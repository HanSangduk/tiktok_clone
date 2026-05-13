---
date: 2026-05-11
phase: P08-readme-ai-docs
agent: Claude Code (Opus 4.7, 1M context)
my_role: README 톤·길이 조정 + Q1/Q2/Q3 검토
ai_role: 구조 제안 + 키워드 정리
---

## 맥락

평가자가 README를 5분 안에 스캔할 수 있는 구조 필요. Q1/Q2/Q3는 가장 비중 큰 영역.

## 내 프롬프트 (요약)

> README 첫 30초가 합/불을 가른다고 가정하고 구조 짜줘. Q1은 200~250자 ×3 / Q2는 4분면 키워드 / Q3는 500자 스토리텔링.

## AI 응답 핵심

- 섹션 순서: `TL;DR (영상 임베드)` → `Quick Start` → `Performance` → `사용 패키지` → `구현 기능` → `프로젝트 구조` → `Q1` → `Q2` → `Q3` → `AI 사용` → `한계` → `참고`
- Q2.4(성능 최적화)는 카테고리별 키워드 30개+ — 게임 회사(슈퍼센트) 평가자가 한눈에 깊이 파악 가능
- Q3는 4-pattern 조합 (sweep + unawaited + 방향성 + 썸네일) 으로 단일 설계가 4가지 문제를 동시에 해결한 스토리

## 내가 채택·거부한 것

**채택**: 전체 구조 + Q2.4 35개 키워드 카테고리.

**거부**:
- 너무 많은 도표 (overload) — 표 3개로 한정 (사용 패키지 / AI 사용 / 키워드)
- AnimatedSwitcher 페이드 효과 README 강조 — 사실 채택 안 했으므로 명시 X
- "TikTok 95% down-scroll" 같은 수치 — 실제 통계 없어 "TikTok 사용자의 95% down-scroll 패턴"으로 휴리스틱 표현

## 직접 작성한 부분

- "본인이 직접 작성·결정한 핵심 부분" 섹션 (Google 403 발견·해결, Flutter 업그레이드 결정 등)
- 한국어 caption 작성 (mock_videos.dart)
- "한계와 개선 계획" 솔직 기재 항목 7개

## 원본 위치

raw transcript Phase 12 (이번 P08) / `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §8
