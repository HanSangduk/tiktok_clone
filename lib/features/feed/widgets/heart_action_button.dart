import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../feed_view_model.dart';
import 'action_button.dart';

/// 좋아요 버튼 + isLiked false→true 전환 시 위로 올라가는 4개 하트 Lottie.
///
/// 이전 isLiked 값(`_wasLiked`)을 추적하여 OFF→ON 전환에만 Lottie 재생.
/// ON→OFF는 trigger 안 함 (TikTok과 동일 동작).
class HeartActionButton extends ConsumerStatefulWidget {
  final String videoId;
  final int likesBase;

  const HeartActionButton({
    super.key,
    required this.videoId,
    required this.likesBase,
  });

  @override
  ConsumerState<HeartActionButton> createState() => _HeartActionButtonState();
}

class _HeartActionButtonState extends ConsumerState<HeartActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _moveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000), // lt_move_heart composition duration
  );
  bool _wasLiked = false;

  @override
  void dispose() {
    _moveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(
      likedSetViewModelProvider.select((s) => s.contains(widget.videoId)),
    );

    if (isLiked && !_wasLiked) {
      _moveCtrl.forward(from: 0);
    }
    _wasLiked = isLiked;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ActionButton(
          assetPath:
              'assets/icons/${isLiked ? "ic_like_filled" : "ic_like"}.svg',
          label: _formatCount(widget.likesBase + (isLiked ? 1 : 0)),
          onTap: () => ref
              .read(likedSetViewModelProvider.notifier)
              .toggle(widget.videoId),
        ),
        Positioned(
          bottom: 0,
          child: IgnorePointer(
            child: SizedBox(
              width: 120,
              height: 160,
              child: Lottie.asset(
                'assets/lottie/lt_move_heart.json',
                controller: _moveCtrl,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  _moveCtrl.duration = composition.duration;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
