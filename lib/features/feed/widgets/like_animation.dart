import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 더블탭 시 화면 중앙에서 재생되는 큰 하트 splash Lottie.
/// 부모가 [animation] AnimationController를 보유하고 `forward(from: 0)`으로 trigger.
///
/// composition.duration이 ~1.2초이므로 부모 controller도 1200ms로 설정.
/// `completed` 시 controller.reset() 호출 — `lt_touch_heart`의 마지막 frame에
/// main_heart가 67% scale로 남는 문제 회피 (첫 frame은 scale=0 → invisible).
class LikeAnimation extends StatefulWidget {
  final AnimationController animation;
  const LikeAnimation({super.key, required this.animation});

  @override
  State<LikeAnimation> createState() => _LikeAnimationState();
}

class _LikeAnimationState extends State<LikeAnimation> {
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatusChanged);
  }

  @override
  void didUpdateWidget(LikeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onStatusChanged);
      widget.animation.addStatusListener(_onStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.animation.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 320,
          height: 320,
          child: Lottie.asset(
            'assets/lottie/lt_touch_heart.json',
            controller: widget.animation,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              widget.animation.duration = composition.duration;
            },
          ),
        ),
      ),
    );
  }
}
