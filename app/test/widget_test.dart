import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenkabutsu/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));
  });
}
