import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:debt_display/services/file_mime_policy.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class BlobFilePreview extends StatefulWidget {
  const BlobFilePreview({
    super.key,
    required this.bytes,
    required this.contentType,
  });

  final Uint8List bytes;
  final String contentType;

  @override
  State<BlobFilePreview> createState() => _BlobFilePreviewState();
}

class _BlobFilePreviewState extends State<BlobFilePreview> {
  late final String _viewType;
  String? _url;

  @override
  void initState() {
    super.initState();
    _viewType = 'file-preview-${DateTime.now().microsecondsSinceEpoch}';
    final safeContentType = normalizeFileContentType(widget.contentType);
    final blob = web.Blob(
      <web.BlobPart>[widget.bytes.toJS].toJS,
      web.BlobPropertyBag(type: safeContentType),
    );
    _url = web.URL.createObjectURL(blob);
    final frame = web.HTMLIFrameElement()
      ..src = _url!
      ..title = 'File preview';
    frame.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%'
      ..borderRadius = '12px';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => frame);
  }

  @override
  void dispose() {
    final url = _url;
    if (url != null) {
      web.URL.revokeObjectURL(url);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
