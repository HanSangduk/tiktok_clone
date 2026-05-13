# AI 사용 내역 (1페이지 요약)

본 과제(TikTok Clone)는 **Claude Code (Opus 4.7, 1M context)** 를 페어 프로그래밍 파트너로 활용했습니다. 코드 작성·아키텍처·패턴 모두 AI와 협업했으며, 모든 의사결정은 지원자가 직접 검토/채택/거부했습니다.

## 사용 도구

| 도구 | 용도 |
|---|---|
| Claude Code (Opus 4.7, 1M context) | 메인 페어 프로그래밍, 아키텍처 자문, 코드 생성 |

다른 AI 도구(ChatGPT, Copilot, Cursor 등)는 본 과제에서 사용하지 않았습니다.

## 작업 범위 표

| 영역 | AI % | 직접 % | 비고 |
|---|---|---|---|
| 폴더 구조 / 아키텍처(MVVM) | 30 | 70 | 후보안 3개 받고 1인 유지보수 관점에서 직접 선택 |
| 패키지 선정 + 최신 버전 매칭 | 40 | 60 | 4개 패키지 버전 사전 명시, 보강 2개만 AI 자문 |
| UI 위젯 코드 | 60 | 40 | boilerplate AI, 디자인 디테일 직접 |
| Riverpod ViewModel | 50 | 50 | 패턴 AI, state 분리·toggle 로직 직접 |
| 영상 lifecycle (mini-pool + 방향성) | 50 | 50 | 패턴 AI, race·예외 케이스 13개 사전 도출은 자문자답으로 직접 |
| Mock data | 90 | 10 | URL 리스트·메타데이터 AI 생성, Google 403 발견·해결은 직접 |
| README / 문서 | 50 | 50 | 구조 AI, Q1/Q2/Q3 답변은 직접 작성·수정 |

**라인 수 기준 추정**: 약 AI 55% / 직접 45%. **의사결정 무게 기준**: 직접 ↑.

## 핵심 협업 패턴

1. **다중 팀 병렬 의견 → 교차검증**: Claude로 동일 문제에 대해 3~6개 관점의 Plan 에이전트를 병렬 실행 (예: "팀 X 렌더링" / "팀 Y 비디오 파이프라인" / "팀 Z 메모리" / "팀 D 방향성 preload" / "팀 E 캐싱" / "팀 F 썸네일"). 결과를 교차검증해 모순 해결, 합의된 패턴만 채택.
2. **자문자답으로 예외 케이스 사전 도출**: PageController.dispose / cold start / cache LRU evict / 방향 reset / 네트워크 실패 등 13개 예외를 사전에 자문자답으로 처리.
3. **단계별 work_log 자동 기록**: 각 P{nn} 파일이 곧 AI 협업 로그.

## 본인이 직접 작성·결정한 핵심 부분

- 모든 패키지 선정 결정 (특히 코드젠 미도입, `cached_video_player_plus` 대신 `flutter_cache_manager` 채택)
- Google `commondatastorage` sample URL의 **403 Forbidden 이슈 발견** → curl로 대체 URL 검증 → ffmpeg streaming 호환성 디버깅 (samplelib는 streaming 안 되어 다운로드 후 추출로 변경) → 10개 안정 sample URL로 mock 재구성
- Flutter SDK 업그레이드 결정 (사용자 명시 패키지 최신 버전 vs 다운그레이드)
- Q1/Q2/Q3 답변 톤·길이 직접 조정
- mock_videos.dart의 한국어 caption / username (10개)

## 대화 기록

- 정제 발췌: [`docs/ai-conversations/`](./ai-conversations/) 6건
- 원본 transcript: `docs/ai-raw-transcripts/*.jsonl.gz` (제출 시 압축본 첨부)

## 작업 로그

- `work_log/` 디렉터리에 P01~P09 단계별 마크다운 (각 P 파일 = AI 협업 핵심 메모 포함)
