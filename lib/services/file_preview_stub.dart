import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class BlobFilePreview extends StatelessWidget {
  const BlobFilePreview({
    super.key,
    required this.bytes,
    required this.contentType,
  });

  final Uint8List bytes;
  final String contentType;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
