import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'pdf_plan.dart';

/// Largest image we upload (Storage rules allow 5 MB).
const _maxImageBytes = 4500000;

/// A picked file: either a PDF or an image as PNG, JPEG or WebP.
class PickedInput {
  final Uint8List bytes;
  final String contentType;

  const PickedInput(this.bytes, this.contentType);

  bool get isPdf => contentType == 'application/pdf';
}

String? detectImageType(Uint8List b) {
  if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
  if (b.length > 12 && String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') return 'image/webp';
  return null;
}

/// Makes any image iOS can decode (also HEIC) usable for upload: keeps PNG,
/// JPEG and WebP up to 4.5 MB as they are, otherwise re-encodes as PNG and
/// scales down until it fits. Null if the bytes are no image.
Future<PickedInput?> normalizeImage(Uint8List bytes) async {
  final type = detectImageType(bytes);
  if (type != null && bytes.lengthInBytes <= _maxImageBytes) return PickedInput(bytes, type);
  try {
    var maxSide = 3000;
    while (maxSide >= 1000) {
      final probe = await ui.instantiateImageCodec(bytes);
      final frame = await probe.getNextFrame();
      final w = frame.image.width, h = frame.image.height;
      frame.image.dispose();
      final scale = (maxSide / (w > h ? w : h)).clamp(0.0, 1.0);
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: (w * scale).round(),
        targetHeight: (h * scale).round(),
      );
      final image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return null;
      final png = data.buffer.asUint8List();
      if (png.lengthInBytes <= _maxImageBytes) return PickedInput(png, 'image/png');
      maxSide = (maxSide * 0.75).round();
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// Lets the user pick a photo or a file (PDF or image). Shows a message and
/// returns null when nothing usable came back – never fails silently.
Future<PickedInput?> pickImageOrPdf(BuildContext context, {String photosSubtitle = 'Foto oder Screenshot'}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Bild aus Fotos'),
            subtitle: Text(photosSubtitle),
            onTap: () => Navigator.pop(context, 'photos'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Datei: PDF oder Bild'),
            subtitle: const Text('z. B. von der Webseite des Marktes'),
            onTap: () => Navigator.pop(context, 'files'),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  void fail(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Uint8List? bytes;
  try {
    if (source == 'photos') {
      // No resizing here: the picker would have to re-save the photo, which
      // fails for some images (image_picker returns "invalid_image").
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, requestFullMetadata: false);
      bytes = await file?.readAsBytes();
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'heic'],
        withData: true,
      );
      bytes = result?.files.single.bytes;
    }
  } on PlatformException catch (e) {
    fail('Die Datei konnte nicht geladen werden (${e.code}). Versuch es über „Datei: PDF oder Bild“.');
    return null;
  } catch (e) {
    fail('Die Datei konnte nicht geladen werden: $e');
    return null;
  }
  if (bytes == null) return null; // cancelled

  if (isPdf(bytes)) return PickedInput(bytes, 'application/pdf');
  final image = await normalizeImage(bytes);
  if (image == null) fail('Bitte ein PDF oder ein Bild (PNG, JPG, WebP, HEIC) wählen.');
  return image;
}
