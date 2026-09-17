import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../features/pose_library/models/pose_reference.dart';
import 'pose_sketch_service.dart';

/// Manages in-memory and persistent disk caching for sketch overlay images.
class PoseSketchCache {
  PoseSketchCache._();
  static final PoseSketchCache instance = PoseSketchCache._();

  /// Memory cache mapping pose ID to processed PNG bytes.
  final Map<String, Uint8List> _memoryCache = {};

  /// In-flight requests map to avoid duplicate work.
  final Map<String, Future<Uint8List?>> _inFlight = {};

  Directory? _cacheDir;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/sketch_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  File _cacheFileFor(Directory dir, String poseId) {
    // Sanitize file name for filesystem safety
    final safeName = poseId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${dir.path}/$safeName.png');
  }

  /// Retrieves the sketch PNG bytes for [pose].
  ///
  /// Checks memory first, then disk, then generates via [PoseSketchService].
  Future<Uint8List?> getSketch(PoseReference pose) {
    // 1. Fast path: in-memory cache
    final inMemory = _memoryCache[pose.id];
    if (inMemory != null) {
      return Future.value(inMemory);
    }

    // 2. Reuse in-flight future if already processing
    final inFlightFuture = _inFlight[pose.id];
    if (inFlightFuture != null) {
      return inFlightFuture;
    }

    final future = _loadOrGenerate(pose);
    _inFlight[pose.id] = future;
    return future;
  }

  Future<Uint8List?> _loadOrGenerate(PoseReference pose) async {
    try {
      final dir = await _getCacheDirectory();
      final file = _cacheFileFor(dir, pose.id);

      // Check persistent disk cache
      if (await file.exists()) {
        final diskBytes = await file.readAsBytes();
        if (diskBytes.isNotEmpty) {
          _memoryCache[pose.id] = diskBytes;
          return diskBytes;
        }
      }

      // Read source image bytes
      final sourceBytes = await _loadSourceBytes(pose);
      if (sourceBytes == null || sourceBytes.isEmpty) {
        return null;
      }

      // Generate sketch in background isolate
      final sketchBytes = await PoseSketchService.generateSketch(sourceBytes);
      if (sketchBytes != null && sketchBytes.isNotEmpty) {
        _memoryCache[pose.id] = sketchBytes;
        try {
          await file.writeAsBytes(sketchBytes, flush: true);
        } catch (e) {
          debugPrint('PoseSketchCache: failed to write disk cache: $e');
        }
        return sketchBytes;
      }

      return null;
    } catch (e) {
      debugPrint('PoseSketchCache: error generating sketch for ${pose.id}: $e');
      return null;
    } finally {
      _inFlight.remove(pose.id);
    }
  }

  Future<Uint8List?> _loadSourceBytes(PoseReference pose) async {
    try {
      if (pose.isLocalImage && pose.localFilePath != null) {
        final f = File(pose.localFilePath!);
        if (await f.exists()) {
          return await f.readAsBytes();
        }
      } else if (pose.isNetworkImage && pose.networkOverlayUrl != null) {
        return await _downloadBytes(pose.networkOverlayUrl!);
      } else if (pose.assetPath.isNotEmpty) {
        final byteData = await rootBundle.load(pose.assetPath);
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('PoseSketchCache: failed to load source bytes: $e');
    }
    return null;
  }

  Future<Uint8List?> _downloadBytes(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final chunks = <List<int>>[];
      await for (final chunk in response) {
        chunks.add(chunk);
      }
      return Uint8List.fromList(chunks.expand((c) => c).toList());
    } catch (e) {
      debugPrint('PoseSketchCache: download failed for $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Sequential background prefetch for a list of poses.
  Future<void> prefetchAll(List<PoseReference> poses) async {
    for (final pose in poses) {
      if (_memoryCache.containsKey(pose.id)) continue;
      try {
        final dir = await _getCacheDirectory();
        final file = _cacheFileFor(dir, pose.id);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _memoryCache[pose.id] = bytes;
          continue;
        }
        await getSketch(pose);
      } catch (e) {
        debugPrint('PoseSketchCache prefetch error for ${pose.id}: $e');
      }
    }
  }
}
