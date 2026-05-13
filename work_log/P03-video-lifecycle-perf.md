---
id: P03
title: FeedScreen `_syncPool` + 방향성 비대칭 mini-pool + VideoPage 썸네일 layering
status: 진행 중
domain: video
created: 2026-05-11
completed:
---

## 목표

플랜의 핵심 결정 4-pattern 구현. 끊김 없는 vertical video feed.

1. **PageView.builder** + `allowImplicitScrolling: false`
2. **`_syncPool(idx)` 단일 진입점**: 방향 갱신 → keep 계산(비대칭) → evict → ensure → setVolume/play sweep
3. **`unawaited(c.initialize().then(...))` + slot identity 체크 (`_pool[i] != c`)**: race-safe, 메인 thread block 0
4. **VideoPage Stack[Image.asset 썸네일 + VideoPlayer]**: init 도중에도 검정 placeholder 0

## 결정 사항

- FeedScreen은 ConsumerStatefulWidget + WidgetsBindingObserver mixin
- VideoPage는 ConsumerWidget + `select((idx) => idx == index)` rebuild 회피
- mini-pool keep set:
  - down: `{i-1, i, i+1, i+2}` (총 4개 controller)
  - up:   `{i-2, i-1, i, i+1}` (총 4개)
  - none: `{i, i+1, i+2}` (첫 진입, 3개)
- VideoCacheResolver.peek로 캐시 hit이면 `.file()`, miss면 `.networkUrl()` + 백그라운드 prefetch
- RepaintBoundary 4겹: VideoLayer / BottomCaption / RightActions / LikeAnimation
- iOS Simulator 부팅 확인 후 `flutter run`으로 빠른 스와이프 시연

## 진행 단계

- [x] work_log/P03 작성
- [ ] `lib/features/feed/video_page.dart` (Stack[썸네일 + VideoPlayer + isActive 분기])
- [ ] `lib/features/feed/feed_screen.dart` (PageView + _syncPool + mini-pool + WidgetsBindingObserver)
- [ ] flutter analyze 0 warning
- [ ] flutter test 통과
- [ ] iOS Simulator 부팅 후 `flutter run`
- [ ] 스와이프 → 영상 자동 재생 / pause 동작 확인
- [ ] 빠른 5장 스와이프 → 검은 화면 0 확인

## 변경 파일

- (신규) lib/features/feed/video_page.dart
- (수정/대체) lib/features/feed/feed_screen.dart

## 검증

- [ ] flutter analyze 0 warning
- [ ] flutter test 통과
- [ ] 시뮬레이터 빠른 5장 스와이프 시 검은 화면 0
- [ ] 오디오 중복 0 (이어폰)
- [ ] DevTools Performance Overlay 16.67ms 라인 초과 frame 거의 없음

## AI 협업 핵심 메모

- 4-pattern 조합 (sweep + unawaited + 방향성 비대칭 + 썸네일 layering)은 팀 X / Y / Z / D / E / F 6개 팀 교차검증의 결론.
- 모순 해결: debounce 대신 unawaited init / token 대신 slot identity / Provider.family 대신 View state Map.
- 13개 예외 케이스 자문자답 완료 (PageController.dispose / cold start / cache LRU evict / 방향 reset 등).

## 후속 작업

- P04에서 Overlay UI (action_button, feed_overlay)
- P07에서 WidgetsBindingObserver의 didChangeAppLifecycleState + didHaveMemoryPressure 보강

## 참조

- plan: `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §4 전체
