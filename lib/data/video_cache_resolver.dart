import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 비디오 디스크 캐시 래퍼.
///
/// 전략:
/// - 첫 시청: progressive playback (네트워크 URL 직접 재생) + 백그라운드 다운로드
/// - 2바퀴+: `peek` hit으로 `file://` 재생
///
/// 성능 메모: `getFileFromCache`는 내부적으로 sqflite query이며 메인 isolate에서
/// 동기 실행되어 ~5~8ms 점유. 본 클래스에 메모리 캐시(`_memCache`)를 두어
/// 같은 URL 두 번째 호출부터 0ms 응답.
class VideoCacheResolver {
  static final CacheManager _manager = CacheManager(
    Config(
      'tiktokCloneVideoCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50,
    ),
  );

  /// URL → 파일 존재 여부 메모리 캐시. null = miss, File = hit.
  /// `prefetch` 시 무효화되어 다음 `peek`이 새로 query.
  final Map<String, File?> _memCache = {};

  /// 캐시 hit이면 file 반환, miss면 null. 네트워크 fetch는 하지 않는다.
  Future<File?> peek(String url) async {
    if (_memCache.containsKey(url)) return _memCache[url];
    final info = await _manager.getFileFromCache(url);
    final file = info?.file;
    _memCache[url] = file;
    return file;
  }

  /// 백그라운드 다운로드 (fire-and-forget). 실패는 무시.
  /// 완료 후 메모리 캐시 무효화 → 다음 peek가 새 파일을 발견.
  Future<void> prefetch(String url) async {
    try {
      await _manager.downloadFile(url);
      _memCache.remove(url);
    } catch (_) {
      // 네트워크 실패 등은 무시. 다음 시청 시 재시도.
    }
  }
}
