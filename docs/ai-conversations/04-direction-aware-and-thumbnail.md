---
date: 2026-05-11
phase: P03-video-lifecycle-perf
agent: Claude Code (Opus 4.7, 1M context)
my_role: 빠른 스크롤 UX 문제 정의 + 솔루션 채택
ai_role: 6 팀(X/Y/Z/D/E/F) 병렬 분석 + 교차검증
---

## 맥락

빠른 5장 연속 스크롤 시 (1) 검은 화면 (2) buffer stutter (3) 메인 thread block. "디바운싱 혹은 더 좋은 방법" + "썸네일로 끊김 없는 느낌" 요구.

## 내 프롬프트 (요약)

> 스크롤 방향성에 따라 preload/evict 우선순위 다르게 해야 하고, 비디오 캐싱도 필요해. 매우 빠른 스크롤 시 끊기지 않게 썸네일로 가려주는 것까지 고려해서 여러 팀 병렬 분석 후 교차검증.

## AI 응답 핵심

3개 팀 병렬:
- **팀 D (방향성)**: down 시 keep={i-1,i,i+1,i+2}, up 시 {i-2,i-1,i,i+1}, none 시 {i,i+1,i+2}. 단일 `_syncPool(idx)` 함수에 통합.
- **팀 E (캐싱)**: `flutter_cache_manager` 채택. peek 전략(전략 3b) — 첫 시청 progressive, 백그라운드 다운로드, 2바퀴+부터 file:// hit.
- **팀 F (썸네일)**: ffmpeg 사전 추출 → assets/thumbnails/*.jpg, Stack[Image.asset + VideoPlayer] layering. debounce 불필요, unawaited init이 더 효과적.

## 내가 채택·거부한 것

**채택 전부**:
- 방향성 비대칭 keep set (down 95% 패턴 최적화)
- `flutter_cache_manager` (`cached_video_player_plus` 대신 — 사용자 명시 video_player 그대로 유지)
- 사전 추출 썸네일 (ffmpeg 1회) + Stack layering
- `unawaited` init (debounce/throttle보다 우월)

**거부**:
- `isScrollingNotifier` 디바운싱 (`unawaited` init이 더 단순)
- `_syncToken` monotonic 패턴 (slot identity로 충분)
- `AnimatedSwitcher` / `AnimatedOpacity` 페이드 (썸네일 첫 프레임 = 영상 첫 프레임이라 즉시 교체로 자연 전환)
- `cached_video_player_plus` (사용자 명시 video_player와 다른 fork)

**자문자답으로 13개 예외 케이스 처리**: PageController.dispose / cold start splash → feed 타이밍 / cache LRU evict / 방향 reset / 비행기 모드 / OS 임시 디렉터리 청소 / 같은 URL 동시 prefetch dedup / 영상 init 영구 실패 등.

## 직접 작성한 부분

- Mock URL 검증 (Google sample 403 → curl/ffprobe로 대체 URL 검증 → samplelib streaming 호환 안 됨 → 다운로드 후 추출 방식으로 변경)
- 13개 영상 → 10개로 축소 결정 (의도된 다양성 일부 희생, stutter 0 우선)
- ffmpeg 스크립트의 curl + 로컬 추출 패턴

## 원본 위치

raw transcript Phase 9 (팀 D/E/F 병렬) / `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §4.2~§4.5
