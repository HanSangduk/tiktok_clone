# 작업 로그 (work_log)

슈퍼센트 Flutter 개발자 과제 — TikTok Clone 작업 로그.

## 인덱스

| # | 제목 | 상태 | 도메인 | 생성 | 완료 |
|---|---|---|---|---|---|
| [P01](P01-project-bootstrap.md) | 프로젝트 부트스트랩 + 폴더 구조 + 라우터 골격 | 완료 | bootstrap | 2026-05-11 | 2026-05-11 |
| [P02](P02-mvvm-feed-state-assets.md) | MVVM 코어 + Mock data + 썸네일 자산 + VideoCacheResolver | 완료 | state | 2026-05-11 | 2026-05-11 |
| [P03](P03-video-lifecycle-perf.md) | FeedScreen `_syncPool` + 방향성 비대칭 mini-pool + VideoPage 썸네일 layering | 완료 | video | 2026-05-11 | 2026-05-11 |
| [P04](P04-overlay-ui.md) | Overlay UI — 우측 액션 바 + 하단 username/caption | 완료 | ui | 2026-05-11 | 2026-05-11 |
| [P05](P05-like-interaction.md) | 더블탭 좋아요 애니메이션 + 단탭 play/pause 제스처 | 완료 | ui | 2026-05-11 | 2026-05-11 |
| [P06](P03-video-lifecycle-perf.md) | (P03에 통합) infinite scroll — `_syncPool` 6단계에 `loadMore` 트리거 포함 | 완료 | feed | 2026-05-11 | 2026-05-11 |
| [P07](P03-video-lifecycle-perf.md) | (P03에 통합) `WidgetsBindingObserver` lifecycle hook + memory pressure 처리 | 완료 | infra | 2026-05-11 | 2026-05-11 |
| [P08](P08-readme-ai-docs.md) | README + AI_USAGE + ai-conversations 6건 발췌 | 완료 | docs | 2026-05-11 | 2026-05-12 |
| [P09](P09-demo-video-perf-claim.md) | profile mode 영상 녹화 + ffmpeg 압축 + raw transcript 압축 + GitHub repo | 진행 중 | docs | 2026-05-12 | |
| [P10](P10-scroll-jank-perf.md) | 스크롤 jank 진단 + 개선 (peek 메모리캐시 / setState 조건 / RepaintBoundary) | 완료 | video | 2026-05-12 | 2026-05-12 |
| [P11](P11-lottie-play-pause-indicator.md) | Lottie 애니메이션 (더블탭 splash + 좋아요 4-hearts) + Pause indicator | 완료 | ui | 2026-05-13 | 2026-05-13 |

## 도메인 라벨 (이 프로젝트 enum)

- `bootstrap` — 초기 세팅 (Flutter 스캐폴드, pubspec, 폴더 구조, 라우터 골격)
- `feed` — 메인 피드 화면, PageView, infinite scroll
- `video` — 영상 플레이어 lifecycle, mini-pool, 캐싱
- `state` — Riverpod ViewModel 설계
- `ui` — 위젯, 애니메이션 (오버레이, 더블탭 하트), 아이콘
- `mock` — Mock 데이터, dummy repository
- `docs` — README, AI_USAGE.md, ai-conversations, Q1/Q2/Q3 답변
- `infra` — Android permissions, .gitignore, GitHub repo
- `mixed` — 여러 도메인 동시 (예: state+ui 동시)

## 형식

글로벌 CLAUDE.md "작업 로그 자동 운영" 규칙 따름. frontmatter 5필드 + 본문 7섹션.

## 참조 plan

- `/Users/straram/.claude/plans/fuzzy-crunching-plum.md`
