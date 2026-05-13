---
date: 2026-05-11
phase: P02-mvvm-feed-state-assets
agent: Claude Code (Opus 4.7, 1M context)
my_role: 코드젠 도입 여부 결정 + ViewModel 3종 분할 결정
ai_role: 3.x API 차이점 정리 + 코드 패턴 제시
---

## 맥락

Riverpod 3.3.1 사용. 3.x는 코드젠(`@riverpod`)을 강하게 권장하며 `StateProvider`가 deprecated. 사용자 요구: 과한 모듈화 금지, 1인 유지보수 우선.

## 내 프롬프트 (요약)

> Riverpod 3.x에서 코드젠을 도입하는 게 표준이라는데 build_runner 부담이 걸린다. 1인 개발 + 단일 화면 규모에서 코드젠을 꼭 써야 하나? StateProvider deprecated는 어떻게 대응?

## AI 응답 핵심

- Riverpod 3.x도 `Notifier` / `AsyncNotifier` 클래스 직접 정의는 **first-class 지원** (deprecated 아님)
- 코드젠은 boilerplate 절감 vs build_runner watch + .g.dart 관리 부담 trade-off
- 단일 모델 + ViewModel 3개 규모면 직접 정의가 더 깔끔 (각 Provider 인스턴스 한 줄)
- `StateProvider` deprecated → 단순 `int` state도 `NotifierProvider<MyVM, int>(MyVM.new)` 패턴으로 통일

## 내가 채택·거부한 것

**채택**:
- 코드젠 **미도입** (build_runner 의존성 0)
- 모든 ViewModel을 `Notifier` 또는 `AsyncNotifier` 클래스로 직접 정의
- `CurrentIndexViewModel extends Notifier<int>` — `StateProvider` 대신 명시적 NotifierProvider
- 3종 ViewModel (Feed/CurrentIndex/Liked)을 `lib/features/feed/feed_view_model.dart` 1개 파일에 모음

**거부**:
- `riverpod_generator` / `@riverpod` annotation
- `freezed` / `json_serializable` (모델 1개에 빌드러너 비용 과잉)

## 직접 작성한 부분

- `FeedViewModel`의 `hasMore` getter (View가 트리거 시점 판단용)
- `LikedSetViewModel.toggle(id)` 시 `{...state}..remove(id)` immutable 복사 패턴
- `videoCacheResolverProvider` 추가 (P03에서 사용)

## 원본 위치

raw transcript Phase 5 + Phase 9 / `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §3
