---
id: P04
title: Overlay UI — 우측 액션 바 + 하단 username/caption
status: 완료
domain: ui
created: 2026-05-11
completed: 2026-05-11
---

## 목표

영상 위 오버레이 UI 구현 (P05의 좋아요 인터랙션 직전).

- 오른쪽: Like / Comment / Share — SVG 아이콘 + 카운트
- 하단: username (굵게) + caption
- VideoPage Stack의 추가 RepaintBoundary layer로 통합

## 결정 사항

- `ActionButton` 재사용 위젯: SVG + count + onTap. 분리도 단순 (props 4개).
- `FeedOverlay`: 우측 Column + 하단 Container. SafeArea 고려.
- 카운트 포맷: 1,200 → "1.2K" / 1,234,500 → "1.2M". 작은 유틸 함수.
- Like 버튼은 P05에서 LikedSetViewModel 연결. 지금은 기본 상태(흰색 하트)만 표시.
- RepaintBoundary: BottomCaption / RightActions 각각 1겹씩.

## 진행 단계

- [x] work_log/P04 작성
- [x] `lib/features/feed/widgets/action_button.dart` (SVG + 카운트 + onTap, color filter)
- [x] `lib/features/feed/widgets/feed_overlay.dart` (ConsumerWidget로 `likedSetViewModelProvider.select` 직접 watch — 영상 layer rebuild 차단)
- [x] VideoPage에 FeedOverlay 통합 (Stack 추가 layer)
- [x] flutter analyze 0 warning

## 변경 결정

- FeedOverlay를 `ConsumerWidget`으로 격상 → 부모(VideoPage)에서 isLiked/onLike props 전달 없이 자체 watch.
  - 이유: 좋아요 변경 시 FeedOverlay만 rebuild되고 VideoPage(영상 layer 포함)는 rebuild되지 않음 → jank 0.
- comment/share는 placeholder SnackBar "Coming soon".

## 변경 파일

- (신규) lib/features/feed/widgets/action_button.dart
- (신규) lib/features/feed/widgets/feed_overlay.dart
- (수정) lib/features/feed/video_page.dart

## 검증

- [ ] flutter analyze 0 warning
- [ ] (P03 통합 검증 시) 오버레이가 영상 위에 잘 보임 + 텍스트 그림자/그라데이션 가독성

## 참조

- plan: §2, §3 폴더 구조 + Lucide SVG 자산
