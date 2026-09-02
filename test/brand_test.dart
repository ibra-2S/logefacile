import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/core/widgets/brand.dart';

void main() {
  testWidgets('les widgets de marque se construisent sans déborder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: null,
          body: Column(
            children: [
              LogeFacileMark(size: 40),
              LogeFacileMark.mono(size: 28, color: Colors.white),
              SizedBox(
                width: 140, // titre d'AppBar étroit : ne doit pas déborder
                child: LogeFacileWordmark(height: 30, monoColor: Colors.white),
              ),
              LogeFacileWordmark(height: 48),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
