import '../models/video_post.dart';
import 'mock_videos.dart';

class VideoRepository {
  /// 페이지네이션 시뮬레이션. 끝에 도달하면 빈 리스트 반환.
  Future<List<VideoPost>> fetchPage(int page, {int size = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final start = page * size;
    if (start >= kMockVideos.length) return const [];
    final end = (start + size).clamp(0, kMockVideos.length);
    return kMockVideos.sublist(start, end);
  }
}
