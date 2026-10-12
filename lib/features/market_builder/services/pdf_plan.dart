import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

bool isPdf(Uint8List bytes) =>
    bytes.length > 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46; // %PDF

Future<int> pdfPageCount(Uint8List pdf) async {
  final doc = await PdfDocument.openData(pdf);
  try {
    return doc.pagesCount;
  } finally {
    await doc.close();
  }
}

/// Renders page [pageNumber] (1-based) of [pdf] as a JPEG whose long edge is
/// [longEdge] pixels, on white. Large enough for the AI to read small labels,
/// and kept under the 5 MB upload limit.
Future<Uint8List> renderPdfPage(Uint8List pdf, int pageNumber, {double longEdge = 2600}) async {
  final doc = await PdfDocument.openData(pdf);
  try {
    final page = await doc.getPage(pageNumber);
    try {
      var edge = longEdge;
      while (true) {
        final scale = edge / math.max(page.width, page.height);
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 88,
        );
        if (image == null) throw StateError('Die PDF-Seite konnte nicht gerendert werden.');
        if (image.bytes.lengthInBytes < 4.8 * 1024 * 1024 || edge <= 1200) return image.bytes;
        edge *= 0.8;
      }
    } finally {
      await page.close();
    }
  } finally {
    await doc.close();
  }
}

/// Small previews of every page, for choosing the one with the plan.
Future<List<Uint8List>> renderPdfThumbnails(Uint8List pdf, {int maxPages = 12}) async {
  final doc = await PdfDocument.openData(pdf);
  final thumbs = <Uint8List>[];
  try {
    for (var i = 1; i <= math.min(doc.pagesCount, maxPages); i++) {
      final page = await doc.getPage(i);
      try {
        final scale = 360 / math.max(page.width, page.height);
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 70,
        );
        if (image != null) thumbs.add(image.bytes);
      } finally {
        await page.close();
      }
    }
  } finally {
    await doc.close();
  }
  return thumbs;
}
