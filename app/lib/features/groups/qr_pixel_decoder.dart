import 'dart:typed_data';

import 'package:zxing2/qrcode.dart';

String? decodeQrPixels(int width, int height, Int32List pixels) {
  final source = RGBLuminanceSource(width, height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  try {
    return QRCodeReader().decode(bitmap).text;
  } on ReaderException {
    return null;
  }
}
