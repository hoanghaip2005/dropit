import 'dart:typed_data';
import 'dart:ui' as ui;

import 'qr_pixel_decoder.dart';

Future<List<String>> decodeQrImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 2048);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) {
        throw const FormatException('Could not decode the selected image.');
      }

      final rgba = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final pixels = Int32List(image.width * image.height);
      for (var index = 0; index < pixels.length; index++) {
        final offset = index * 4;
        pixels[index] =
            (rgba[offset + 3] << 24) |
            (rgba[offset] << 16) |
            (rgba[offset + 1] << 8) |
            rgba[offset + 2];
      }

      final payload = decodeQrPixels(image.width, image.height, pixels);
      return payload == null ? const [] : [payload];
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
