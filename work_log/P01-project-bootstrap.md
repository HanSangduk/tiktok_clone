---
id: P01
title: 프로젝트 부트스트랩 + 폴더 구조 + 라우터 골격
status: 완료
domain: bootstrap
created: 2026-05-11
completed: 2026-05-11
---

## 목표

`flutter create` 스캐폴드 상태에서 → `flutter run`이 splash → 빈 feed 화면으로 동작하는 프로젝트 골격 구축. 의존성, MVVM 폴더 구조, GoRouter, 다크 테마, Lucide SVG 아이콘, widget_test 교체까지 한 번에.

## 결정 사항

- 패키지 버전(사용자 명시): `flutter_riverpod ^3.3.1`, `go_router ^17.2.3`, `video_player ^2.11.1`, `flutter_svg ^2.3.0`
- 추가: `visibility_detector ^0.4.0+2`, `flutter_cache_manager ^3.4.1`
- 아키텍처: MVVM (Model=lib/models, View=lib/features/*/screen.dart/widgets, ViewModel=lib/features/*/view_model.dart, Repository=lib/data)
- 폴더 구조: feature-first slim (depth 2 고정)
- 화면: Splash + Feed 2개. GoRouter는 `'/' → splash`, `'/feed' → feed`
- SVG 아이콘: Lucide (heart, message-circle, share-2)
- widget_test: 기본 카운터 앱 테스트 → VideoPost.copyWith dummy 테스트로 교체 (단, P02에서 모델 정의 후. P01에서는 우선 의존성/main만 동작하게 함)

## 진행 단계

- [x] git init + main 브랜치
- [x] .gitignore에 docs/ai-raw-transcripts/*.jsonl + demo-raw.mp4 라인 추가
- [x] 폴더 구조 생성 (lib/models, lib/data, lib/features/{splash,feed/widgets}, assets/{icons,thumbnails}, docs/{ai-conversations,ai-raw-transcripts,demo}, scripts, work_log)
- [x] work_log/README.md + P01 작성
- [x] **Flutter SDK 업그레이드** (3.32.7 → 3.41.9 / Dart 3.8.1 → 3.10+) — 명시 패키지 최신 버전들이 Dart 3.10+ 요구
- [x] pubspec.yaml 의존성 확정 + `flutter pub get`
- [x] lib/theme.dart (다크 ThemeData, TikTok 핑크 primary)
- [x] lib/router.dart (GoRouter '/' splash + '/feed')
- [x] lib/main.dart (ProviderScope + MaterialApp.router + showPerformanceOverlay 환경변수)
- [x] lib/features/splash/splash_screen.dart (1.5s Timer + context.go('/feed'))
- [x] lib/features/feed/feed_screen.dart (스켈레톤만, "Feed coming soon…")
- [x] CLAUDE.md (프로젝트 루트, MVVM/Riverpod 3.x/Video Lifecycle 룰 명시)
- [x] assets/icons/ Lucide SVG 3개 (heart, comment, share)
- [x] test/widget_test.dart 교체 (Splash 텍스트 smoke test)
- [x] flutter analyze 0 warning
- [x] flutter test 통과
- [ ] flutter run → splash → 빈 feed (P03 통합 검증 시 확인)

## 변경 파일

- (예정) pubspec.yaml, lib/main.dart, lib/router.dart, lib/theme.dart
- (신규) lib/features/splash/splash_screen.dart, lib/features/feed/feed_screen.dart
- (신규) assets/icons/{heart,comment,share}.svg
- (신규) CLAUDE.md, work_log/README.md, work_log/P01-project-bootstrap.md
- (수정) test/widget_test.dart
- (수정) .gitignore

## 검증

- [x] `flutter pub get` 무경고 (Got dependencies! ✓)
- [x] `flutter analyze` — **No issues found! (ran in 12.6s)**
- [x] `flutter test` — All tests passed!
- [ ] `flutter run` → 1.5초 splash → 빈 feed 화면 표시 (P03 통합 검증 시 확인)

## AI 협업 핵심 메모

- 패키지 버전: 사용자가 명시한 4개 + 보강 2개 (visibility_detector, flutter_cache_manager)
- 폴더 구조: AI가 3안 제시(Plan A 미니멀 / Plan B 평가자 / Plan C AI증빙) → 교차검증 후 Plan A 베이스로 통합
- 코드젠 제외 결정: 사용자 "과한 모듈화 금지" + Riverpod 3.x도 코드젠 없이 NotifierProvider first-class 지원
- **Flutter 업그레이드 결정**: 사용자 명시한 4개 패키지 최신 버전이 Dart 3.10+ 요구해서 충돌 발생 → 사용자 확인 후 `flutter upgrade`로 3.41.9 + Dart 3.10+ 환경 구축. 명시 버전 그대로 유지.

## 후속 작업

- P02에서 VideoPost 모델 + thumbnailAsset 필드 + ffmpeg 썸네일 추출
- P03에서 mini-pool + 방향성 비대칭 + unawaited 패턴

## 참조

- plan: `/Users/straram/.claude/plans/fuzzy-crunching-plum.md`
- 슈퍼센트 채용공고: https://www.wanted.co.kr/wd/358933
