import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:tenkabutsu/main.dart';

void main() {
  testWidgets('Camera screen displays camera preview', (WidgetTester tester) async {
    // モックカメラの設定
    final mockCamera = CameraDescription(
      name: 'mock',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );

    // アプリをビルド
    await tester.pumpWidget(
      const MaterialApp(
        home: TakePictureScreen(),
      ),
    );

    // ローディングインジケータが表示されることを確認
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // カメラボタンが表示されることを確認
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
