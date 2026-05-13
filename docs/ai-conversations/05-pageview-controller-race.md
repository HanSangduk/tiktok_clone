---
date: 2026-05-11
phase: P03-video-lifecycle-perf
agent: Claude Code (Opus 4.7, 1M context)
my_role: 예외 케이스 자문자답 가이드 + 최종 검증
ai_role: 시나리오별 대응 패턴 제시
---

## 맥락

Q3 답변 작성을 위해 "가장 어려웠던 문제 — 빠른 스크롤 시 4가지 문제 동시 발생" 시나리오 정리.

## 내 프롬프트 (요약)

> mini-pool 구현 중 만난 예외 케이스를 모두 자문자답으로 사전 도출하고 싶어. 13개 정도 시나리오 던져봐.

## AI 응답 핵심 (13개 예외 케이스)

| # | 케이스 | 처리 |
|---|---|---|
| 1 | PageController.dispose 시 _pool 정리 | `State.dispose`에서 pool 전체 dispose |
| 2 | Splash 1.5s 후 첫 _syncPool(0) 타이밍 | initState `addPostFrameCallback` + feedViewModel listen 0→N 전환 시 호출 |
| 3 | feedViewModel loading 중 _syncPool | `??const []` + maxIdx=-1 → no-op, data 도착 후 setState로 재호출 |
| 4 | unawaited init 도중 evict | `_pool[i] != c` slot identity → dispose |
| 5 | cache_manager 파일 LRU evict 후 controller 재사용 | controller가 native buffer 보유, 재생 계속 |
| 6 | 첫 시청 progressive + cache_manager 동시 fetch (네트워크 2배) | 시뮬레이터 부담 X, production은 Q2 키워드로 |
| 7 | 썸네일 추출 실패 (ffmpeg 에러) | `Image.asset(errorBuilder:)` → 검정 fallback |
| 8 | 영상 init 영구 실패 | catchError → slot 제거, 썸네일 유지 |
| 9 | OS 임시 디렉터리 청소 | `getFileFromCache` null → 네트워크 fallback |
| 10 | 같은 URL 두 슬롯 동시 prefetch | cache_manager 내부 dedup |
| 11 | 방향 reset (down→up 실수) | 즉시 갱신, idempotent ensure로 짧은 init |
| 12 | 비행기 모드 + 2바퀴 (캐시 hit) | file:// 재생 정상 |
| 13 | controller가 parent prop 변경 시 VideoPage rebuild | parent setState로 자동 |

## 내가 채택·거부한 것

**채택**: 13개 모두 그대로. 추가로:
- **14번**: VideoPage의 GestureDetector — onTap + onDoubleTap 등록 시 onTap ~300ms 지연. TikTok도 동일하므로 받아들임.

**거부**: 없음 (모든 시나리오를 plan에 명시).

## 직접 작성한 부분

- 14번 케이스 (GestureDetector 충돌) 추가
- Q3 답변 톤 조정 ("init 속도가 아니라 init 시간을 가리는 UX 설계"라는 메타 학습 추가)

## 원본 위치

raw transcript Phase 11 (자체 검토 + 예외 자문자답) / `/Users/straram/.claude/plans/fuzzy-crunching-plum.md` §7
