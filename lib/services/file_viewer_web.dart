import 'dart:js_interop';
import 'dart:typed_data';

import 'package:debt_display/services/file_mime_policy.dart';
import 'package:web/web.dart' as web;

class PendingFileWindow {
  PendingFileWindow(this._window);

  final web.Window? _window;

  Future<void> showBytes({
    required Uint8List bytes,
    required String contentType,
    required String filename,
  }) async {
    final safeContentType = normalizeFileContentType(contentType);
    final blob = web.Blob(
      <web.BlobPart>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: safeContentType),
    );
    final url = web.URL.createObjectURL(blob);
    if (!isInlinePreviewContentType(safeContentType)) {
      _window?.close();
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = filename.isEmpty ? 'file' : filename;
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
      return;
    }
    final target = _window;
    if (target == null) {
      web.window.open(url, '_blank');
      return;
    }
    target.location.href = url;
  }
}

PendingFileWindow openPendingFileWindow() {
  return PendingFileWindow(web.window.open('', '_blank'));
}
