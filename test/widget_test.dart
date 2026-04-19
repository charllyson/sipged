import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sipged/gate_page.dart';

void main() {
  testWidgets('GatePage renderiza sem erro', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatePage(),
      ),
    );

    await tester.pump();

    expect(find.byType(GatePage), findsOneWidget);
  });
}