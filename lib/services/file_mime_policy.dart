const defaultDownloadContentType = 'application/octet-stream';

const _inlinePreviewContentTypes = <String>{
  'application/pdf',
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
  'image/avif',
  'image/bmp',
};

const _rasterImageContentTypes = <String>{
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
  'image/avif',
  'image/bmp',
};

String normalizeFileContentType(String? contentType) {
  final normalized = contentType?.split(';').first.trim().toLowerCase() ?? '';
  if (_inlinePreviewContentTypes.contains(normalized)) {
    return normalized;
  }
  return defaultDownloadContentType;
}

bool isInlinePreviewContentType(String? contentType) {
  return _inlinePreviewContentTypes.contains(
    normalizeFileContentType(contentType),
  );
}

bool isPdfContentType(String? contentType) {
  return normalizeFileContentType(contentType) == 'application/pdf';
}

bool isRasterImageContentType(String? contentType) {
  return _rasterImageContentTypes.contains(
    normalizeFileContentType(contentType),
  );
}
