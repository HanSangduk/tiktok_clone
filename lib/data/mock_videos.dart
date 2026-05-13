import '../models/video_post.dart';

/// HTTPS + content-type=video/mp4로 안정성 검증된 무료 sample MP4 10개.
/// (Google commondatastorage는 2026년 들어 403으로 막혔으므로 교체.)
const _videos = <_RawVideo>[
  _RawVideo(
    name: 'Butterfly',
    url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    caption: '🦋 잡으려다 놓쳤다',
  ),
  _RawVideo(
    name: 'Bee',
    url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    caption: '꿀벌이 진짜 예쁘다 🐝',
  ),
  _RawVideo(
    name: 'BigBuckBunny',
    url: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4',
    caption: '오늘 본 만화 중 최고 🎬',
  ),
  _RawVideo(
    name: 'Jellyfish',
    url: 'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_2MB.mp4',
    caption: '해파리 보는데 힐링됨 🪼',
  ),
  _RawVideo(
    name: 'Sintel',
    url: 'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_2MB.mp4',
    caption: '판타지 영화 추천 ⚔️',
  ),
  _RawVideo(
    name: 'Sample5s',
    url: 'https://download.samplelib.com/mp4/sample-5s.mp4',
    caption: '짧고 굵게 5초',
  ),
  _RawVideo(
    name: 'Sample10s',
    url: 'https://download.samplelib.com/mp4/sample-10s.mp4',
    caption: '도시의 밤 풍경 🌃',
  ),
  _RawVideo(
    name: 'Sample15s',
    url: 'https://download.samplelib.com/mp4/sample-15s.mp4',
    caption: '바다 보러 가실 분 🌊',
  ),
  _RawVideo(
    name: 'Sample20s',
    url: 'https://download.samplelib.com/mp4/sample-20s.mp4',
    caption: '여행 가고 싶다 ✈️',
  ),
  _RawVideo(
    name: 'Sample30s',
    url: 'https://download.samplelib.com/mp4/sample-30s.mp4',
    caption: '오늘 하루 마무리',
  ),
];

const _usernames = [
  '@stra_ram',
  '@flutter_dev',
  '@supercent',
  '@vibes_only',
  '@dreamer',
  '@on_the_road',
  '@cinephile',
  '@weekend.vlog',
  '@tech_diary',
  '@coffee_addict',
];

/// 100개 mock VideoPost — 10개 영상을 id만 다르게 반복.
final List<VideoPost> kMockVideos = List<VideoPost>.unmodifiable(
  List.generate(100, (i) {
    final v = _videos[i % _videos.length];
    return VideoPost(
      id: 'v_$i',
      videoUrl: v.url,
      thumbnailAsset: 'assets/thumbnails/${v.name}.jpg',
      username: _usernames[i % _usernames.length],
      caption: "[$i]-${v.caption}",
      likes: 1200 + i * 37 % 5000,
      comments: 30 + i * 11 % 400,
      shares: 5 + i * 7 % 200,
    );
  }),
);

class _RawVideo {
  final String name;
  final String url;
  final String caption;
  const _RawVideo({required this.name, required this.url, required this.caption});
}
