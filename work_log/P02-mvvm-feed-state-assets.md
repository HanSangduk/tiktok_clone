---
id: P02
title: MVVM 코어 + Mock data + 썸네일 자산 + VideoCacheResolver
status: 완료
domain: state
created: 2026-05-11
completed: 2026-05-11
---

## 목표

MVVM의 Model + Data 레이어 + ViewModel 3종 + 비디오 자산(영상 URL 25개 + 썸네일 13장) + 디스크 캐싱 래퍼를 구축. P03의 FeedScreen이 곧바로 ViewModel을 구독해 PageView를 렌더할 수 있는 상태로 만든다.

## 결정 사항

- **VideoPost 모델**: plain Dart class + `copyWith` + `==`/`hashCode`. freezed 미사용.
- **Mock URL 13개**: Google `commondatastorage.googleapis.com/gtv-videos-bucket/sample/` 의 faststart 검증된 영상. id만 다르게 반복해 25개 채움.
- **VideoRepository**: `fetchPage(int page, {int size=5})` + `await Future.delayed(500ms)` 로딩 시뮬.
- **FeedViewModel**: AsyncNotifier 페이지네이션, `hasMore` getter, `loadMore()` idempotent.
- **CurrentIndexViewModel**: Notifier<int>, Riverpod 3.x StateProvider deprecated 대응.
- **LikedSetViewModel**: Notifier<Set<String>>, `toggle(id)` 메서드만 노출.
- **썸네일**: `scripts/extract_thumbnails.sh`로 ffmpeg 추출 → `assets/thumbnails/*.jpg`.
- **VideoCacheResolver**: `flutter_cache_manager`의 `peek`(캐시 hit만 확인) + `prefetch`(백그라운드 다운로드) 2 메서드.

## 진행 단계

- [x] work_log/P02 파일 작성 + README 인덱스 업데이트
- [x] ffmpeg/ffprobe 설치 확인 (이미 /opt/homebrew/bin/ffmpeg 7.1)
- [x] `lib/models/video_post.dart` (VideoPost + copyWith + ==/hashCode)
- [x] `lib/data/mock_videos.dart` — Google sample이 403이라 **10개 안정 URL로 교체** (flutter.github.io + test-videos.co.uk + samplelib)
- [x] `lib/data/video_repository.dart`
- [x] `lib/data/video_cache_resolver.dart`
- [x] `lib/features/feed/feed_view_model.dart` (FeedViewModel + CurrentIndexViewModel + LikedSetViewModel)
- [x] `scripts/extract_thumbnails.sh` (curl + ffmpeg 로컬 추출, samplelib streaming 호환성 회피)
- [x] 스크립트 실행 → `assets/thumbnails/*.jpg` **10장** 생성 (14KB~109KB, 합 670KB)
- [x] `flutter analyze` 0 warning
- [x] `flutter test` 통과

## 변경 파일

- (신규) lib/models/video_post.dart
- (신규) lib/data/mock_videos.dart
- (신규) lib/data/video_repository.dart
- (신규) lib/data/video_cache_resolver.dart
- (신규) lib/features/feed/feed_view_model.dart
- (신규) scripts/extract_thumbnails.sh
- (신규) assets/thumbnails/*.jpg × 13

## 검증

- [x] flutter analyze — No issues found!
- [x] flutter test — All tests passed!
- [x] `ls assets/thumbnails | wc -l` → **10** (URL 10개로 축소)
- [x] 모든 mock URL HTTP 200 확인 (curl -I)

## 변경 내역: Google sample 403 이슈 대응

원 plan은 `commondatastorage.googleapis.com/gtv-videos-bucket/sample/*.mp4`의 13개 영상이었으나
2026년 5월 시점 모두 **HTTP 403 Forbidden**으로 응답. 대체 URL 검증 후 다음 10개 채택:
- `flutter.github.io/assets-for-api-docs/assets/videos/{butterfly,bee}.mp4` (2개, Flutter 공식)
- `test-videos.co.uk/vids/{bigbuckbunny,jellyfish,sintel}/mp4/h264/720/*_10s_2MB.mp4` (3개)
- `download.samplelib.com/mp4/sample-{5,10,15,20,30}s.mp4` (5개)

모두 HTTPS + content-type=video/mp4. mock 25개는 10개를 id만 다르게 반복.

## AI 협업 핵심 메모

- 캐싱 패키지 결정: 3개 옵션(미구현 / flutter_cache_manager / cached_video_player_plus) 중 flutter_cache_manager 채택. 사용자 명시 video_player를 그대로 유지하면서 디스크 캐싱 효익 확보.
- 첫 시청 전략: 전략 3b (progressive playback + 백그라운드 cache 다운로드) — 첫 TTFF 희생 X, 2바퀴+부터 file:// hit.
- 썸네일 사전 추출 결정: 옵션 A (ffmpeg JPEG) 채택. 런타임 생성(B) 대비 결정성 ↑.

## 후속 작업

- P03에서 FeedScreen `_syncPool`이 VideoCacheResolver.peek를 호출

## 참조

- plan: `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §3, §4.5
- 팀 E 캐싱 분석, 팀 F 썸네일 분석
