---
id: P08
title: README + AI_USAGE + ai-conversations 발췌 + Q1/Q2/Q3 답변
status: 완료
domain: docs
created: 2026-05-11
completed: 2026-05-12
---

## 목표

평가자가 5분 안에 합격 시그널을 확인할 수 있는 README + AI 사용 증빙 3계층.

## 결정 사항

- README는 plan §8 구조 그대로. TL;DR + Performance + Quick Start + 사용 패키지 표 + 구현 기능 + 폴더 구조(MVVM) + Q1/Q2/Q3 + AI 사용 + 한계.
- `docs/AI_USAGE.md` 1페이지 요약 + 영역별 표.
- `docs/ai-conversations/` 핵심 발췌 6건 (architecture/state/lifecycle/double-tap/pageview-race/readme-drafting).
- raw transcript는 P09 단계에서 압축.

## 진행 단계

- [x] work_log/P08 작성
- [x] README.md 전면 재작성 (TL;DR/Performance/Quick Start/패키지/구현기능/구조/Q1/Q2/Q3/AI사용/한계)
- [x] docs/AI_USAGE.md (1페이지 요약 + 영역별 표 + 핵심 협업 패턴)
- [x] docs/ai-conversations/README.md + 6건 발췌 (architecture/riverpod/lifecycle/direction-thumbnail/exceptions/readme)
- [x] flutter analyze 0 warning 유지

## 변경 파일

- (수정) README.md
- (신규) docs/AI_USAGE.md
- (신규) docs/ai-conversations/README.md
- (신규) docs/ai-conversations/01-architecture-mvvm-decision.md
- (신규) docs/ai-conversations/02-riverpod-3x-notifier-pattern.md
- (신규) docs/ai-conversations/03-video-lifecycle-mini-pool.md
- (신규) docs/ai-conversations/04-direction-aware-and-thumbnail.md
- (신규) docs/ai-conversations/05-pageview-controller-race.md
- (신규) docs/ai-conversations/06-readme-q1-q2-q3-drafting.md

## 검증

- [ ] README 첫 30초 스캔에 TL;DR + 영상 임베드 자리 + Performance 보임
- [ ] Q1/Q2/Q3 답변 2000자 ± 200
- [ ] AI 사용 표 7행 + 발췌 6건 매핑

## 참조

- plan: §8 README 구조 + §9 AI 증빙 3계층
