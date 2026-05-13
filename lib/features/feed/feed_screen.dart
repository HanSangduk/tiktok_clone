import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../models/video_post.dart';
import 'feed_view_model.dart';
import 'video_page.dart';

enum SwipeDirection { down, up, none }

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with WidgetsBindingObserver {

  // 클래스 필드에 추가
  final Map<int, ValueNotifier<VideoPlayerController?>> _slots = {};

  ValueNotifier<VideoPlayerController?> _slotOf(int i) =>
      _slots.putIfAbsent(i, () => ValueNotifier<VideoPlayerController?>(null));

  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _pool = {};
  SwipeDirection _lastDirection = SwipeDirection.none;
  int? _lastIdx;
  int? _currentlyPlayingIdx;

  List<VideoPost> get _items =>
      ref.read(feedViewModelProvider).value ?? const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 첫 프레임 직후 첫 영상 init 트리거 (feedViewModel 로드 완료 후엔 listen에서 처리)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _items.isNotEmpty) _syncPool(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final c in _pool.values) {
      c.dispose();
    }
    _pool.clear();
    for (final s in _slots.values) {
      s.dispose();
    }
    _slots.clear();
    super.dispose();
  }

  // ─── Lifecycle ─────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final active = _currentlyPlayingIdx;
    if (active == null) return;
    final ctrl = _pool[active];
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      ctrl.play();
    } else {
      ctrl.pause();
    }
  }

  @override
  void didHaveMemoryPressure() {
    // 메모리 워닝: current 제외 전부 dispose
    final keep = _currentlyPlayingIdx;
    final toEvict = _pool.keys.where((k) => k != keep).toList();
    for (final k in toEvict) {
      _evict(k);
    }
  }

  // ─── Pool 관리 ─────────────────────────────────────────────

  Set<int> _computeKeep(int idx) {
    final maxIdx = _items.length - 1;
    final raw = switch (_lastDirection) {
      SwipeDirection.down => {idx - 1, idx, idx + 1, idx + 2},
      SwipeDirection.up => {idx - 2, idx - 1, idx, idx + 1},
      SwipeDirection.none => {idx, idx + 1, idx + 2},
    };
    return raw.where((i) => i >= 0 && i <= maxIdx).toSet();
  }

  void _syncPool(int newIdx) {
    if (_items.isEmpty) return;
    final sw = Stopwatch()..start();

    // 1) 방향 갱신
    if (_lastIdx != null) {
      if (newIdx > _lastIdx!) {
        _lastDirection = SwipeDirection.down;
      } else if (newIdx < _lastIdx!) {
        _lastDirection = SwipeDirection.up;
      }
    }
    _lastIdx = newIdx;

    // 2) keep 계산
    final keep = _computeKeep(newIdx);

    // 3) evict — keep 밖 즉시 dispose
    final toEvict = _pool.keys.where((k) => !keep.contains(k)).toList();
    for (final k in toEvict) {
      _evict(k);
    }

    // 4) ensure — keep 안 + 아직 없는 것
    for (final i in keep) {
      if (!_pool.containsKey(i)) _ensure(i);
    }

    // 5) Transition — sweep 대체. prev/new 2개 controller만 diff 처리.
    _applyActiveTransition(newIdx);

    // 6) infinite scroll 트리거
    final notifier = ref.read(feedViewModelProvider.notifier);
    if (newIdx >= _items.length - 3 && notifier.hasMore) {
      notifier.loadMore();
    }

    if (kDebugMode) {
      debugPrint(
        '[JANK] syncPool TOTAL=${sw.elapsedMicroseconds}μs '
        'evict=${toEvict.length} keep=${keep.length} pool=${_pool.length}',
      );
    }
  }

  /// Active idx만 즉시 play/setVolume, 이전 active의 pause/setVolume(0)은
  /// 다음 frame으로 미룸 (사용자가 인지 못 하는 부분이므로 frame budget 절약).
  ///
  /// Race 가드: PostFrame 실행 시점에 oldIdx가 다시 active가 됐다면(swipe back)
  /// pause 금지. evict로 controller가 사라졌다면 null check로 skip.
  ///
  /// 단일 진실 원천: `_currentlyPlayingIdx`. transition 진입 시 oldIdx를 capture
  /// 한 뒤 갱신. PostFrame에서는 capture된 oldIdx로 _pool 조회.
  void _applyActiveTransition(int newIdx) {
    if (_currentlyPlayingIdx == newIdx) return; // idem-potent
    final oldIdx = _currentlyPlayingIdx;
    _currentlyPlayingIdx = newIdx;

    // ① 새 active는 즉시 (사용자가 곧바로 봐야 하므로)
    final next = _pool[newIdx];
    if (next != null && next.value.isInitialized) {
      next.setVolume(1.0);
      next.play();
    }

    if (oldIdx == null) return;

    // ② 이전 active 끄기는 다음 frame (사용자 인지 X, frame budget 절약)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // swipe back으로 oldIdx가 다시 active가 됐으면 pause 금지
      if (oldIdx == _currentlyPlayingIdx) return;
      final prev = _pool[oldIdx];
      if (prev != null && prev.value.isInitialized) {
        prev.setVolume(0);
        prev.pause();
      }
    });
  }

  void _evict(int i) {
    // 1) VideoPage가 먼저 controller를 놓아주도록 slot 비우기
    _slots[i]?.value = null;
    // 2) 그 다음 controller dispose
    final c = _pool.remove(i);
    if (c != null) {
      // final sw = Stopwatch()..start();
      // Future.microtask(() => c.dispose());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        c.pause();
        c.dispose();   // 현재 frame 렌더링 완료 후 실행
      });

      // if (kDebugMode) {
      //   debugPrint('[JANK] evict idx=$i dispose=${sw.elapsedMicroseconds}μs');
      // }
    }
  }

  void _ensure(int i) async {
    if (i < 0 || i >= _items.length || _pool.containsKey(i)) return;
    final url = _items[i].videoUrl;
    final resolver = ref.read(videoCacheResolverProvider);

    final swPeek = Stopwatch()..start();
    final cached = await resolver.peek(url);
    if (kDebugMode) {
      debugPrint(
        '[JANK] ensure peek idx=$i=${swPeek.elapsedMicroseconds}μs hit=${cached != null}',
      );
    }

    if (!mounted) return;
    if (_pool.containsKey(i)) return;

    final c = cached != null
        ? VideoPlayerController.file(cached)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    c.setLooping(true);
    _pool[i] = c;
    _slotOf(i).value = c; // ← 추가: 슬롯에 즉시 노출 (init 전이어도 VideoPage가 받음)

    final swInit = Stopwatch()..start();
    unawaited(
      c.initialize().then((_) {
        if (kDebugMode) {
          debugPrint(
            '[JANK] ensure init idx=$i=${swInit.elapsedMicroseconds}μs',
          );
        }
        if (!mounted) {
          c.dispose();
          return;
        }
        if (_pool[i] != c) {
          c.dispose();
          return;
        }

        c.setVolume(i == _currentlyPlayingIdx ? 1.0 : 0.0);
        if (i == _currentlyPlayingIdx) c.play();
        // setState 제거 — VideoPage의 inner ValueListenableBuilder<VideoPlayerValue>가
        // c.value.isInitialized 변경을 감지하여 자체 rebuild함.
        // FeedScreen rebuild 불필요.
      }).catchError((Object _, StackTrace __) {
        if (_pool[i] == c) {
          _pool.remove(i);
          _slots[i]?.value = null; // 실패 시 slot도 비우기
        }
        c.dispose();
      }),
    );

    if (cached == null) {
      unawaited(resolver.prefetch(url));
    }
  }

  // ─── PageView 콜백 ───────────────────────────────────────────

  /// `ScrollEndNotification` 시점에 호출됨 — PageView가 완전히 settle된 후 1번만.
  /// 같은 idx로 settle된 경우(swipe cancel) idem-potent guard로 noop.
  void _onPageSettled(int newIdx) {
    if (newIdx == _currentlyPlayingIdx) return;
    final sw = Stopwatch()..start();
    ref.read(currentIndexViewModelProvider.notifier).set(newIdx);
    _syncPool(newIdx);
    if (kDebugMode) {
      debugPrint(
        '[JANK] onPageSettled idx=$newIdx total=${sw.elapsedMicroseconds}μs',
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _buildCount++;
      debugPrint('[JANK] FeedScreen build #$_buildCount');
    }

    // feedViewModel 로드 완료 시점에 첫 syncPool 호출 보장
    ref.listen<AsyncValue<List<VideoPost>>>(feedViewModelProvider, (prev, next) {
      final prevLen = prev?.value?.length ?? 0;
      final nextLen = next.value?.length ?? 0;
      // 0 → N 전환된 경우에만 첫 영상 동기화
      if (prevLen == 0 && nextLen > 0 && _lastIdx == null) {
        _syncPool(0);
      }
    });

    final feed = ref.watch(feedViewModelProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Failed to load feed: $err',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No videos', style: TextStyle(color: Colors.white70)),
            );
          }
          // PageView의 onPageChanged는 viewport 중심 통과(fraction 0.5) 시 fire되어
          // 빠른 fling 시 중간 페이지마다 호출됨 → 메모리 peak + 불필요한 sync.
          // ScrollEndNotification으로 settle 완료 시점에만 1번 trigger.
          return NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              if (notification.depth != 0) return false; // 중첩 스크롤 무시
              final page = _pageController.page;
              if (page == null) return false;
              final newIdx = page.round();
              if (newIdx >= 0 && newIdx < items.length) {
                _onPageSettled(newIdx);
              }
              return false; // propagation 유지
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              allowImplicitScrolling: false,
              itemCount: items.length,
              itemBuilder: (_, i) => VideoPage(
                key: ValueKey(items[i].id),
                index: i,
                post: items[i],
                slot: _slotOf(i), // ← controller → slot
              ),
            ),
          );
        },
      ),
    );
  }
}