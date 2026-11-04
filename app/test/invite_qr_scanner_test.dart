import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dropit/features/groups/invite_qr_scanner.dart';
import 'package:dropit/features/groups/qr_image_decoder_web.dart';
import 'package:dropit/features/groups/qr_pixel_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing2/qrcode.dart';

void main() {
  const baseUrl = 'https://app.dropit.example';

  test('accepts a valid invite code and normalizes its case', () {
    expect(parseInviteQrPayload(' 576D9S68 ', baseUrl: baseUrl), '576D9S68');
    expect(parseInviteQrPayload('576d9s68', baseUrl: baseUrl), '576D9S68');
  });

  test('accepts only the app consent invite URL', () {
    final payload = Uri.parse(
      baseUrl,
    ).replace(fragment: '/consent/576D9S68').toString();

    expect(parseInviteQrPayload(payload, baseUrl: baseUrl), '576D9S68');
    expect(
      inviteConsentRouteFromQr(payload, baseUrl: baseUrl),
      '/consent/576D9S68',
    );
    expect(
      firstInviteConsentRouteFromQr([
        'invalid QR',
        '576D9S68',
      ], baseUrl: baseUrl),
      '/consent/576D9S68',
    );
    expect(
      parseInviteQrPayload(
        'https://external.example/#/consent/576D9S68',
        baseUrl: baseUrl,
      ),
      isNull,
    );
    expect(
      parseInviteQrPayload('$baseUrl/#/groups/576D9S68', baseUrl: baseUrl),
      isNull,
    );
  });

  test('rejects malformed or invalid invite codes', () {
    expect(parseInviteQrPayload('576D9S6', baseUrl: baseUrl), isNull);
    expect(parseInviteQrPayload('576D9S6O', baseUrl: baseUrl), isNull);
    expect(
      parseInviteQrPayload('$baseUrl/#/consent/576D9S6O', baseUrl: baseUrl),
      isNull,
    );
    expect(inviteConsentRouteFromQr('576D9S6O', baseUrl: baseUrl), isNull);
    expect(
      firstInviteConsentRouteFromQr([
        'invalid QR',
        '576D9S6O',
      ], baseUrl: baseUrl),
      isNull,
    );
  });

  test('decodes an invite QR from local image pixels', () {
    const inviteCode = '576D9S68';
    const scale = 8;
    const quietZone = 4;
    final matrix = Encoder.encode(inviteCode, ErrorCorrectionLevel.h).matrix!;
    final size = (matrix.width + quietZone * 2) * scale;
    final pixels = Int32List(size * size)
      ..fillRange(0, size * size, 0xFFFFFFFF);

    for (var y = 0; y < matrix.height; y++) {
      for (var x = 0; x < matrix.width; x++) {
        if (matrix.get(x, y) != 1) continue;
        for (var dy = 0; dy < scale; dy++) {
          for (var dx = 0; dx < scale; dx++) {
            final px = (x + quietZone) * scale + dx;
            final py = (y + quietZone) * scale + dy;
            pixels[py * size + px] = 0xFF000000;
          }
        }
      }
    }

    expect(decodeQrPixels(size, size, pixels), inviteCode);
  });

  test('decodes an invite QR from a PNG image', () async {
    const inviteCode = '576D9S68';
    const scale = 8;
    const quietZone = 4;
    final matrix = Encoder.encode(inviteCode, ErrorCorrectionLevel.h).matrix!;
    final size = (matrix.width + quietZone * 2) * scale;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    final paint = ui.Paint()..color = const ui.Color(0xFF000000);
    for (var y = 0; y < matrix.height; y++) {
      for (var x = 0; x < matrix.width; x++) {
        if (matrix.get(x, y) != 1) continue;
        canvas.drawRect(
          ui.Rect.fromLTWH(
            (x + quietZone) * scale.toDouble(),
            (y + quietZone) * scale.toDouble(),
            scale.toDouble(),
            scale.toDouble(),
          ),
          paint,
        );
      }
    }

    final image = await recorder.endRecording().toImage(size, size);
    try {
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      expect(await decodeQrImage(png.buffer.asUint8List()), [inviteCode]);
    } finally {
      image.dispose();
    }
  });
}
