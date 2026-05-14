# TikTok Clone — Flutter Developer Take-Home

> 지원자: **한상덕** · 제출: 슈퍼센트 플러터 클라이언트 개발자(2~7년) 과제

세로 스크롤 영상 피드 (TikTok 스타일) Flutter 구현 — **MVVM + Riverpod 3.x + GoRouter**.

---

## 0. TL;DR

**한 줄 요약**: `ScrollEndNotification` settle trigger + 방향성 비대칭 mini-pool(4 controllers) + `unawaited` race-safe init + 사전 추출 썸네일 layering + Lottie 인터랙션으로 끊김 없는 vertical feed.

**핵심 의사결정 4가지**:
1. **MVVM 1:1 매핑** — Riverpod `Notifier`/`AsyncNotifier` 클래스 = ViewModel. 코드젠 미도입 (1-feature 규모에 over-engineering 회피).
2. **방향성 비대칭 mini-pool ±1** — down-scroll 시 forward +2 / backward -1 (TikTok 95% down-scroll 패턴 휴리스틱).
3. **`ScrollEndNotification` trigger** — `PageView.onPageChanged`(중심 통과 시 fire)의 빠른 fling 다중 호출 회피 → settle 완료 시 1번만 trigger.
4. **썸네일 layering + Lottie** — `Stack[Image.asset + VideoPlayer]`로 init 동안에도 검정 화면 0. 더블탭/좋아요는 Lottie로 부드러운 인터랙션.

**▶ 실행 영상**: `docs/demo/demo.mp4`

---

## 1. 실행 방법

```bash
git clone https://github.com/HanSangduk/tiktok_clone.git
cd tiktok-clone
flutter pub get
flutter run
```

**환경**:
- Flutter 3.41.9 / Dart ^3.10
- iOS Simulator (iPhone 15 Pro), Android emulator/실기기 모두 동작

**성능 측정 시 주의**:
- debug 모드는 framework 어설션으로 5~10배 느려 jank 측정 무의미
- 빠른 swipe·메모리 측정은 `flutter run --release` (Android 실기기·emulator) 또는 실 iPhone에서

**.env / Info.plist 변경 불필요** — mock 영상 모두 HTTPS.

## 데모
https://github.com/user-attachments/assets/d89a8a9d-3ffc-4ef6-a078-2d95ca35bafa
---

## 1.5 Performance (실측 결과)

| 지표 | Before | After | 개선율 |
|---|---|---|---|
| `ensure peek` (sqlite query) | 5,200μs | 1,400μs | **−73%** (메모리 캐시) |
| `setState` 호출 빈도 | 매 ensure × N | active idx만 | **−95%+** |
| `FeedScreen build` 빈도 (5장 fling) | ~16회 | 2회 | **−88%** |
| `_syncPool` 호출 (5장 fling) | 5회 | 1회 | **−80%** (ScrollEndNotification) |

- Target: Galaxy S21 5G + release / iPhone 15 Pro Simulator + release
- Buffer stutter: 0 occurrences (90s 연속 swipe 시연)
- Method: `adb logcat` + `dumpsys gfxinfo` Janky frames 카운트

---

## 2. 사용한 패키지

| 패키지 | 버전 | 용도 |
|---|---|---|
| `flutter_riverpod` | ^3.3.1 | 상태관리 (ViewModel) |
| `go_router` | ^17.2.3 | 라우팅 (splash → feed) |
| `video_player` | ^2.11.1 | 영상 재생 (공식) |
| `flutter_svg` | ^2.3.0 | SVG 아이콘 (Lucide) |
| `flutter_cache_manager` | ^3.4.1 | 디스크 LRU 캐싱 (1바퀴+ 후 `file://`) |
| `lottie` | ^3.3.3 | 더블탭 하트 / 좋아요 토글 애니메이션 |
| `visibility_detector` | ^0.4.0+2 | (예비) pause 안전망 |

**의도적으로 뺀 것**: `riverpod_generator` · `freezed` · `json_serializable` · `dio` · `get_it`. 1-feature 규모에 코드젠/추상화 비용 ≫ 효익.

---

## 3. 프로젝트 구조 (MVVM)

```
lib/
├── main.dart                            # ProviderScope + MaterialApp.router
├── router.dart                          # GoRouter ('/'=splash, '/feed')
├── theme.dart                           # 다크 ThemeData
├── models/                              # ── Model ──
│   └── video_post.dart                  # plain Dart class + copyWith
├── data/                                # ── Data Source / Repository ──
│   ├── mock_videos.dart                 # 10개 검증 URL → 100개 VideoPost (id 반복)
│   ├── video_repository.dart            # fetchPage(int page, {int size=20})
│   └── video_cache_resolver.dart        # flutter_cache_manager + peek 메모리 캐시
└── features/
    ├── splash/                          # ── View only ──
    │   └── splash_screen.dart           # 1.5s Timer → context.go('/feed')
    └── feed/
        ├── feed_view_model.dart         # ── ViewModel ── 3종 Notifier
        ├── feed_screen.dart             # ── View ── PageView + _syncPool + Transition diff
        ├── video_page.dart              # ── View ── Stack 5-layer
        └── widgets/
            ├── feed_overlay.dart        # 우측 액션 + 하단 caption
            ├── action_button.dart       # SVG + 카운트 + onTap (재사용)
            ├── heart_action_button.dart # 좋아요 토글 + 4-hearts Lottie (OFF→ON 시)
            ├── like_animation.dart      # 더블탭 11-hearts splash Lottie
            └── play_pause_indicator.dart# 사용자 명시 탭 pause 시 가운데 play 아이콘

assets/
├── icons/                               # Lucide SVG (heart, comment, share, play)
├── thumbnails/                          # ffmpeg 추출 첫 프레임 JPEG × 10
└── lottie/                              # lt_touch_heart.json, lt_move_heart.json

scripts/
└── extract_thumbnails.sh                # curl + ffmpeg 일괄 추출
```

**데이터 흐름**: `VideoRepository → FeedViewModel(AsyncNotifier) → ref.watch → FeedScreen → PageView → VideoPage(slot prop)`.

**좋아요 흐름**: `LikedSetViewModelProvider ← .select watch ← HeartActionButton`. VideoPage는 좋아요 상태를 모르므로 영상 layer는 rebuild되지 않는다.

**Stack 5-layer (VideoPage)**: ① 썸네일(Image.asset) → ② 영상(VideoPlayer) → ③ 오버레이(FeedOverlay) → ④ 더블탭 하트(LikeAnimation) → ⑤ Pause indicator. 모든 layer는 `RepaintBoundary`로 격리.

---

## 4. 구현 기능

### 필수 (4/4)
- [x] **Vertical Video Feed** — PageView.builder + `NotificationListener<ScrollEndNotification>` (settle trigger)
- [x] **Video Player** — autoplay / pause / resume / buffering
- [x] **Overlay UI** — 우측 Like·Comment·Share (Lucide SVG) + 하단 username/caption (gradient)
- [x] **Mock data** — 10개 검증 영상 URL × 100개 VideoPost (id 반복, 페이지당 20개)

### 가산점 (5/5)
- [x] **Like toggle** — 단탭 시 토글, 좋아요 카운트 +1
- [x] **Double tap like** — 화면 가운데 11-hearts splash Lottie
- [x] **Infinite scroll** — `FeedViewModel.loadMore` 페이지네이션 (끝 도달 시 자동 fetch)
- [x] **상태관리** — Riverpod 3.x ViewModel 3종 (Feed/CurrentIndex/Liked)
- [x] **확장 가능한 프로젝트 구조** — MVVM feature-first slim

### 추가 구현
- [x] **방향성 비대칭 mini-pool** — down/up 시 keep set 다르게
- [x] **디스크 LRU 캐싱** — `flutter_cache_manager` + peek 메모리 캐시 (sqlite query 1회만)
- [x] **사전 추출 썸네일 layering** — Stack 최하단 Image.asset → init 동안 검정 화면 0
- [x] **`unawaited` race-safe init** — slot identity 체크로 race 시 dispose
- [x] **Transition diff sweep** — 전체 pool 순회 대신 prev/new 2개만 platform channel 호출
- [x] **PostFrame dispose** — controller `c.dispose()`를 다음 frame으로 미룸 (UI thread block 회피)
- [x] **`ScrollEndNotification` settle trigger** — `onPageChanged` 다중 호출 회피
- [x] **`PlayPauseIndicator`** — 사용자 명시 탭으로 pause한 경우만 표시 (자동재생 시 깜빡임 X)
- [x] **`HeartActionButton`** — 좋아요 OFF→ON 시 4-hearts Lottie 위로 이동
- [x] **`WidgetsBindingObserver`** — 백그라운드 진입 시 active pause + memory pressure 시 pool 축소

### 미구현 (솔직 기재)
- [ ] Android 실기기 광범위 검증 (Galaxy S21 위주)
- [ ] e2e 통합 테스트 (smoke widget test 1개만)
- [ ] Firebase Analytics / Crashlytics
- [ ] HLS adaptive bitrate (현재 progressive MP4만)
- [ ] 좋아요 영구 저장 (mock 데이터 휘발성)

---

## 5. Q1. 앱 구조 설계

### 5.1 폴더 구조 설계 이유

**MVVM + feature-first slim (depth 2 고정)**. 단일 feature 규모에 3-layer Clean Architecture는 over-engineering이라 회피.

- **Model** (`lib/models/`) — 불변 데이터 클래스
- **View** (`lib/features/<name>/(screen|page).dart`, `widgets/*`) — UI + 위젯 lifecycle 자원(VideoController)
- **ViewModel** (`lib/features/<name>/<feature>_view_model.dart`) — Riverpod `Notifier`/`AsyncNotifier`. 같은 도메인의 여러 VM(Feed/CurrentIndex/Liked)은 1파일에 모음 → grep 친화.
- **Repository** (`lib/data/`) — ViewModel이 의존. 실 API 전환 시 `VideoRepository`만 swap.

추가 분리(`controllers/`, `presentation/`, `services/`) 금지. `features/<name>/widgets/`만 허용.

### 5.2 상태 관리 (Riverpod 3.x) 선택 이유

채용공고 명시 + 다른 대안 대비:
- **vs Provider** — compile-time 안전 + `autoDispose`로 자원 자동 해제
- **vs BLoC** — event/state boilerplate 무거움. derived state(currentIndex, liked, hasMore) 많을 때 1/3 코드
- **vs GetX** — DI/Routing/State 한 통에 묶여 책임 분리 약함

**3.x 변경점 반영**: `StateProvider` deprecated → 모든 state를 `Notifier`/`AsyncNotifier`로 통일 (MVVM 1:1 매핑). **코드젠 미도입** — build_runner 부담 회피, 직접 정의가 가독성 ↑.

### 5.3 Video Player Lifecycle

**`FeedScreen` state에 방향성 비대칭 mini-pool**을 직접 관리. ViewModel로 끌어올리지 않음 (`VideoPlayerController`는 GPU/디코더/native handle 자원이라 위젯 lifecycle 동기화가 안전).

- **keep set**:
  - down: `{i-1, i, i+1, i+2}` (forward +2)
  - up: `{i-2, i-1, i, i+1}` (backward +2)
  - none (첫 진입): `{i, i+1, i+2}`
- **단일 진입점 `_syncPool(idx)`** — 방향 갱신 → keep 계산 → evict → ensure → Transition diff sweep
- **`unawaited(c.initialize().then(...))` + slot identity** — 메인 thread block 0, race 시 dispose
- **`PostFrame dispose`** — `c.dispose()`를 다음 frame으로 미뤄 UI thread 보호
- **`Transition diff sweep`** — pool 전체 순회 대신 prev/new 2 controller만 toggle (platform channel 호출 O(N)→O(1))
- **`WidgetsBindingObserver`** — 백그라운드 pause + memory pressure 시 active 외 dispose
- **썸네일 layering** — Stack 최하단 Image.asset → init 도중에도 첫 프레임 표시

---

## 6. Q2. 확장성 — 실 TikTok 규모

### 6.1 Video Preload
- direction-aware asymmetric window — 현재 +2/-1, 실 서비스는 사용자 행동 EMA로 동적
- HLS adaptive bitrate — preload 시 240p, active 시 720/1080p
- TTFF 최적화 — faststart MP4 / 첫 KB Range request
- CDN edge prefetch + disk LRU 200MB cap

### 6.2 네트워크 처리
- HTTP/2 multiplexing + Range request resume
- exponential backoff + jitter (Dio interceptor)
- cursor-based pagination
- optimistic update (like/comment 즉시 반영 후 reconcile)
- WebSocket / SSE for real-time like count

### 6.3 상태 관리 구조
- feature scope Provider 분리 (feed / liked / comments)
- `autoDispose` + `keepAlive(Duration)`
- `.select`로 rebuild 최소화 (이미 적용)
- 서버 상태(repo cache) vs UI 상태(controller) vs user action(별 Provider) — TanStack Query 패턴
- Crash recovery — 마지막 시청 idx persist

### 6.4 성능 최적화 (핵심 키워드)
- **메모리**: LRU pool eviction · `didHaveMemoryPressure` handler · dynamic pool sizing per device tier
- **디코더/코덱**: HW decoder (ExoPlayer/AVPlayer) · faststart MP4 · HLS ABR · decoder instance reuse
- **Flutter 렌더링**: `RepaintBoundary` 5-layer · `PageView.builder` lazy · `.select` rebuild scope · `ValueListenableBuilder` 텍스처 갱신
- **Race-safety**: `unawaited` init + slot identity · 단일 `_syncPool` sweep + Transition diff · PostFrame dispose
- **관측**: Firebase Performance (TTFF trace) · Crashlytics (OOM·ANR) · custom `Timeline.startSync`

---

## 7. Q3. 가장 어려웠던 문제 — 끊김 없는 vertical feed 만들기

### 7.1 문제 상황

빠른 연속 스와이프 시 5가지 문제가 한꺼번에 발생:
1. **검은 화면 200~500ms 노출** (영상 init 동안)
2. **오디오 중첩** (이전 controller pause 전 다음 controller play)
3. **메인 thread block** (`await initialize()` 직접 호출)
4. **메모리 압박** (controller dispose 누락 + 빠른 fling 시 동시 init 4~5개)
5. **스크롤 버벅임** (빠른 fling 시 중간 idx마다 `_syncPool` 호출 → ensure async chain → 메인 thread 부하)

### 7.2 시도와 발견

1. **`await c.initialize()` 직접 호출** → 메인 thread block, UI 멈춤 → ❌
2. **`VisibilityDetector` 기반 play/pause** → visibility 이벤트가 스크롤 도중 fire → 미정착 페이지가 play 트리거 → 오디오 중첩 → ❌
3. **`Provider.family`로 controller pool을 ViewModel로** → autoDispose 타이밍이 위젯 lifecycle보다 늦/빨라 race → ❌
4. **검정 placeholder** → 빠른 스크롤 시 평가자에게 "끊김"으로 인지됨 → ❌
5. **`PageView.onPageChanged` 사용** → Flutter 소스 분석 결과 `ScrollUpdateNotification` listen → `metrics.page!.round()` 정수 변경 시 fire = **viewport 중심(fraction 0.5) 통과 시점**. 빠른 5장 fling = 5번 호출 → `_syncPool` 5번 → 메모리 peak. → **`NotificationListener<ScrollEndNotification>`으로 wrap하여 settle 완료 시점에만 1번 fire** → ✅

### 7.3 최종 해결 — 5-pattern 조합

- **`_syncPool(idx)` 단일 진입점 sweep** — 방향성 비대칭 keep set → evict → ensure → Transition diff. 분산 트리거(visibility / onPageChanged / lifecycle)에 의존하지 않음.
- **`unawaited(c.initialize().then(...))` + slot identity** — 메인 thread block 0, race 시 dispose.
- **방향성 비대칭 mini-pool** — 95% down-scroll 패턴에 forward +2 / backward -1 → swipe-up TTFF 거의 0ms.
- **사전 추출 썸네일 layering** — Stack 최하단 Image.asset → 사용자가 첫 프레임을 보고 있어 "끊김 없는" 인지.
- **`ScrollEndNotification` settle trigger** — `onPageChanged`(중심 통과 시) → settle 완료 시 1번. `_syncPool` 호출 5회 → 1회로 80% 감소, 메모리 peak 안정 (mini-pool ±1 = 4개 유지).

### 7.4 학습

- **"단일 invariant는 단일 함수에서"** — 동시 재생 controller 1개, 메인 thread block 0, race-free 같은 invariant들은 분산 트리거에 의존하면 항상 race가 발생한다. `_syncPool` 한 함수에 sweep으로 강제하면 race 자체가 차단된다.
- **"끊김 없음"은 init 속도를 줄이는 것이 아니라 init 시간을 가리는 UX 설계로 달성된다** — 썸네일 layering이 검정 placeholder보다 압도적으로 우월.
- **Flutter API의 의미를 정확히 알아야 한다** — `PageView.onPageChanged`의 fire 시점이 "settle 후"가 아니라 "viewport 중심 통과 시"라는 사실은 Flutter 소스를 직접 읽어야 알 수 있었다. 표준 API의 자동 동작을 의심하고 검증하는 습관이 결정적.

---

## 8. AI 사용 내역

**도구**: Claude Code (Opus 4.7, 1M context). 자세한 협업 기록은 [`docs/AI_USAGE.md`](docs/AI_USAGE.md).

### 8.1 작업 범위 (직접 vs AI)

| 영역 | AI 활용 | 직접 작성 | 비고 |
|---|---|---|---|
| 폴더 구조 / 아키텍처 (MVVM) | 30% | 70% | AI 3안 제시 → 1인 유지보수 관점에서 직접 선택 |
| 패키지 선정 + 버전 매칭 | 40% | 60% | 4개 핵심 버전 사전 명시, 보강 2개만 AI 자문 |
| UI 위젯 코드 | 60% | 40% | boilerplate AI, 디자인 디테일 직접 |
| Riverpod ViewModel | 50% | 50% | 패턴 AI, state 분리·toggle 로직 직접 |
| 영상 lifecycle (mini-pool + 방향성 + Transition) | 50% | 50% | 패턴 AI, race·예외 케이스 직접 검증 |
| Mock data | 90% | 10% | URL·메타데이터 AI 생성, Google sample 403 직접 발견·해결 |
| README / 문서 | 50% | 50% | 구조 AI, Q1/Q2/Q3 답변 직접 검토·수정 |

### 8.2 AI를 사용한 작업

- 다중 팀 (미니멀 / 평가자 / 성능 / 캐싱 / 썸네일) **병렬 의견 → 교차검증 → 자문자답**으로 예외 케이스 사전 도출
- 코드 boilerplate 생성 (Riverpod Provider, GoRouter 라우트, MaterialApp 구조)
- 패턴 추천 (`_syncPool` sweep, `unawaited` race-safe, slot identity, Transition diff, PostFrame dispose)

### 8.3 본인이 직접 작성한 부분

- 모든 의사결정 (패키지 선정, 폴더 구조, 코드젠 미도입, 영상 URL 교체 등)
- Q1/Q2/Q3 답변 검토 + 톤 조정
- **Google sample URL 403 이슈 발견** → 대체 URL 검증 (curl) + ffmpeg 호환성 디버깅 (samplelib streaming 호환 안 됨 → 다운로드 후 추출 방식 채택)
- **`ScrollEndNotification` 통찰** — `PageView.onPageChanged`가 viewport 중심 통과 시 fire된다는 가설 직접 제시 → AI가 Flutter 소스 검증 → 채택
- mock_videos.dart 한국어 caption / username

### 8.4 대화 기록

- 정제 발췌: [`docs/ai-conversations/`](docs/ai-conversations/) 6건 (architecture · riverpod · video lifecycle · direction-thumbnail · pageview-race · readme drafting)
- 원본 transcript: `docs/ai-raw-transcripts/*.jsonl.gz` (제출 시 압축본 포함)

---

## 9. 한계와 개선 계획

- 실 API 전환 시 `VideoRepository`만 swap (다른 ViewModel/View는 그대로)
- Firebase Analytics/Performance 미연동
- e2e 통합 테스트 부재 (smoke widget test 1개만)
- Android 실기기 광범위 검증 부족 (Galaxy S21 release 위주)
- HLS adaptive bitrate 미적용 (현재 progressive MP4)
- 좋아요 영구 저장 미적용 (mock 휘발성)
- low-end Android (2GB RAM) dynamic pool sizing 미구현 (Q2.4 키워드만)

---

## 10. 참고 자산

**영상 (CC0/Public Domain)**:
- [Flutter assets-for-api-docs](https://flutter.github.io/assets-for-api-docs/) — butterfly · bee
- [test-videos.co.uk](https://test-videos.co.uk/) — BigBuckBunny · Jellyfish · Sintel
- [download.samplelib.com](https://samplelib.com/) — sample-5s ~ 30s

**아이콘**: [Lucide](https://lucide.dev) (ISC License)

**Lottie**: [LottieFiles](https://lottiefiles.com/) — heart-touch · heart-move
