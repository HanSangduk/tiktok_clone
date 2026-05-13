import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/video_cache_resolver.dart';
import '../../data/video_repository.dart';
import '../../models/video_post.dart';

// ─── Provider 모음 ────────────────────────────────────────────

final videoRepositoryProvider =
    Provider<VideoRepository>((ref) => VideoRepository());

final videoCacheResolverProvider =
    Provider<VideoCacheResolver>((ref) => VideoCacheResolver());

// ─── FeedViewModel: 영상 리스트 + 페이지네이션 ──────────────

class FeedViewModel extends AsyncNotifier<List<VideoPost>> {
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<VideoPost>> build() async {
    final repo = ref.read(videoRepositoryProvider);
    final first = await repo.fetchPage(_page, size: _pageSize);
    _page = 1;
    _hasMore = first.length == _pageSize;
    return first;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final repo = ref.read(videoRepositoryProvider);
      final next = await repo.fetchPage(_page, size: _pageSize);
      _page += 1;
      if (next.length < _pageSize) _hasMore = false;
      final current = state.value ?? const <VideoPost>[];
      state = AsyncData([...current, ...next]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => _hasMore;
}

final feedViewModelProvider =
    AsyncNotifierProvider<FeedViewModel, List<VideoPost>>(FeedViewModel.new);

// ─── CurrentIndexViewModel: 현재 재생 인덱스 ──────────────────

class CurrentIndexViewModel extends Notifier<int> {
  @override
  int build() => 0;

  void set(int idx) {
    if (state != idx) state = idx;
  }
}

final currentIndexViewModelProvider =
    NotifierProvider<CurrentIndexViewModel, int>(CurrentIndexViewModel.new);

// ─── LikedSetViewModel: 좋아요 누른 videoId 집합 ─────────────

class LikedSetViewModel extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool isLiked(String videoId) => state.contains(videoId);

  void toggle(String videoId) {
    state = state.contains(videoId)
        ? ({...state}..remove(videoId))
        : {...state, videoId};
  }
}

final likedSetViewModelProvider =
    NotifierProvider<LikedSetViewModel, Set<String>>(LikedSetViewModel.new);
