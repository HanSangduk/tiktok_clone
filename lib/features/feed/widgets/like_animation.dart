import 'package:flutter/material.dart';

/// 더블탭 시 화면 중앙에 잠시 떠올랐다 사라지는 큰 하트.
/// 부모가 [controller]를 보유하고 `forward(from: 0)`으로 trigger.
class LikeAnimation extends StatelessWidget {
  final Animation<double> animation;
  const LikeAnimation({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            // 0.0~0.3: scale 0.4→1.2, opacity 0→1
            // 0.3~1.0: scale 1.2→1.4, opacity 1→0
            final t = animation.value;
            final double scale;
            final double opacity;
            if (t < 0.3) {
              final p = t / 0.3;
              scale = 0.4 + 0.8 * p;
              opacity = p;
            } else {
              final p = (t - 0.3) / 0.7;
              scale = 1.2 + 0.2 * p;
              opacity = 1 - p;
            }
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: const Icon(
                  Icons.favorite,
                  size: 140,
                  color: Color(0xFFFE2C55),
                  shadows: [Shadow(blurRadius: 16, color: Colors.black54)],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
