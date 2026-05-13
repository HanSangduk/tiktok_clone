---
id: P05
title: 더블탭 좋아요 애니메이션 + 단탭 play/pause 제스처
status: 완료
domain: ui
created: 2026-05-11
completed: 2026-05-11
---

## 목표

VideoPage에 제스처 + 더블탭 시 큰 하트 애니메이션.

- 단탭 → 영상 toggle (play/pause)
- 더블탭 → `likedSetViewModelProvider.toggle(post.id)` + 큰 하트 페이드/스케일 애니메이션 (TikTok 스타일)

## 결정 사항

- VideoPage를 `ConsumerStatefulWidget`으로 변경 (AnimationController 보유 위함).
- `GestureDetector(onTap, onDoubleTap)` — onDoubleTap 등록 시 onTap이 ~300ms 지연되는 건 의도된 동작 (받아들임). TikTok도 동일.
- `LikeAnimation`: 1회용 fire-and-forget. AnimationController로 0→1→0 → 0.0~0.3 페이드인+scale, 0.3~1.0 페이드아웃+scale 유지.
- 더블탭 시 항상 좋아요 ON으로 toggle (이미 좋아요면 OFF로). TikTok에서는 항상 ON으로 만들지만, 본 과제는 toggle이 가산점 항목 명시이므로 toggle 채택.

## 진행 단계

- [x] work_log/P05 작성
- [x] `lib/features/feed/widgets/like_animation.dart` (AnimatedBuilder + Opacity/Transform.scale 2단계: 0~0.3 페이드인+scale, 0.3~1.0 페이드아웃+scale)
- [x] VideoPage → ConsumerStatefulWidget 변경 (SingleTickerProviderStateMixin)
- [x] AnimationController 추가 (700ms), dispose
- [x] onTap: controller.value.isPlaying ? pause : play
- [x] onDoubleTap: ref.read(likedSetViewModelProvider.notifier).toggle(post.id) + animation.forward(from: 0)
- [x] LikeAnimation 위젯 Stack 추가 layer (RepaintBoundary)
- [x] flutter analyze 0 warning

## 변경 파일

- (신규) lib/features/feed/widgets/like_animation.dart
- (수정) lib/features/feed/video_page.dart

## 검증

- [ ] flutter analyze 0 warning
- [ ] 단탭/더블탭 충돌 없음 (시뮬레이터)
- [ ] 더블탭 시 하트 0.6초 페이드 동작

## 참조

- plan: §11 영상 콘티 0:30~0:55
