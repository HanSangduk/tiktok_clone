# TikTok Clone — Flutter Developer Take-Home

> 지원자: **한상덕(람)** · 제출: 슈퍼센트 플러터 클라이언트 개발자(2~7년) 과제

세로 스크롤 영상 피드 (TikTok 스타일) Flutter 구현. MVVM + Riverpod 3.x + GoRouter.

---

## 0. TL;DR

**한 줄 요약**: PageView + 방향성 비대칭 mini-pool(4 controllers) + unawaited race-safe init + 사전 추출 썸네일 layering으로 끊김 없는 vertical feed.

**핵심 의사결정**:
1. **MVVM**: Riverpod `Notifier`/`AsyncNotifier` 클래스 = ViewModel 1:1 매핑 (코드젠 X, 단일 화면 규모에 over-engineering 회피)
2. **mini-pool ±1 (방향성 비대칭)**: down-scroll 시 forward +2/backward -1 윈도우 (TikTok 95% down-scroll 패턴)
3. **썸네일 layering**: Stack[Image.asset + VideoPlayer] — init 200~500ms 동안에도 검정 화면 0

**▶ 실행 영상**: `docs/demo/demo.mp4` (P09에서 녹화)

---

## 1. Quick Start

```bash
git clone https://github.com/<owner>/tiktok-clone.git
cd tiktok-clone
flutter pub get
flutter run --profile          # 성능 측정 모드
# 또는
flutter run                    # 일반 debug
```

**환경**:
- Flutter 3.41.9 / Dart ^3.10
- iOS Simulator (iPhone 15 Pro 권장) 또는 Android emulator

**.env / iOS Info.plist 변경 불필요** (mock 영상은 모두 HTTPS).

**중요**:
- 성능 측정/영상 녹화: **iOS Simulator는 `--release`**, 실 기기는 `--profile` 또는 `--release`
- debug는 framework 어설션으로 5~10배 느려 jank 측정이 무의미
- iOS Simulator는 `--profile`을 지원하지 않음 (Apple 정책) → release 사용

---

## 1.5 Performance

- Target: iPhone 15 Pro Simulator (iOS 17.5), Flutter 3.41.9, **release mode**
- **TTFF** (next-video first-frame after swipe-up): mini-pool prefetch ±1 + 방향성 비대칭 keep set으로 prefetch된 controller는 즉시 재생
- **Buffer stutter**: 0 occurrences in 90s continuous-swipe take (정성 관찰)
- **Cache hit rate**: 첫 바퀴 0% → 2바퀴+ 100% (mock 10개 반복, file:// 재생)
- Method: `xcrun simctl io booted recordVideo --codec=h264` 60fps 프레임 검사
- Caveats: Android 미검증 / 실 기기 4G·3G 미측정 / iOS Simulator는 profile 모드 미지원이라 release로 측정

---

## 2. 사용 패키지 & 결정 근거

| 패키지 | 버전 | 용도 | 선택 이유 |
|---|---|---|---|
| `flutter_riverpod` | ^3.3.1 | 상태관리 (ViewModel) | 컴파일 안전 + autoDispose. 3.x에서 `Notifier`/`AsyncNotifier` first-class. 코드젠 X |
| `go_router` | ^17.2.3 | 라우팅 | declarative, splash → feed |
| `video_player` | ^2.11.1 | 영상 재생 | 공식. `better_player`는 2022년 이후 stale |
| `flutter_svg` | ^2.3.0 | SVG 아이콘 | Lucide (heart, comment, share) |
| `visibility_detector` | ^0.4.0+2 | (예비) | 향후 pause 안전망 |
| `flutter_cache_manager` | ^3.4.1 | 디스크 LRU 캐싱 | 1바퀴+ 후 `file://` 재생 |

**의도적으로 뺀 것**: `riverpod_generator` / `riverpod_annotation` / `build_runner` / `freezed` / `json_serializable` / `dio` / `get_it`. 1-feature 규모에 코드젠/추상화 비용 ≫ 효익.

---

## 3. 구현 기능

### 필수 (4/4)
- [x] Vertical Video Feed (PageView.builder, 양방향 스크롤)
- [x] Video Player — autoplay / pause / resume / buffering 처리
- [x] Overlay UI — 우측 Like·Comment·Share (SVG) + 하단 username/caption
- [x] Mock data (10개 영상 URL, 25개 mock VideoPost — id만 다르게 반복)

### 가산점 (5/5)
- [x] Like toggle (단탭 ActionButton)
- [x] Double tap like (큰 하트 페이드+스케일 애니메이션)
- [x] Infinite scroll (`FeedViewModel.loadMore` 페이지네이션)
- [x] 상태관리 (Riverpod 3.x ViewModel 3종)
- [x] 확장 가능한 프로젝트 구조 (MVVM feature-first slim)

### 추가 구현 (가산점 외)
- [x] 방향성 비대칭 mini-pool (down/up 시 keep set 변경)
- [x] 디스크 LRU 캐싱 (`flutter_cache_manager`)
- [x] 사전 추출 썸네일 (ffmpeg, `assets/thumbnails/*.jpg`)
- [x] `unawaited` race-safe init + slot identity 패턴
- [x] `WidgetsBindingObserver` — 백그라운드 pause + memory pressure 시 pool 축소

### 미구현 (솔직 기재)
- [ ] iOS Simulator 메모리 워닝 hook 실측 (`Hardware → Simulate Memory Warning`로 코드는 동작, 영상 녹화에 미포함)
- [ ] Android 실기기 검증 (시뮬레이터/에뮬레이터만)
- [ ] e2e 통합 테스트 (smoke widget test 1개만)
- [ ] Firebase Analytics / Crashlytics (실 서비스용)
- [ ] HLS adaptive bitrate (현재 progressive MP4만)

---

## 4. 프로젝트 구조 (MVVM)

```
lib/
├── main.dart                          # ProviderScope + MaterialApp.router
├── router.dart                        # GoRouter ('/'=splash, '/feed')
├── theme.dart                         # 다크 ThemeData
├── models/                            # ── Model ──
│   └── video_post.dart                # plain Dart class + copyWith
├── data/                              # ── Data Source / Repository ──
│   ├── mock_videos.dart               # 10개 검증된 sample URL → 25개 VideoPost
│   ├── video_repository.dart          # fetchPage(int page, {int size=5})
│   └── video_cache_resolver.dart      # flutter_cache_manager 래퍼 (peek/prefetch)
└── features/
    ├── splash/                        # ── View only ──
    │   └── splash_screen.dart         # 1.5s Timer → context.go('/feed')
    └── feed/
        ├── feed_view_model.dart       # ── ViewModel ── 3종 Notifier
        ├── feed_screen.dart           # ── View ── PageView + _syncPool
        ├── video_page.dart            # ── View ── Stack[썸네일/영상/오버레이/하트]
        └── widgets/
            ├── feed_overlay.dart      # 우측 액션 + 하단 caption (자체 watch)
            ├── action_button.dart     # SVG + 카운트 + onTap (재사용)
            └── like_animation.dart    # 더블탭 하트 페이드+스케일

assets/
├── icons/                             # Lucide SVG (heart, comment, share)
└── thumbnails/                        # ffmpeg 추출 첫 프레임 JPEG ×10

scripts/
└── extract_thumbnails.sh              # curl + ffmpeg 일괄 추출 (1회)
```

**데이터 흐름**: `VideoRepository → FeedViewModel(AsyncNotifier) → ref.watch → FeedScreen build → PageView → VideoPage(controller prop)`.

**Like 흐름**: `LikedSetViewModel(Notifier) ← ref.watch(.select) ← FeedOverlay`. VideoPage는 좋아요를 모르므로 영상 layer는 rebuild되지 않는다.

---

## 5. Q1. 앱 구조 설계

### 5.1 폴더 구조 설계 이유

**MVVM + feature-first slim (depth 2 고정)**. 단일 feature(`feed`) 규모에 3-layer Clean Architecture(presentation/domain/data) 분리는 over-engineering이라 의도적으로 회피했다. 대신 다음 원칙:

- **Model** = `lib/models/`: 불변 데이터 클래스 (freezed 미사용, 모델 1개)
- **View** = `lib/features/<name>/(screen.dart | page.dart | widgets/*)`: UI + 위젯 lifecycle 자원(VideoController)
- **ViewModel** = `lib/features/<name>/<feature>_view_model.dart`: Riverpod `Notifier`/`AsyncNotifier` 클래스. 같은 도메인의 여러 ViewModel(Feed/CurrentIndex/Liked)은 1개 파일에 모음 → 1인 개발자 grep 친화.
- **Repository** = `lib/data/`: ViewModel이 의존하는 data source. 실 API 전환 시 `VideoRepository`만 swap.

추가 분리(controllers/, presentation/, services/) 금지. `features/<name>/widgets/`만 허용.

### 5.2 상태 관리(Riverpod 3.x) 선택 이유

채용공고에 Riverpod이 명시되어 있고, 다음 대안 대비 우월하다:
- **vs Provider**: compile-time 안전, `autoDispose`로 자원 자동 해제
- **vs BLoC**: event/state boilerplate가 무거움. 영상 feed처럼 derived state(currentIndex, liked, hasMore)가 많을 때 1/3 코드
- **vs GetX**: DI/Routing/State 한 통에 묶여서 책임 분리 약함

**3.x 변경점 반영**: `StateProvider`가 deprecated되어 단순 `int` state도 `NotifierProvider`로 통일 → MVVM ViewModel과 1:1 매핑이 깔끔. **코드젠은 의도적으로 미도입** — build_runner 부담 회피, 1-feature 규모에 직접 정의(`Notifier`/`AsyncNotifier`)가 가독성 ↑.

### 5.3 Video Player Lifecycle

**FeedScreen state에 방향성 비대칭 mini-pool**을 직접 관리한다. ViewModel로 끌어올리지 않는다 (VideoPlayerController는 GPU/디코더/native handle 자원이라 위젯 lifecycle 동기화가 안전, race 회피).

- **keep set**:
  - down: `{i-1, i, i+1, i+2}` (forward +2, 95% 사용자 패턴 최적화)
  - up:   `{i-2, i-1, i, i+1}`
  - none (첫 진입): `{i, i+1, i+2}` (down default)
- **단일 진입점 `_syncPool(idx)`**: 방향 갱신 → keep 계산(`_computeKeep`) → evict → ensure → setVolume/play sweep
- **`unawaited(c.initialize().then(...))` + slot identity 체크 (`_pool[i] != c`)**: 메인 thread block 0, race 시 dispose
- **`WidgetsBindingObserver`**: 백그라운드 진입 시 pause, memory pressure 시 active 제외 dispose
- **썸네일 layering**: Stack 최하단에 Image.asset, 그 위에 VideoPlayer ValueListenableBuilder → init 도중 검정 화면 0

---

## 6. Q2. 확장성 — 실 TikTok 규모

### 6.1 Video Preload

- **direction-aware asymmetric window**: 현재 down +2/-1, 실 서비스는 사용자 행동 EMA로 동적 조정
- **HLS adaptive bitrate**: preload 시 240p, active 진입 시 720/1080p로 upgrade
- **TTFF 최적화**: faststart MP4 (moov atom front) / 첫 KB Range request
- **CDN edge prefetch**: For You feed는 추천 시퀀스가 정해져 있어 manifest를 미리 fetch
- **storage budget**: 디스크 LRU 200MB cap, 사용자 데이터 절약 모드 분기

### 6.2 네트워크 처리

- **HTTP/2 multiplexing + Range request resume**: 영상 chunk 재개
- **exponential backoff + jitter** (Dio interceptor)
- **cursor-based pagination** (offset 대신 cursor → 신규 영상 invalidation 안 함)
- **optimistic update** (like/comment 카운트 즉시 반영, 서버 응답 reconcile)
- **WebSocket / SSE**: 실시간 like count. 폴링은 16억 규모에서 비용 폭발
- **graceful degradation**: 영상 fetch 실패 시 다음 영상 auto-skip

### 6.3 상태 관리 구조

- **feature scope Provider 분리**: feed / liked / comments / share 별도
- **`autoDispose` + `keepAlive(Duration)`**: window 밖 영상은 60초 후 dispose
- **`.select`로 rebuild 최소화** (이미 본 과제도 적용)
- **서버 상태와 UI 상태 분리**: video metadata는 캐시 layer(repo), 재생 상태는 controller layer, like 같은 user action은 별 Provider — TanStack Query 패턴
- **Crash recovery**: 마지막 시청 idx persist (SharedPreferences / Isar)

### 6.4 성능 최적화 (35개+ 키워드)

- **메모리**: LRU pool eviction / RAM cap per device tier / GPU texture share / `didHaveMemoryPressure` handler / dynamic pool sizing / 백그라운드 dispose / Dart GC churn 회피 / listener cleanup / `Image.asset(cacheWidth:)` 디코드 사이즈 제한
- **디코더/코덱**: HW decoder (AVPlayer·MediaCodec) / H.264 > H.265 > AV1 우선순위 / decoder instance reuse / **fastStart MP4 (moov front)** / HLS adaptive bitrate
- **Preload/Window**: **direction-aware preload (+2/-1 on down-scroll)** / asymmetric keep set per scroll direction / 95% down-scroll heuristic / ML 추천 기반 dynamic window
- **캐싱**: **disk LRU 200MB cap (`flutter_cache_manager`)** / first-view progressive + background prefetch / file:// playback / HTTP Range resume / CDN edge cache / ETag·Last-Modified invalidation
- **썸네일/UX**: **pre-extracted first-frame JPEG thumbnails** / Stack[Image.asset + VideoPlayer] layering / 자연 교체 (시각적 점프 0) / errorBuilder fallback
- **Flutter 렌더링**: `const` constructors / RepaintBoundary 4-layer / `PageView.builder` lazy / `allowImplicitScrolling:false` / `.select`로 rebuild scope 축소 / `ValueListenableBuilder` 텍스처 갱신
- **Race-safety**: **`unawaited` init + slot identity (`_pool[i] != c`)** / 단일 `_syncPool` sweep 진입점 / 메인 thread block 0
- **관측**: Firebase Performance (TTFF trace) / Crashlytics (OOM·ANR) / Sentry / `Timeline.startSync`
- **빌드/측정**: profile mode benchmark / `flutter analyze` + lints / DevTools Performance Overlay / `xcrun simctl recordVideo` 60fps 프레임 검사

---

## 7. Q3. 가장 어려웠던 문제 — `_syncPool` 4-pattern 조합 도출

### 7.1 문제 상황

빠른 연속 스와이프 시 4가지 문제가 한꺼번에 발생했다:
1. **검은 화면 200~500ms 노출** (영상 init 동안)
2. **오디오 중첩** (이전 controller pause 전에 다음 play)
3. **메인 스레드 block** (`await initialize()` 직접 호출)
4. **메모리 압박** (controller dispose 누락)
5. 스크롤 버벅임 

### 7.2 시도한 해결 (실패한 접근)

1. **`onPageChanged` 안에서 `await c.initialize()` 직접 await** → 메인 thread block, 빠른 스크롤 시 UI 멈춤
2. **`VisibilityDetector`만으로 play/pause 제어** → visibility 이벤트가 스크롤 도중 발생 → 미정착 페이지가 play 트리거 → 중첩 + 깜빡임
3. **Provider.family로 controller pool을 ViewModel로 끌어올림** → autoDispose 타이밍이 위젯 lifecycle보다 늦/빨라 race condition
4. **검정 placeholder** → 빠른 스크롤 시 평가자에게 "끊김"으로 인지됨
5. onPageChanged 제거 후 NotificationListener

### 7.3 최종 해결 — 4-pattern 조합

- **`_syncPool(idx)` 단일 진입점 sweep**: 방향성 비대칭 keep set 계산 → evict → ensure → setVolume/play sweep을 하나의 함수에서 일괄. 분산된 트리거(visibility/onPageChanged/라이프사이클)에 의존하지 않음.
- **`unawaited(c.initialize().then(...))` + slot identity 체크**: 메인 thread block 0. `_pool[i] != c`로 race 시 dispose.
- **방향성 비대칭 mini-pool**: 95% down-scroll 패턴에 forward +2/backward -1 슬롯 할당 → swipe-up TTFF 거의 0ms.
- **사전 추출 썸네일 layering**: Stack[Image.asset + VideoPlayer] — init 도중에도 사용자가 첫 프레임을 보고 있어 "끊김 없는" 인지.

### 7.4 학습

**"단일 invariant는 단일 함수에서"**. 동시 재생 controller 1개 보장 / 메인 thread block 0 / race-free 같은 invariant들은 분산된 트리거에 의존하면 항상 race가 발생한다. `_syncPool` 한 함수에 sweep으로 강제하면 race 자체가 차단된다.

**"끊김 없음"은 init 속도를 줄이는 것이 아니라 init 시간을 가리는 UX 설계로 달성된다**. 썸네일 layering이 검정 placeholder보다 압도적으로 우월하며, 코드량은 거의 동일하다.

---

## 8. AI 사용 내역

본 프로젝트는 **Claude Code (Opus 4.7, 1M context)** 를 페어 프로그래밍 파트너로 사용. 자세한 내용은 [docs/AI_USAGE.md](docs/AI_USAGE.md).

### 8.1 작업 범위 요약

| 영역 | AI 활용 | 직접 작성 | 비고 |
|---|---|---|---|
| 폴더 구조 / 아키텍처(MVVM) | 30% | 70% | AI가 3안 제시 → 1인 유지보수 관점에서 직접 선택 |
| 패키지 선정 + 최신 버전 매칭 | 40% | 60% | 4개 패키지 버전 사전 명시, 보강 2개만 AI 자문 |
| UI 위젯 코드 | 60% | 40% | boilerplate AI, 디자인 디테일 직접 |
| Riverpod ViewModel | 50% | 50% | 패턴 AI, state 분리·toggle 로직 직접 |
| 영상 lifecycle (mini-pool + 방향성) | 50% | 50% | 패턴 AI, race·예외 케이스 직접 검증 |
| Mock data | 90% | 10% | URL 리스트·메타데이터 AI 생성 (Google sample 403 이슈 직접 발견·해결) |
| README / 문서 | 50% | 50% | 구조 AI, Q1/Q2/Q3 답변은 직접 검토·수정 |

### 8.2 AI를 사용한 작업 범위

- 다중 팀(미니멀 / 평가자 / AI증빙 / 성능 / 캐싱 / 썸네일 등) **병렬 의견 → 교차검증 → 자문자답**으로 13개 예외 케이스 사전 도출
- 코드 boilerplate 생성 (Riverpod Provider, GoRouter 라우트, MaterialApp 구조 등)
- 패턴 추천 (`_syncPool` sweep, `unawaited` race-safe, slot identity)

### 8.3 본인이 직접 작성한 부분

- 모든 의사결정 (패키지 선정, 폴더 구조, 코드젠 미도입, 영상 URL 교체 등)
- Q1/Q2/Q3 답변 검토 + 톤 조정
- Google sample URL 403 이슈 발견 → 대체 URL 검증 (curl) + ffmpeg 호환성 디버깅 (samplelib streaming 호환 안 됨 → 다운로드 후 추출 방식 채택)
- mock_videos.dart의 한국어 caption / username 작성

### 8.4 대화 기록

- 정제 발췌: [docs/ai-conversations/](docs/ai-conversations/) 6건
- 원본 transcript: `docs/ai-raw-transcripts/*.jsonl.gz` (제출 시 압축본 포함)

---

## 9. 한계와 개선 계획

- 실 API 전환 시: `VideoRepository`만 swap. 다른 ViewModel/View는 그대로.
- Firebase Analytics/Performance 미연동
- e2e 통합 테스트 부재 (smoke widget test 1개만)
- Android 실기기 검증 부족 (iOS Simulator 우선)
- HLS adaptive bitrate 미적용 (현재 progressive MP4만)
- 좋아요 상태 영구 저장 미적용 (mock 데이터 휘발성)
- low-end Android(2GB RAM) dynamic pool sizing 미적용 (Q2.4 키워드만)

---

## 10. 참고 자산

**영상 (CC0/Public Domain)**:
- [Flutter assets-for-api-docs](https://flutter.github.io/assets-for-api-docs/) — butterfly, bee
- [test-videos.co.uk](https://test-videos.co.uk/) — BigBuckBunny, Jellyfish, Sintel
- [download.samplelib.com](https://samplelib.com/) — sample-5s ~ 30s

**아이콘**: [Lucide](https://lucide.dev) (ISC License)
