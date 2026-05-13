// import 'dart:async';
//
// import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
//
// import '../../models/video_post.dart';
// import 'feed_view_model.dart';
// import 'video_page.dart';
//
// enum SwipeDirection { down, up, none }
//
// class FeedScreen extends ConsumerStatefulWidget {
//   const FeedScreen({super.key});
//
//   @override
//   ConsumerState<FeedScreen> createState() => _FeedScreenState();
// }
//
// class _FeedScreenState extends ConsumerState<FeedScreen>
//     with WidgetsBindingObserver {
//   final PageController _pageController = PageController();
//   final Map<int, VideoPlayerController> _pool = {};
//   SwipeDirection _lastDirection = SwipeDirection.none;
//   int? _lastIdx;
//   int? _currentlyPlayingIdx;
//
//   List<VideoPost> get _items =>
//       ref.read(feedViewModelProvider).value ?? const [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     // 첫 프레임 직후 첫 영상 init 트리거 (feedViewModel 로드 완료 후엔 listen에서 처리)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted && _items.isNotEmpty) _syncPool(0);
//     });
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pageController.dispose();
//     for (final c in _pool.values) {
//       c.dispose();
//     }
//     _pool.clear();
//     super.dispose();
//   }
//
//   // ─── Lifecycle ─────────────────────────────────────────────
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!mounted) return;
//     final active = _currentlyPlayingIdx;
//     if (active == null) return;
//     final ctrl = _pool[active];
//     if (ctrl == null || !ctrl.value.isInitialized) return;
//     if (state == AppLifecycleState.resumed) {
//       ctrl.play();
//     } else {
//       ctrl.pause();
//     }
//   }
//
//   @override
//   void didHaveMemoryPressure() {
//     // 메모리 워닝: current 제외 전부 dispose
//     final keep = _currentlyPlayingIdx;
//     final toEvict = _pool.keys.where((k) => k != keep).toList();
//     for (final k in toEvict) {
//       _evict(k);
//     }
//   }
//
//   // ─── Pool 관리 ─────────────────────────────────────────────
//
//   Set<int> _computeKeep(int idx) {
//     final maxIdx = _items.length - 1;
//     final raw = switch (_lastDirection) {
//       SwipeDirection.down => {idx - 1, idx, idx + 1, idx + 2},
//       SwipeDirection.up => {idx - 2, idx - 1, idx, idx + 1},
//       SwipeDirection.none => {idx, idx + 1, idx + 2},
//     };
//     return raw.where((i) => i >= 0 && i <= maxIdx).toSet();
//   }
//
//   void _syncPool(int newIdx) {
//     if (_items.isEmpty) return;
//     final sw = Stopwatch()..start();
//
//     // 1) 방향 갱신
//     if (_lastIdx != null) {
//       if (newIdx > _lastIdx!) {
//         _lastDirection = SwipeDirection.down;
//       } else if (newIdx < _lastIdx!) {
//         _lastDirection = SwipeDirection.up;
//       }
//     }
//     _lastIdx = newIdx;
//     _currentlyPlayingIdx = newIdx;
//
//     // 2) keep 계산
//     final keep = _computeKeep(newIdx);
//
//     // 3) evict — keep 밖 즉시 dispose
//     final toEvict = _pool.keys.where((k) => !keep.contains(k)).toList();
//     for (final k in toEvict) {
//       _evict(k);
//     }
//
//     // 4) ensure — keep 안 + 아직 없는 것
//     for (final i in keep) {
//       if (!_pool.containsKey(i)) _ensure(i);
//     }
//
//     // 5) sweep — pool 전체에 setVolume/play/pause 명시
//     _pool.forEach((k, c) {
//       if (!c.value.isInitialized) return; // init 중 슬롯은 콜백에서 처리
//       if (k == newIdx) {
//         c.setVolume(1.0);
//         c.play();
//       } else {
//         c.setVolume(0);
//         c.pause();
//       }
//     });
//
//     // 6) infinite scroll 트리거 — 끝 2개 안쪽이면 loadMore
//     final notifier = ref.read(feedViewModelProvider.notifier);
//     if (newIdx >= _items.length - 3 && notifier.hasMore) {
//       notifier.loadMore();
//     }
//
//     if (kDebugMode) {
//       debugPrint(
//         '[JANK] syncPool TOTAL=${sw.elapsedMicroseconds}μs '
//         'evict=${toEvict.length} keep=${keep.length} pool=${_pool.length}',
//       );
//     }
//   }
//
//   void _evict(int i) {
//     final c = _pool.remove(i);
//     if (c != null) {
//       c.pause();
//       final sw = Stopwatch()..start();
//       c.dispose();
//       if (kDebugMode) {
//         debugPrint('[JANK] evict idx=$i dispose=${sw.elapsedMicroseconds}μs');
//       }
//     }
//   }
//
//   void _ensure(int i) async {
//     if(true){
//       return;
//     }
//     if (i < 0 || i >= _items.length || _pool.containsKey(i)) return;
//     final url = _items[i].videoUrl;
//     final resolver = ref.read(videoCacheResolverProvider);
//
//     final swPeek = Stopwatch()..start();
//     final cached = await resolver.peek(url);
//     if (kDebugMode) {
//       debugPrint(
//         '[JANK] ensure peek idx=$i=${swPeek.elapsedMicroseconds}μs hit=${cached != null}',
//       );
//     }
//
//     if (!mounted) return;
//     if (_pool.containsKey(i)) return; // 그 사이 다른 호출이 채웠을 수도
//
//     final c = cached != null
//         ? VideoPlayerController.file(cached)
//         : VideoPlayerController.networkUrl(Uri.parse(url));
//     c.setLooping(true);
//     _pool[i] = c; // slot 즉시 점유 (중복 ensure 방지)
//
//     final swInit = Stopwatch()..start();
//     unawaited(
//       c.initialize().then((_) {
//         if (kDebugMode) {
//           debugPrint(
//             '[JANK] ensure init idx=$i=${swInit.elapsedMicroseconds}μs',
//           );
//         }
//         if (!mounted) {
//           c.dispose();
//           return;
//         }
//         if (_pool[i] != c) {
//           c.dispose(); // race: 그 사이 evict됨
//           return;
//         }
//
//         c.setVolume(i == _currentlyPlayingIdx ? 1.0 : 0.0);
//         if (i == _currentlyPlayingIdx) c.play();
//         // 현재 visible 페이지(active)일 때만 setState → 불필요한 FeedScreen rebuild 차단.
//         // preload된 idx±1/+2의 init 완료는 PageView가 해당 페이지를 build할 때
//         // itemBuilder가 다시 호출되며 자연스럽게 controller prop 전달.
//         if (i == _currentlyPlayingIdx) {
//           final swSet = Stopwatch()..start();
//           setState(() {}); // texture paint 트리거
//           if (kDebugMode) {
//             debugPrint(
//               '[JANK] setState idx=$i=${swSet.elapsedMicroseconds}μs',
//             );
//           }
//         }
//       }).catchError((Object _, StackTrace __) {
//         if (_pool[i] == c) _pool.remove(i);
//         c.dispose();
//       }),
//     );
//
//     // 캐시 miss면 백그라운드 prefetch (다음 호출부터 file:// hit)
//     if (cached == null) {
//       unawaited(resolver.prefetch(url));
//     }
//   }
//
//   // ─── PageView 콜백 ───────────────────────────────────────────
//
//   /// `ScrollEndNotification` 시점에 호출됨 — PageView가 완전히 settle된 후 1번만.
//   /// 같은 idx로 settle된 경우(swipe cancel) idem-potent guard로 noop.
//   void _onPageSettled(int newIdx) {
//     if (newIdx == _currentlyPlayingIdx) return;
//     final sw = Stopwatch()..start();
//     ref.read(currentIndexViewModelProvider.notifier).set(newIdx);
//     _syncPool(newIdx);
//     if (kDebugMode) {
//       debugPrint(
//         '[JANK] onPageSettled idx=$newIdx total=${sw.elapsedMicroseconds}μs',
//       );
//     }
//   }
//
//   // ─── Build ─────────────────────────────────────────────────
//
//   int _buildCount = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     if (kDebugMode) {
//       _buildCount++;
//       debugPrint('[JANK] FeedScreen build #$_buildCount');
//     }
//
//     // feedViewModel 로드 완료 시점에 첫 syncPool 호출 보장
//     ref.listen<AsyncValue<List<VideoPost>>>(feedViewModelProvider, (prev, next) {
//       final prevLen = prev?.value?.length ?? 0;
//       final nextLen = next.value?.length ?? 0;
//       // 0 → N 전환된 경우에만 첫 영상 동기화
//       if (prevLen == 0 && nextLen > 0 && _lastIdx == null) {
//         _syncPool(0);
//       }
//     });
//
//     final feed = ref.watch(feedViewModelProvider);
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: feed.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, _) => Center(
//           child: Text(
//             'Failed to load feed: $err',
//             style: const TextStyle(color: Colors.white70),
//           ),
//         ),
//         data: (items) {
//           if (items.isEmpty) {
//             return const Center(
//               child: Text('No videos', style: TextStyle(color: Colors.white70)),
//             );
//           }
//           // PageView의 onPageChanged는 viewport 중심 통과(fraction 0.5) 시 fire되어
//           // 빠른 fling 시 중간 페이지마다 호출됨 → 메모리 peak + 불필요한 sync.
//           // ScrollEndNotification으로 settle 완료 시점에만 1번 trigger.
//           return NotificationListener<ScrollEndNotification>(
//             onNotification: (notification) {
//               if (notification.depth != 0) return false; // 중첩 스크롤 무시
//               final page = _pageController.page;
//               if (page == null) return false;
//               final newIdx = page.round();
//               if (newIdx >= 0 && newIdx < items.length) {
//                 _onPageSettled(newIdx);
//               }
//               return false; // propagation 유지
//             },
//             child: PageView.builder(
//               controller: _pageController,
//               scrollDirection: Axis.vertical,
//               allowImplicitScrolling: false,
//               itemCount: items.length,
//               itemBuilder: (_, i) => VideoPage(
//                 key: ValueKey(items[i].id),
//                 index: i,
//                 post: items[i],
//                 controller: _pool[i],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }