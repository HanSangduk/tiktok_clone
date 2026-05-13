# tiktok_clone — Project Context

Supercent Flutter 개발자 과제 — Vertical Video Feed (TikTok-style) 클론. **MVVM 패턴**.

## 기술 스택

- Flutter 3.32.7+ / Dart ^3.8.1 (Flutter upgrade 후 3.10+)
- 상태관리: `flutter_riverpod ^3.3.1` (코드젠 X, `Notifier`/`AsyncNotifier` 직접 정의)
- 라우팅: `go_router ^17.2.3`
- 영상: `video_player ^2.11.1` + `visibility_detector ^0.4.0+2`
- 캐싱: `flutter_cache_manager ^3.4.1` (디스크 LRU 200MB, file:// 재생)
- 아이콘: `flutter_svg` (Lucide)

## 아키텍처: MVVM

- **Model**: `lib/models/*` — 불변 데이터 클래스 (plain Dart class, freezed/JSON 직렬화 미사용)
- **View**: `lib/features/*/(*_screen.dart | *_page.dart | widgets/*)` — UI + 위젯 lifecycle 자원
- **ViewModel**: `lib/features/*/*_view_model.dart` — Riverpod `Notifier`/`AsyncNotifier` 클래스
- **Repository**: `lib/data/*_repository.dart` — data source 추상화, ViewModel이 의존

## 폴더 구조 룰

- feature-first slim (depth 2 고정)
- 한 feature 내 ViewModel들은 1개 `*_view_model.dart` 파일에 모음 (도메인 분리 시 분리)
- `features/{name}/widgets/`만 허용 (presentation/controllers 추가 분리 금지)
- 1인 유지보수 우선 — premature abstraction 금지

## Riverpod 3.x 룰

- `StateProvider` 사용 금지 (deprecated) → 단순 state도 `NotifierProvider`로
- ViewModel = `Notifier` 또는 `AsyncNotifier` 클래스
- `Provider.family` 도입 금지 (VideoController는 View state로 관리)
- `ConsumerWidget` vs `ConsumerStatefulWidget`: dispose 필요한 곳만 Stateful

## Video Lifecycle 룰 (위반 금지)

- `VideoPlayerController`는 반드시 `dispose`
- 동시 play 상태 controller 1개만 허용 (오디오 충돌 방지)
- async gap 후 `BuildContext` 사용 시 `if (!mounted) return;` 패턴
- mini-pool 방향성 비대칭:
  - down: `keep = {i-1, i, i+1, i+2}`
  - up:   `keep = {i-2, i-1, i, i+1}`
  - none: `keep = {i, i+1, i+2}` (첫 진입)
- `_ensure(i)`는 `unawaited(c.initialize().then(...))` + slot identity 체크 (`_pool[i] != c`) 패턴
- `_syncPool(idx)` 단일 진입점에서 방향 갱신 → keep 계산 → evict → ensure → setVolume/play sweep

## 영상 / 썸네일 자산

- 영상: Google `commondatastorage.googleapis.com/gtv-videos-bucket/sample/*.mp4` (faststart 검증된 13개)
- 썸네일: ffmpeg로 첫 프레임 추출, `assets/thumbnails/*.jpg` (~100KB × 13장)
- 디스크 캐싱: 첫 시청은 progressive playback, 2바퀴+부터 file:// 재생

## 코드 스타일

- `print`/`debugPrint`는 커밋 전 제거
- `// TODO` 남기지 말 것 (work_log P{nn}로 이동)
- `flutter analyze` 0 warning 유지

## work_log domain enum

`bootstrap` / `feed` / `video` / `state` / `ui` / `mock` / `docs` / `infra`

## 실행

- 개발: `flutter run` (debug)
- 성능 측정 / 영상 녹화: `flutter run --profile` (debug는 5~10배 느림)
- 영상 녹화: `xcrun simctl io booted recordVideo --codec=h264 docs/demo/demo-raw.mp4` → `ffmpeg -i demo-raw.mp4 -vcodec libx264 -crf 26 -preset slow demo.mp4`

## 참조

- 구현 plan: `/Users/straram/.claude/plans/fuzzy-crunching-plum.md`
- 과제 채용공고: https://www.wanted.co.kr/wd/358933
