import 'package:debt_display/services/file_mime_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes allowed inline content types', () {
    expect(
      normalizeFileContentType(' Application/PDF ; charset=binary '),
      'application/pdf',
    );
    expect(normalizeFileContentType('IMAGE/PNG'), 'image/png');
    expect(normalizeFileContentType('image/jpeg'), 'image/jpeg');
    expect(normalizeFileContentType('image/gif'), 'image/gif');
    expect(normalizeFileContentType('image/webp'), 'image/webp');
    expect(normalizeFileContentType('image/avif'), 'image/avif');
    expect(normalizeFileContentType('image/bmp'), 'image/bmp');
  });

  test('maps active unknown and unsafe content types to octet stream', () {
    expect(normalizeFileContentType(null), defaultDownloadContentType);
    expect(normalizeFileContentType(''), defaultDownloadContentType);
    expect(normalizeFileContentType('text/html'), defaultDownloadContentType);
    expect(
      normalizeFileContentType('image/svg+xml'),
      defaultDownloadContentType,
    );
    expect(
      normalizeFileContentType('application/xml'),
      defaultDownloadContentType,
    );
    expect(
      normalizeFileContentType('text/javascript'),
      defaultDownloadContentType,
    );
    expect(
      normalizeFileContentType('application/javascript'),
      defaultDownloadContentType,
    );
  });

  test('reports preview capabilities for only pdf and safe rasters', () {
    expect(isInlinePreviewContentType('application/pdf'), isTrue);
    expect(isPdfContentType('application/pdf; charset=utf-8'), isTrue);
    expect(isRasterImageContentType('image/webp'), isTrue);

    expect(isInlinePreviewContentType('text/html'), isFalse);
    expect(isPdfContentType('text/html'), isFalse);
    expect(isRasterImageContentType('image/svg+xml'), isFalse);
  });
}
