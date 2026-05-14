import 'package:flutter_test/flutter_test.dart';

import 'package:project_elite/core/utils/date_utils.dart';

void main() {
  test('DateX produces a 7-day window ending today', () {
    final days = DateX.last7Days();
    expect(days.length, 7);
    expect(
      DateX.dayKey(days.last),
      DateX.todayKey(),
    );
  });
}
