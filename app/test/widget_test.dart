import 'package:flutter_test/flutter_test.dart';
import 'package:farsi_vocabulary/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(FarsiVocabularyApp, isNotNull);
  });
}
