// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
//
// import '../../models/video_post.dart';
// import 'feed_view_model.dart';
// import 'widgets/feed_overlay.dart';
// import 'widgets/like_animation.dart';
//
// /// 영상 1개 페이지.
// /// - 부모(FeedScreen)에서 [controller]를 prop으로 받음 (자체 init/dispose X).
// /// - 단탭: play/pause toggle. 더블탭: 좋아요 + 하트 애니메이션.
// /// - Stack 4 layer: 썸네일 / 영상 / 오버레이 / 더블탭 하트.
// class VideoPage extends ConsumerStatefulWidget {
//   final int index;
//   final VideoPost post;
//   final VideoPlayerController? controller;
//
//   const VideoPage({
//     super.key,
//     required this.index,
//     required this.post,
//     required this.controller,
//   });
//
//   @override
//   ConsumerState<VideoPage> createState() => _VideoPageState();
// }
//
// class _VideoPageState extends ConsumerState<VideoPage>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _likeAnim = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 700),
//   );
//
//   @override
//   void dispose() {
//     _likeAnim.dispose();
//     super.dispose();
//   }
//
//   void _onTap() {
//     final c = widget.controller;
//     if (c == null || !c.value.isInitialized) return;
//     if (c.value.isPlaying) {
//       c.pause();
//     } else {
//       c.play();
//     }
//   }
//
//   void _onDoubleTap() {
//     ref.read(likedSetViewModelProvider.notifier).toggle(widget.post.id);
//     _likeAnim.forward(from: 0);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final dpr = MediaQuery.devicePixelRatioOf(context);
//     final w = MediaQuery.sizeOf(context).width;
//     final c = widget.controller;
//
//     return GestureDetector(
//       onTap: _onTap,
//       onDoubleTap: _onDoubleTap,
//       behavior: HitTestBehavior.opaque,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // 1) 항상 깔리는 썸네일 (cacheWidth로 디코드 메모리 제한)
//           RepaintBoundary(
//             child: Image.asset(
//               widget.post.thumbnailAsset,
//               fit: BoxFit.cover,
//               cacheWidth: (w * dpr).round(),
//               errorBuilder: (_, __, ___) =>
//                   const ColoredBox(color: Colors.black),
//             ),
//           ),
//           // 2) controller init 완료 시 그 위에 영상 layer
//           if (c != null)
//             RepaintBoundary(
//               child: ValueListenableBuilder<VideoPlayerValue>(
//                 valueListenable: c,
//                 builder: (_, v, __) {
//                   if (!v.isInitialized) return const SizedBox.shrink();
//                   return FittedBox(
//                     fit: BoxFit.cover,
//                     child: SizedBox(
//                       width: v.size.width,
//                       height: v.size.height,
//                       child: VideoPlayer(c),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           // 3) Overlay UI (LikedSetViewModel 직접 watch — 영상 layer rebuild X)
//           RepaintBoundary(child: FeedOverlay(post: widget.post)),
//           // 4) 더블탭 하트 애니메이션
//           RepaintBoundary(child: LikeAnimation(animation: _likeAnim)),
//         ],
//       ),
//     );
//   }
// }
