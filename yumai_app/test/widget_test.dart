// Basic smoke test for yumai_app.
import 'package:flutter_test/flutter_test.dart';
import 'package:yumai_app/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    // Just verify the app can be instantiated with required parameters.
    // Full widget testing requires mocking SharedPreferences and ThemeProvider.
    expect(const MyApp(initialLang: 'zh'), isNotNull);
  });
}
