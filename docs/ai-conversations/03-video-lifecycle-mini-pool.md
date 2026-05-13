---
date: 2026-05-11
phase: P03-video-lifecycle-perf
agent: Claude Code (Opus 4.7, 1M context)
my_role: Controller 위치 결정 (View state vs ViewModel) + race 회피 검증
ai_role: 3개 옵션 비교 + race 예외 케이스 도출
---

## 맥락

영상 컨트롤러를 어디서 관리할지 결정. ViewModel(Riverpod Notifier) vs View state(FeedScreen.State) vs InheritedWidget vs 별도 클래스.

## 내 프롬프트 (요약)

> mini-pool 패턴을 구현하려는데 controller를 ViewModel(Riverpod)에 두면 깔끔할 것 같지만 race가 걱정. 사용자 매우 빠른 스크롤 시에도 동시 재생 1개만 보장되어야 함. 어느 게 안전하면서도 단순한가?

## AI 응답 핵심

- **Provider.family로 끌어올리는 안**: autoDispose 타이밍이 위젯 lifecycle보다 늦/빨라 race. 거부.
- **View state Map**: FeedScreen.State에 `Map<int, VideoPlayerController>` 직접 보유. MVVM 원칙상 ViewModel에 위젯 자원(GPU 텍스처, 네이티브 핸들)을 두지 않는 것이 맞음.
- **단일 진입점 `_syncPool` 패턴**: 분산된 트리거(visibility, onPageChanged, 라이프사이클)에 의존하지 않고 하나의 함수에서 sweep.
- **`unawaited(c.initialize().then(...))` + slot identity 체크**: `_pool[i] != c` 로 race 시 dispose. 메인 thread block 0.

## 내가 채택·거부한 것

**채택**:
- View state Map 보유
- `_syncPool` 단일 진입점 sweep 패턴
- `unawaited` + slot identity (`_pool[i] != c`) race-safe init

**거부**:
- `Provider.family<VideoControllerState, VideoId>` (race + autoDispose 타이밍 위험)
- `InheritedWidget` 분리 (1인 개발에 과한 모듈화)
- `_syncToken` monotonic 패턴 (slot identity로 충분)
- `Timer` debounce (onPageChanged 자체가 settle 후 1회 fire라 불필요)

## 직접 작성한 부분

- `FeedScreen.didChangeAppLifecycleState` — paused/resumed 분기
- `didHaveMemoryPressure` — current 제외 dispose
- `_pool` dispose 시 `c.pause(); c.dispose();` 순서
- `feedViewModelProvider` listen으로 0→N 전환 시점에 `_syncPool(0)` 호출 보장

## 원본 위치

raw transcript Phase 6 (팀 X/Y/Z 성능 분석) / `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §4 전체
