# AI 대화 발췌 (정제본)

본 폴더는 Claude Code(Opus 4.7)와의 핵심 대화를 발췌해 정리한 것입니다.
원본 raw transcript는 `../ai-raw-transcripts/*.jsonl.gz` 참조.

## 발췌 인덱스 (P{nn} ↔ 발췌 1:1 매핑)

| # | 발췌 파일 | 출처 P 파일 | 주제 |
|---|---|---|---|
| 01 | [architecture-mvvm-decision.md](01-architecture-mvvm-decision.md) | P01 | MVVM + feature-first slim 폴더 구조 결정 (3 후보 → 교차검증) |
| 02 | [riverpod-3x-notifier-pattern.md](02-riverpod-3x-notifier-pattern.md) | P02 | Riverpod 3.x 코드젠 X + Notifier/AsyncNotifier 직접 정의 결정 |
| 03 | [video-lifecycle-mini-pool.md](03-video-lifecycle-mini-pool.md) | P03 | mini-pool ±1 → 방향성 비대칭 + unawaited race-safe 패턴 도출 |
| 04 | [direction-aware-and-thumbnail.md](04-direction-aware-and-thumbnail.md) | P03 | 6개 팀 병렬 분석(X/Y/Z/D/E/F) 교차검증 — 디바운싱 X, 썸네일 layering 채택 |
| 05 | [pageview-controller-race.md](05-pageview-controller-race.md) | P03 | Q3 답변 — 13개 예외 케이스 자문자답 |
| 06 | [readme-q1-q2-q3-drafting.md](06-readme-q1-q2-q3-drafting.md) | P08 | README 구조 + Q1/Q2/Q3 답변 톤·길이 가이드 |

## 발췌 1건 템플릿

```
---
date: YYYY-MM-DD
phase: P{nn}-{title}
agent: Claude Code (Opus 4.7, 1M context)
my_role: ...
ai_role: ...
---

## 맥락
## 내 프롬프트 (요약)
## AI 응답 핵심
## 내가 채택·거부한 것
## 직접 작성한 부분
## 원본 위치 (raw transcript 라인)
```

각 발췌는 raw transcript의 핵심 구간을 정제한 것이며, **"내가 무엇을 채택/거부하고 왜 그랬는지"** 의 의사결정 흔적이 핵심입니다.
