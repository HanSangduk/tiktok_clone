import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 우측 액션 바 1버튼 (SVG + 카운트). 재사용.
class ActionButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const ActionButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetPath,
            width: 34,
            height: 34,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}
