import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';

typedef _ShowBytesCallback =
    Future<void> Function({
      required Uint8List bytes,
      required String contentType,
      required String filename,
    });

class PendingFileWindow {
  const PendingFileWindow(this._showBytes);

  final _ShowBytesCallback _showBytes;

  Future<void> showBytes({
    required Uint8List bytes,
    required String contentType,
    required String filename,
  }) {
    return _showBytes(
      bytes: bytes,
      contentType: contentType,
      filename: filename,
    );
  }
}

PendingFileWindow Function()? _debugPendingFileWindowFactory;

@visibleForTesting
void debugSetPendingFileWindowFactory(PendingFileWindow Function()? factory) {
  _debugPendingFileWindowFactory = factory;
}

PendingFileWindow openPendingFileWindow() {
  final debugFactory = _debugPendingFileWindowFactory;
  if (debugFactory != null) {
    return debugFactory();
  }
  return const PendingFileWindow(_showBytesWithPlatformOpen);
}

Future<void> _showBytesWithPlatformOpen({
  required Uint8List bytes,
  required String contentType,
  required String filename,
}) async {
  final tempDirectory = await Directory.systemTemp.createTemp('debt-display-');
  final safeFilename = _sanitizeFilename(filename);
  final file = File(
    '${tempDirectory.path}${Platform.pathSeparator}$safeFilename',
  );
  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFile.open(file.path, type: contentType);
  if (result.type == ResultType.done) {
    return;
  }

  final message = result.message.trim();
  throw StateError(message.isEmpty ? 'Could not open $safeFilename.' : message);
}

String _sanitizeFilename(String filename) {
  final trimmed = filename.trim();
  final normalized = trimmed.isEmpty ? 'file' : trimmed;
  final sanitized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_');
  return sanitized.isEmpty ? 'file' : sanitized;
}
