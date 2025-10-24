// This is a basic Flutter widget test for CrumbChain app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crumbchain/main.dart';

void main() {
  testWidgets('Login page displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CrumbChainApp());

    // Verify that the app name is displayed.
    expect(find.text('CrumbChain'), findsOneWidget);

    // Verify that the tagline is displayed.
    expect(
      find.text('Connecting surplus food with those in need'),
      findsOneWidget,
    );

    // Verify that both role selection cards are displayed.
    expect(find.text('I\'m a Donor'), findsOneWidget);
    expect(find.text('I\'m a Receiver'), findsOneWidget);

    // Verify that the Continue button is displayed.
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('User can select donor role', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CrumbChainApp());

    // Tap on the Donor card.
    await tester.tap(find.text('I\'m a Donor'));
    await tester.pump();

    // Verify that the checkmark appears (icon check).
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('User can select receiver role', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CrumbChainApp());

    // Tap on the Receiver card.
    await tester.tap(find.text('I\'m a Receiver'));
    await tester.pump();

    // Verify that the checkmark appears (icon check).
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('User can switch between roles', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CrumbChainApp());

    // Tap on the Donor card.
    await tester.tap(find.text('I\'m a Donor'));
    await tester.pump();

    // Verify checkmark appears.
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Now tap on the Receiver card.
    await tester.tap(find.text('I\'m a Receiver'));
    await tester.pump();

    // Verify checkmark still appears (just one, for the new selection).
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
