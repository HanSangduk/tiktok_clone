import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/video_post.dart';
import 'action_button.dart';
import 'heart_action_button.dart';

/// 영상 위 오버레이 (우측 액션 바 + 하단 username/caption).
/// 좋아요 처리는 [HeartActionButton]에 위임 (Lottie 애니메이션 포함).
class FeedOverlay extends ConsumerWidget {
  final VideoPost post;

  const FeedOverlay({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void noop() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coming soon'),
          duration: Duration(milliseconds: 600),
        ),
      );
    }

    return Stack(
      children: [
        // 우측 액션 바
        Positioned(
          right: 12,
          bottom: 32,
          child: SafeArea(
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Avatar(username: post.username),
                  const SizedBox(height: 18),
                  HeartActionButton(
                    videoId: post.id,
                    likesBase: post.likes,
                  ),
                  const SizedBox(height: 18),
                  ActionButton(
                    assetPath: 'assets/icons/ic_comment.svg',
                    label: _formatCount(post.comments),
                    onTap: noop,
                  ),
                  const SizedBox(height: 18),
                  ActionButton(
                    assetPath: 'assets/icons/ic_share.svg',
                    label: _formatCount(post.shares),
                    onTap: noop,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 하단 username + caption (gradient 그림자로 가독성 확보)
        Positioned(
          left: 16,
          right: 80,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: RepaintBoundary(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String username;
  const _Avatar({required this.username});

  @override
  Widget build(BuildContext context) {
    final initial = username.replaceAll('@', '').characters.firstOrNull ?? '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFE2C55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
