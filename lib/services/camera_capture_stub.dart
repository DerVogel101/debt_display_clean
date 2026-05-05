import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class CapturedImage {
  const CapturedImage({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String filename;
  final Uint8List bytes;
  final String contentType;
}

Future<CapturedImage?> captureImageWithCamera(BuildContext context) async {
  return null;
}
