---
id: P09
title: profile mode 영상 녹화 + ffmpeg 압축 + raw transcript 압축 + GitHub repo
status: 진행 중
domain: docs
created: 2026-05-12
completed:
---

## 목표

평가자에게 전달할 1테이크 시연 영상 + AI raw transcript 압축본 + GitHub public repo 생성.

## 결정 사항

- 영상 녹화 모드: **profile** (debug는 5~10배 느림 → jank 측정 무의미)
- 녹화 명령: `xcrun simctl io booted recordVideo --codec=h264 docs/demo/demo-raw.mp4` → 사용자가 1테이크 시연 후 Ctrl+C
- 압축: `ffmpeg -i demo-raw.mp4 -vcodec libx264 -crf 26 -preset slow demo.mp4`
- raw transcript: `~/.claude/projects/-Users-straram-development-tiktok-clone/*.jsonl` → `docs/ai-raw-transcripts/claude-code-session-2026-05-12.jsonl.gz`
- GitHub: gh CLI로 public `tiktok-clone` repo 생성 + push

## 진행 단계

- [x] work_log/P09 작성
- [ ] flutter run (debug) 종료 → `flutter run --profile` 재실행
- [ ] **사용자**: 시뮬레이터에서 splash → feed 동작 확인
- [ ] **사용자**: `xcrun simctl io booted recordVideo --codec=h264 docs/demo/demo-raw.mp4` 실행 → 1분 30초 시연 → Ctrl+C
- [ ] ffmpeg 압축
- [ ] raw transcript 압축
- [ ] gh CLI로 GitHub repo 생성
- [ ] git add + commit + push
- [ ] README 영상 임베드 URL 업데이트

## 변경 파일

- (신규) docs/demo/demo.mp4 (압축본, 30~60MB)
- (신규) docs/ai-raw-transcripts/claude-code-session-2026-05-12.jsonl.gz
- (수정) README.md (영상 임베드 URL)

## 검증

- [ ] 영상이 1분 30초 내, 60fps 유지
- [ ] 빠른 스크롤 시 검은 화면 0
- [ ] 오디오 중복 0
- [ ] GitHub repo public 접근 가능
- [ ] fresh clone → flutter pub get + run 성공

## 참조

- plan: §11 영상 콘티, §12 GitHub repo 운영
