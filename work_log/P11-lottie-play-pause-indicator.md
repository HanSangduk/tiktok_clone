---
id: P11
title: Lottie 애니메이션 (더블탭 하트 splash + 좋아요 토글 4-hearts) + Pause indicator
status: 완료
domain: ui
created: 2026-05-13
completed: 2026-05-13
---

## 목표

UI 디테일 보강 3가지:
1. 단탭 play/pause 토글 시 pause 상태에서 가운데 흐릿한 play 아이콘 표시
2. 더블탭 시 큰 하트 splash 애니메이션 (Lottie 11개 하트)
3. 좋아요 토글 OFF→ON 시 4개 하트가 위로 올라가는 Lottie

## 결정 사항

- **외부 인터페이스 유지**: `LikeAnimation(animation: ...)` prop 그대로 → video_page.dart 변경 최소화. 내부만 Lottie로 교체.
- **좋아요 분리**: 좋아요 버튼만 `HeartActionButton` (ConsumerStatefulWidget)으로 분리. 다른 ActionButton (comment, share)는 그대로.
- **isLiked false→true 감지**: `_wasLiked` 필드로 추적, build 안에서 비교. TikTok 동일 동작 (OFF→ON 시에만 Lottie 재생, ON→OFF는 X).
- **PlayPauseIndicator**: VideoPlayerController.value.isPlaying 감지, AnimatedOpacity 0.7/0.0 (150ms fade).
- `_likeAnim` duration 700ms → 1200ms (lt_touch_heart composition duration 매칭).

## 진행 단계

- [x] `assets/icons/ic_play.svg` (흰색 채워진 삼각형, Lucide play 스타일)
- [x] `lib/features/feed/widgets/play_pause_indicator.dart` (IgnorePointer + AnimatedOpacity + SvgPicture)
- [x] `lib/features/feed/widgets/like_animation.dart` Lottie로 내부 교체 (lt_touch_heart, 320x320)
- [x] `lib/features/feed/widgets/heart_action_button.dart` 신규 (ConsumerStatefulWidget + lt_move_heart + _wasLiked 가드)
- [x] `lib/features/feed/widgets/feed_overlay.dart` 좋아요 ActionButton → HeartActionButton 교체
- [x] `lib/features/feed/video_page.dart` Stack layer 5 추가 (PlayPauseIndicator) + _likeAnim 1200ms
- [x] `flutter analyze` No issues found
- [x] `flutter test` All tests passed

## 변경 파일

신규:
- `assets/icons/ic_play.svg`
- `lib/features/feed/widgets/play_pause_indicator.dart`
- `lib/features/feed/widgets/heart_action_button.dart`

수정:
- `lib/features/feed/widgets/like_animation.dart` (Lottie로 교체)
- `lib/features/feed/widgets/feed_overlay.dart` (좋아요 자리 교체, `isLiked`/`toggleLike` 로컬 변수 제거)
- `lib/features/feed/video_page.dart` (PlayPauseIndicator layer + duration 변경)

## 검증

- [x] flutter analyze 0 warning
- [x] flutter test 통과
- [ ] 디바이스 실행 — 단탭 pause → 가운데 ic_play 0.7 opacity fade-in
- [ ] 디바이스 실행 — 더블탭 → 1.2초 11-hearts splash
- [ ] 디바이스 실행 — 우측 좋아요 단탭(OFF→ON) → 4-hearts 위로, 카운트 +1
- [ ] 디바이스 실행 — 좋아요 단탭(ON→OFF) → Lottie 재생 X, 카운트 -1

## AI 협업 핵심 메모

- 첫 시도(prompt)에서 plan을 정독한 뒤 자문자답 13개로 위험 평가:
  - LikeAnimation 인터페이스 유지 → video_page.dart 변경 최소화
  - HeartActionButton 분리 → false→true 추적이 깔끔
  - Stack clipBehavior: Clip.none → Lottie가 ActionButton 위로 넘침 가능
  - Lottie composition duration 사전 1200/2000ms 설정 → onLoaded 전에도 일관 동작
- 회귀 위험 매우 낮음: 외부 API 유지, 새 위젯 추가 위주.

## 후속 작업

- 디바이스 실행 시연으로 시각 효과 검증 후 P11 완전 종료

## 참조

- plan: `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` (P11 섹션)
- assets: `assets/lottie/lt_touch_heart.json`, `assets/lottie/lt_move_heart.json`
