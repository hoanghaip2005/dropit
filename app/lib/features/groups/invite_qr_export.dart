import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum InviteQrSaveResult { saved, downloadStarted, cancelled }

typedef InviteQrSaveCallback =
    Future<InviteQrSaveResult> Function(String inviteUrl);

Future<Uint8List> generateInviteQrPng(String inviteUrl) async {
  const imageSize = 1024.0;
  const quietZone = imageSize * 10 / 220;
  final painter = QrPainter(
    data: inviteUrl,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src)
    ..save()
    ..translate(quietZone, quietZone);
  painter.paint(
    canvas,
    const Size(imageSize - quietZone * 2, imageSize - quietZone * 2),
  );
  canvas.restore();
  final picture = recorder.endRecording();
  final image = await picture.toImage(imageSize.toInt(), imageSize.toInt());
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) {
      throw StateError('Could not encode the invite QR as PNG.');
    }
    return Uint8List.fromList(
      png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<InviteQrSaveResult> saveInviteQrPng(String inviteUrl) async {
  final png = await generateInviteQrPng(inviteUrl);
  final path = await FileSaver.instance.saveAs(
    name: 'dropit-invite-qr',
    bytes: png,
    fileExtension: 'png',
    mimeType: MimeType.png,
    dialogTitle: 'Tải ảnh QR',
  );
  if (path == null) return InviteQrSaveResult.cancelled;
  return kIsWeb
      ? InviteQrSaveResult.downloadStarted
      : InviteQrSaveResult.saved;
}
