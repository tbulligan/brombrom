import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'language_code': 'en',
      'bg_task_scheduled': true,
      'onboarding_seen': true,
    });

    await tester.pumpWidget(const BromBromApp());
    await tester.pumpAndSettle();

    expect(find.text('BromBrom Manager'), findsOneWidget);
  });

  test('buildOsfContentUri selects provider path by storage mode', () {
    expect(
      buildOsfContentUri(
        '/storage/emulated/0/Android/data/com.brombrom.app/files/BromBrom.osf',
        usingInternalStorage: false,
      ),
      'content://com.brombrom.app.fileprovider/map_imports_ext/BromBrom.osf',
    );
    expect(
      buildOsfContentUri(
        '/data/user/0/com.brombrom.app/files/BromBrom.osf',
        usingInternalStorage: true,
      ),
      'content://com.brombrom.app.fileprovider/map_imports_int/BromBrom.osf',
    );
  });

  test('GithubReleaseInfo.fetch times out on stalled response', () async {
    final client = MockClient((_) => Completer<http.Response>().future);
    await expectLater(
      GithubReleaseInfo.fetch(
        'https://example.com/releases/latest',
        client: client,
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  testWidgets('Onboarding slide 3 can finish without notification permission', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'language_code': 'en',
      'bg_task_scheduled': true,
      'onboarding_seen': false,
    });

    await tester.pumpWidget(const BromBromApp());
    await tester.pump();
    await tester.pumpAndSettle();

    // Slide 1 -> Slide 2 -> Slide 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Enable Notifications'), findsOneWidget);
    final finishFinder = find.widgetWithText(ElevatedButton, 'Get Started');
    expect(finishFinder, findsOneWidget);
    expect(tester.widget<ElevatedButton>(finishFinder).onPressed, isNotNull);

    await tester.tap(finishFinder);
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsNothing);
  });
}
