import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nissy_bakes_original/components/admin_password_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, List<bool> result) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result.add(await askAdminPassword(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() => dotenv.testLoad(fileInput: 'ADMIN_PASSWORD=secret'));

  testWidgets('correct password closes the dialog without errors',
      (tester) async {
    final result = <bool>[];
    await open(tester, result);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, [true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong password shows an error and stays open', (tester) async {
    final result = <bool>[];
    await open(tester, result);
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong password'), findsOneWidget);
    expect(result, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, [false]);
  });
}
