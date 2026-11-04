import 'package:dropit/features/groups/invite_qr_export.dart';
import 'package:dropit/features/groups/qr_image_decoder_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates a PNG QR containing the invite URL', () async {
    const inviteUrl = 'https://app.dropit.example/#/consent/ABCDEFGH';

    final png = await generateInviteQrPng(inviteUrl);

    expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(await decodeQrImage(png), [inviteUrl]);
  });
}
