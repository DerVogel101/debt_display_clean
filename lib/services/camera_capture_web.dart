import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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
  web.MediaStream? stream;
  try {
    stream = await web.window.navigator.mediaDevices
        .getUserMedia(
          web.MediaStreamConstraints(video: true.toJS, audio: false.toJS),
        )
        .toDart;
    if (!context.mounted) {
      _stopStream(stream);
      return null;
    }
    return showDialog<CapturedImage>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CameraCaptureDialog(stream: stream!),
    );
  } catch (_) {
    _stopStream(stream);
    return null;
  }
}

class _CameraCaptureDialog extends StatefulWidget {
  const _CameraCaptureDialog({required this.stream});

  final web.MediaStream stream;

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  late final String _viewType;
  late final web.HTMLVideoElement _video;

  @override
  void initState() {
    super.initState();
    _viewType = 'bill-camera-${DateTime.now().microsecondsSinceEpoch}';
    _video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..playsInline = true
      ..srcObject = widget.stream as web.MediaProvider;
    _video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover'
      ..borderRadius = '12px'
      ..backgroundColor = '#111827';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _video);
    _video.play().toDart.ignore();
  }

  @override
  void dispose() {
    _stopStream(widget.stream);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Take picture'),
      content: SizedBox(
        width: 520,
        height: 360,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('bill-camera-capture-button'),
          onPressed: () {
            final capture = _captureFrame();
            Navigator.of(context).pop(capture);
          },
          icon: const Icon(Icons.photo_camera_rounded),
          label: const Text('Capture'),
        ),
      ],
    );
  }

  CapturedImage _captureFrame() {
    final width = _video.videoWidth == 0 ? 1280 : _video.videoWidth;
    final height = _video.videoHeight == 0 ? 720 : _video.videoHeight;
    final canvas = web.HTMLCanvasElement()
      ..width = width
      ..height = height;
    final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
    context.drawImage(_video, 0, 0, width, height);
    final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
    final encoded = dataUrl.substring(dataUrl.indexOf(',') + 1);
    return CapturedImage(
      filename:
          'camera-${DateTime.now().toIso8601String().replaceAll(':', '-')}.jpg',
      bytes: Uint8List.fromList(base64Decode(encoded)),
      contentType: 'image/jpeg',
    );
  }
}

void _stopStream(web.MediaStream? stream) {
  if (stream == null) {
    return;
  }
  for (final track in stream.getTracks().toDart) {
    track.stop();
  }
}
