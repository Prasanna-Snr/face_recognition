import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:face/main.dart';

void main() {
  testWidgets('Face Scan Screen loads with cancel button', (WidgetTester tester) async {
    // 1. Create a dummy CameraDescription to satisfy the requirement
    const camera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    );
    final cameras = [camera];

    // 2. Build our app and pass the dummy cameras.
    // Note: We use MyApp(cameras: cameras) because that's our root widget now.
    await tester.pumpWidget(MyApp(cameras: cameras));

    // 3. Verify that the "Cancel" button exists.
    expect(find.text('Cancel'), findsOneWidget);

    // 4. Verify that the instruction text is present.
    expect(find.textContaining('Move your head'), findsOneWidget);

    // 5. Verify that the counter '0' (from the old template) is NOT there.
    expect(find.text('0'), findsNothing);
  });
}