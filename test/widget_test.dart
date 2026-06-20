import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Guna jalan pintas keluar folder untuk cari main.dart tanpa ralat pakej
import '../lib/main.dart'; 

void main() {
  testWidgets('Counter value test placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}