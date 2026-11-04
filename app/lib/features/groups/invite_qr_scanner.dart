import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/env.dart';
import 'qr_image_decoder_stub.dart'
    if (dart.library.js_interop) 'qr_image_decoder_web.dart'
    as qr_image_decoder;

final _inviteCodePattern = RegExp(r'^[A-HJ-NP-Z2-9]{8}$');
final _consentFragmentPattern = RegExp(r'^/consent/([A-HJ-NP-Z2-9]{8})$');

String? parseInviteQrPayload(String payload, {String? baseUrl}) {
  final value = payload.trim();
  final normalizedCode = value.toUpperCase();
  if (_inviteCodePattern.hasMatch(normalizedCode)) return normalizedCode;

  final scannedUri = Uri.tryParse(value);
  final appUri = Uri.tryParse(baseUrl ?? Env.baseUrl);
  if (scannedUri == null || appUri == null) return null;
  if (scannedUri.userInfo.isNotEmpty ||
      scannedUri.scheme != appUri.scheme ||
      scannedUri.host != appUri.host ||
      scannedUri.port != appUri.port ||
      scannedUri.path != appUri.path ||
      scannedUri.query != appUri.query) {
    return null;
  }

  return _consentFragmentPattern.firstMatch(scannedUri.fragment)?.group(1);
}

String? inviteConsentRouteFromQr(String payload, {String? baseUrl}) {
  final code = parseInviteQrPayload(payload, baseUrl: baseUrl);
  return code == null ? null : '/consent/$code';
}

String? firstInviteConsentRouteFromQr(
  Iterable<String> payloads, {
  String? baseUrl,
}) {
  for (final payload in payloads) {
    final route = inviteConsentRouteFromQr(payload, baseUrl: baseUrl);
    if (route != null) return route;
  }
  return null;
}

class InviteQrScannerScreen extends StatefulWidget {
  const InviteQrScannerScreen({super.key});

  @override
  State<InviteQrScannerScreen> createState() => _InviteQrScannerScreenState();
}

class _InviteQrScannerScreenState extends State<InviteQrScannerScreen> {
  final _controller = MobileScannerController();
  String? _lastRejectedPayload;
  String? _galleryError;
  bool _handled = false;
  bool _readingGalleryImage = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      MobileScannerPlatform.instance.setWebBarcodeReader(
        WebBarcodeReader.barcodeDetector,
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    _handlePayloads(
      capture.barcodes
          .where((barcode) => barcode.format == BarcodeFormat.qrCode)
          .map((barcode) => barcode.rawValue)
          .whereType<String>(),
    );
  }

  void _handlePayloads(Iterable<String> payloads) {
    if (_handled) return;
    final candidates = payloads
        .where((payload) => payload.trim().isNotEmpty)
        .toList();
    final route = firstInviteConsentRouteFromQr(candidates);
    if (route == null) {
      for (final payload in candidates) {
        if (_lastRejectedPayload == payload) break;
        _lastRejectedPayload = payload;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Mã QR không hợp lệ. Hãy quét mã mời DropIt! hoặc nhập mã thủ công.',
              ),
            ),
          );
        break;
      }
      return;
    }

    _handled = true;
    _lastRejectedPayload = null;
    context.replace(route);
  }

  Future<void> _pickQrImage() async {
    if (_readingGalleryImage || _handled) return;
    setState(() {
      _readingGalleryImage = true;
      _galleryError = null;
    });

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;

      final List<String> payloads;
      if (kIsWeb) {
        payloads = await qr_image_decoder.decodeQrImage(
          await image.readAsBytes(),
        );
      } else {
        final capture = await _controller.analyzeImage(
          image.path,
          formats: const [BarcodeFormat.qrCode],
        );
        payloads =
            capture?.barcodes
                .where((barcode) => barcode.format == BarcodeFormat.qrCode)
                .map((barcode) => barcode.rawValue)
                .whereType<String>()
                .toList() ??
            const [];
      }

      if (!mounted) return;
      if (firstInviteConsentRouteFromQr(payloads) == null) {
        setState(() {
          _galleryError =
              'Không tìm thấy mã mời DropIt! hợp lệ trong ảnh. Hãy chọn ảnh khác hoặc nhập mã.';
        });
      } else {
        _handlePayloads(payloads);
      }
    } on UnsupportedError {
      if (mounted) {
        setState(() {
          _galleryError =
              'Không thể đọc QR từ ảnh trong môi trường này. Hãy thử quét bằng camera hoặc nhập mã thủ công.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _galleryError =
              'Không đọc được ảnh này. Hãy chọn ảnh QR khác hoặc nhập mã thủ công.';
        });
      }
    } on MobileScannerBarcodeException {
      if (mounted) {
        setState(() {
          _galleryError =
              'Không giải mã được mã trong ảnh. Hãy chọn ảnh khác hoặc nhập mã thủ công.';
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _galleryError = 'Không mở được ảnh. Hãy chọn ảnh khác hoặc nhập mã.';
        });
      }
    } on Exception catch (error) {
      debugPrint('Failed to decode invite QR image: $error');
      if (mounted) {
        setState(() {
          _galleryError =
              'Không đọc được ảnh QR. Hãy chọn ảnh khác hoặc nhập mã thủ công.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _readingGalleryImage = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét mã QR'),
        actions: [
          TextButton(
            onPressed: () => context.replace('/join'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Nhập mã'),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _cameraError(error),
            placeholderBuilder: (_) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            overlayBuilder: (_, constraints) {
              final side = math.min(
                constraints.maxWidth * .72,
                constraints.maxHeight * .48,
              );
              return IgnorePointer(
                child: Center(
                  child: Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .92),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Đặt mã QR lời mời vào trong khung để quét.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    if (_galleryError case final error?) ...[
                      const SizedBox(height: 8),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _readingGalleryImage ? null : _pickQrImage,
                      icon: _readingGalleryImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _readingGalleryImage
                            ? 'Đang đọc ảnh…'
                            : 'Chọn ảnh QR từ thư viện',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.replace('/join'),
                      icon: const Icon(Icons.keyboard_outlined),
                      label: const Text('Nhập mã thủ công'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraError(MobileScannerException error) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Chưa có quyền dùng camera. Hãy cho phép camera hoặc nhập mã thủ công.',
      MobileScannerErrorCode.unsupported =>
        'Thiết bị hoặc trình duyệt này không hỗ trợ quét camera. Bạn có thể nhập mã thủ công.',
      _ =>
        'Không mở được camera hoặc trình duyệt không hỗ trợ quét. Hãy thử lại hoặc nhập mã thủ công.',
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
