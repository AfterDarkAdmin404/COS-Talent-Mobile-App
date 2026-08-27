import 'package:flutter_test/flutter_test.dart';

import 'package:cos_talent/main.dart';

void main() {
  testWidgets('App boots to the setup-needed screen when unconfigured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CosTalentApp(isConfigured: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Supabase isn\'t configured yet'), findsOneWidget);
  });
}
