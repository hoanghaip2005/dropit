import 'package:dio/dio.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/models_ext.dart';
import 'package:dropit/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class PagedHistoryApi extends DropItApi {
  PagedHistoryApi({this.repeatCursor = false}) : super(Dio());
  final bool repeatCursor;
  final calls = <(String?, String?, String?)>[];
  @override
  Future<HistoryPage> history({String? cursor, int limit = 30, String? from, String? to}) async {
    calls.add((cursor, from, to));
    return HistoryPage([
      MySessionResult.fromJson({'session_id': cursor ?? 'first'}),
    ], cursor == null || repeatCursor ? 'next' : null);
  }
}

void main() {
  const range = ('2026-10-20T17:00:00.000Z', '2026-10-21T17:00:00.000Z');
  test('Selected old period loads all pages and forwards identical bounds', () async {
    final api = PagedHistoryApi();
    final container = ProviderContainer(overrides: [apiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    final result = await container.read(historyPeriodProvider(range).future);
    expect(result.items.map((e) => e.sessionId), ['first', 'next']);
    expect(result.nextCursor, isNull);
    expect(api.calls, [(null, range.$1, range.$2), ('next', range.$1, range.$2)]);
  });
  test('Repeated server cursor fails rather than looping or publishing partial totals', () async {
    final api = PagedHistoryApi(repeatCursor: true);
    final container = ProviderContainer(overrides: [apiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    await expectLater(container.read(historyPeriodProvider(range).future), throwsStateError);
    expect(api.calls, hasLength(2));
  });
}
