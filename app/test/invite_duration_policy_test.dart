import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/invite_navigation.dart';
import 'package:dropit/core/models.dart';

void main() {
  test('Invite return preserves internal consent only', () {
    expect(safeInviteReturn('/consent/ABCD1234'), '/consent/ABCD1234');
    for (final value in ['https://other.test', '//other.test', '/groups', '/consent/a?x=y']) {
      expect(safeInviteReturn(value), isNull);
    }
    expect(Uri.parse(authRouteWithInvite('/login', '/consent/ABCD1234')).queryParameters['next'], '/consent/ABCD1234');
  });
  test('Custom duration rewards preserve old values and cap long sessions', () {
    expect(sessionRewardCoins(1), 0);
    expect(sessionRewardCoins(10), 4);
    expect(sessionRewardCoins(25), 10);
    expect(sessionRewardCoins(37), 17);
    expect(sessionRewardCoins(50), 25);
    expect(sessionRewardCoins(240), 25);
  });
}
