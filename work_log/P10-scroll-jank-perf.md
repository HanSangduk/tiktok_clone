---
id: P10
title: 스크롤 jank 진단 + 개선 (peek 메모리캐시 / setState 조건 / RepaintBoundary)
status: 완료
domain: video
created: 2026-05-12
completed: 2026-05-12
---

## 목표

Galaxy S21 release 모드에서 영상 → 영상 전환 시 매번 발생하는 jank의 진짜 원인을 찾고, 데이터 기반으로 최소 변경만 적용한다.

## 결정 사항

3개 팀(G/H/I) 교차검증 후 plan v2 도출. 5개 후보 중 명확히 효과 있는 3개만 채택:
- **P1 (HIGH)**: `VideoCacheResolver.peek`에 메모리 캐시 (`Map<String, File?>`) → 두 번째 호출부터 sqlite query skip
- **P2 (MED)**: `_ensure` 콜백의 `setState`를 `i == _currentlyPlayingIdx`일 때만 호출 → preload 완료 시 불필요한 rebuild 차단
- **P3 (LOW)**: `video_page.dart` Stack의 `FeedOverlay`를 `RepaintBoundary`로 감싸기

진단 데이터상 효과 없음 판명되어 **보류**:
- ~~dispose `Priority.idle`~~ — dispose 평균 15μs (frame budget의 0.1%)
- ~~sweep pause `Priority.idle`~~ — syncPool TOTAL 1.5ms 양호
- ~~setState 제거~~ — 회귀 위험 (FeedScreen이 currentIndex watch 안 함)
- ~~gaplessPlayback~~ — ImageProvider 변경 시나리오 없음

## 진행 단계

- [x] 3팀 병렬 분석 (G: Flutter 내부 동작 / H: 진단 로그 부작용 / I: 개선안 위험성)
- [x] 진단 로그 6곳 적용 (kDebugMode 가드 + Stopwatch)
- [x] release 빌드 + 사용자 logcat 수집 (Before 측정)
- [x] 102개 JANK 로그 분석 → 진짜 원인 발견 (peek sqlite query 4~8ms)
- [x] P1/P2/P3 적용
- [x] release 빌드 + 사용자 logcat 재수집 (After 측정)
- [x] 효과 검증 (peek -73%, setState -95%, FeedScreen build -88%)

## 변경 파일

- (수정) `lib/data/video_cache_resolver.dart` — `_memCache` 추가, prefetch 후 invalidate
- (수정) `lib/features/feed/feed_screen.dart` — Log 6곳 + setState 조건
- (수정) `lib/features/feed/video_page.dart` — FeedOverlay RepaintBoundary 래핑

## 검증

| 메트릭 | Before | After | 개선율 |
|---|---|---|---|
| `ensure peek` 평균 | 5,200μs | 1,400μs | **-73%** |
| `ensure peek` 최대 | 7,778μs | 2,015μs | -74% |
| `setState` 빈도 | 매 ensure × N | active만 | **-95%+** |
| `FeedScreen build` 빈도 | ~16회 | 2회 | **-88%** |

## AI 협업 핵심 메모

- 첫 v1 plan에서 microtask dispose 등을 적용하려 했으나, 3팀 교차검증으로:
  - `Future.microtask`는 같은 frame 내 처리 → 효과 미미. `SchedulerBinding.scheduleTask(Priority.idle)` 권장 (팀 G)
  - `setState 제거`는 회귀 (FeedScreen이 currentIndex watch 안 함) (팀 I)
  - 진단 로그 9곳 자체가 jank 유발 → 6곳 + kDebugMode 가드 (팀 H)
- **데이터 없이 개선 적용 금지** 원칙 — 진단 후 peek가 진짜 원인으로 확정되자 P1/P2/P3만 적용

## 후속 작업

- (옵션) `FutureOr<File?>` 패턴으로 peek 메모리 hit 시 동기 반환 → 추가 ~50% 감소 가능. 현재 1~2ms도 양호하므로 보류.
- 진단 로그(Log 1~6)를 P09 제출 전 제거 또는 영구 유지 결정.

## 참조

- plan: `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` (v2 진단 plan)
- log: `/Users/straram/development/tiktok_clone/log` (Before + After raw logcat)
