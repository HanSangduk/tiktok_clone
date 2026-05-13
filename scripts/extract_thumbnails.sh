#!/usr/bin/env bash
# 영상 첫 프레임을 JPEG 썸네일로 추출.
# samplelib 같은 일부 호스트는 ffmpeg streaming과 호환이 약해서
# curl로 먼저 다운로드 → ffmpeg 로컬 추출 방식.
#
# 사용: bash scripts/extract_thumbnails.sh
# 결과: assets/thumbnails/*.jpg (10장)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$PROJECT_ROOT/assets/thumbnails"
TMP_DIR="$(mktemp -d)"
mkdir -p "$OUT_DIR"

trap 'rm -rf "$TMP_DIR"' EXIT

# name|url 쌍. lib/data/mock_videos.dart 의 _videos와 일치해야 함.
ENTRIES=(
  "Butterfly|https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
  "Bee|https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"
  "BigBuckBunny|https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4"
  "Jellyfish|https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_2MB.mp4"
  "Sintel|https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_2MB.mp4"
  "Sample5s|https://download.samplelib.com/mp4/sample-5s.mp4"
  "Sample10s|https://download.samplelib.com/mp4/sample-10s.mp4"
  "Sample15s|https://download.samplelib.com/mp4/sample-15s.mp4"
  "Sample20s|https://download.samplelib.com/mp4/sample-20s.mp4"
  "Sample30s|https://download.samplelib.com/mp4/sample-30s.mp4"
)

for entry in "${ENTRIES[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  out="$OUT_DIR/$name.jpg"
  tmp="$TMP_DIR/$name.mp4"

  echo "▶ $name (download)"
  curl -fsSL -o "$tmp" "$url"

  echo "  $name (extract first frame)"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$tmp" \
    -vframes 1 -q:v 4 -vf "scale='min(720,iw)':-2" \
    "$out"
done

echo ""
echo "✓ Done. Thumbnails:"
ls -lh "$OUT_DIR"
