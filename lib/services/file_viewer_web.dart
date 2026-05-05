import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class PendingFileWindow {
  PendingFileWindow(this._window);

  final web.Window? _window;

  Future<void> showBytes({
    required Uint8List bytes,
    required String contentType,
    required String filename,
  }) async {
    final blob = web.Blob(
      <web.BlobPart>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: contentType),
    );
    final url = web.URL.createObjectURL(blob);
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
