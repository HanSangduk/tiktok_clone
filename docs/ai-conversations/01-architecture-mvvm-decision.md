---
date: 2026-05-11
phase: P01-project-bootstrap
agent: Claude Code (Opus 4.7, 1M context)
my_role: 요구사항 정의 (Riverpod+GoRouter, MVVM, 과한 모듈화 금지) + 최종 선택
ai_role: 3 후보안 설계 + 교차검증
---

## 맥락

슈퍼센트 Flutter 과제. 1인 개발자로서 이해/수정 쉬운 구조 필요. 평가에서 "확장 가능한 구조"가 가산점이지만 over-engineering은 감점.

## 내 프롬프트 (요약)

> Riverpod + GoRouter 사용, MVVM 패턴 적용. 과한 모듈화 금지. 폴더 구조를 어떻게 짜야 1인 개발 + 평가 모두 만족시킬 수 있을까. 여러 관점의 팀을 병렬로 굴려서 교차검증해줘.

## AI 응답 핵심

3 후보안을 병렬 Plan 에이전트로 받음:
- **팀 A (미니멀)**: 평면 feature-first, lib 11개 파일, `providers/feed_providers.dart` 한 파일에 모든 Provider
- **팀 B (평가자)**: feature-first + `presentation/providers/controllers/` 3-depth, Controller Pool 패턴 ViewModel 분리
- **팀 C (AI증빙)**: docs/ai-conversations 3계층 + work_log P 파일

## 내가 채택·거부한 것

**채택**:
- 팀 A의 평면 구조 베이스 (depth 2 고정, premature abstraction 회피)
- 팀 B의 Controller Pool 패턴 컨셉은 **View state로 끌어내려서** 적용 (ViewModel로 끌어올리면 race)
- 팀 C의 3계층 AI 증빙 (`AI_USAGE.md` + `ai-conversations/` + raw transcript)

**거부**:
- 팀 B의 `presentation/providers/controllers/` 3-depth — 1-feature에 과잉
- 팀 B의 `Provider.family<VideoControllerState, VideoId>` — autoDispose 타이밍 race 위험

## 직접 작성한 부분

- MVVM 매핑 (Model=models / View=features/*/* / ViewModel=*_view_model.dart / Repository=data) 명시
- "단일 도메인 ViewModel 3종은 1개 파일에 모음" 규칙 (1인 grep 친화)
- CLAUDE.md 룰 정리 (`StateProvider` 사용 금지, mini-pool ±1 고정 등)

## 원본 위치

raw transcript Phase 2 (3개 Plan 에이전트 병렬 실행) 결과 / `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §2, §13
