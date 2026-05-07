import 'dart:typed_data';

class PendingFileWindow {
  Future<void> showBytes({
    required Uint8List bytes,
    required String contentType,
    required String filename,
  }) async {
    throw UnsupportedError('Opening files is not supported on this platform.');
  }
}

PendingFileWindow openPendingFileWindow() => PendingFileWindow();
