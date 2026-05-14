import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

/// 영상 pause 상태일 때 가운데에 흐릿한 play 아이콘 표시.
///
/// 표시 조건: **사용자가 명시적으로 탭해서 pause한 경우**에만 (자동재생 시작 시
/// 잠깐 isPlaying=false 구간이 있어도 표시 X). [userPaused]는 부모(VideoPage)가
/// onTap에서 토글하여 갱신.
///
/// IgnorePointer로 터치 차단 — 부모 GestureDetector(단탭 toggle)에 영향 X.
class PlayPauseIndicator extends StatelessWidget {
  final VideoPlayerController controller;
  final ValueListenable<bool> userPaused;

  const PlayPauseIndicator({
    super.key,
    required this.controller,
    required this.userPaused,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: userPaused,
          builder: (_, paused, child) {
            return ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (_, v, __) {
                final showIcon = v.isInitialized && !v.isPlaying && paused;
                return AnimatedOpacity(
                  opacity: showIcon ? 0.7 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: child,
                );
              },
            );
          },
          child: SvgPicture.asset(
            'assets/icons/ic_play.svg',
            width: 96,
            height: 96,
          ),
        ),
      ),
    );
  }
}
