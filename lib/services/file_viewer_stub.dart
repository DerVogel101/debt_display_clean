import 'dart:typed_data';

class PendingFileWindow {
  Future<void> showBytes({
    required Uint8List bytes,
    required String contentType,
    required String filename,
  }) async {}
}

PendingFileWindow openPendingFileWindow() => PendingFileWindow();
