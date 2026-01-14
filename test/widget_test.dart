import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:face/main.dart';
import 'package:face/screens/face_scan_screen.dart';

void main() {
  testWidgets('Face Scan Screen loads with cancel button', (WidgetTester tester) async {
    // 1. Create a dummy CameraDescription to satisfy the requirement
    const camera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    );
    final cameras = [camera];

    // 2. Build the app with isLoggedIn=false to ensure LoginScreen shows first
    await tester.pumpWidget(MyApp(cameras: cameras, isLoggedIn: false));

    // 3. Navigate manually to FaceScanScreen for testing
    await tester.pumpAndSettle();
    await tester.pumpWidget(FaceScanScreen(cameras: cameras));

    // 4. Wait for the widgets to build
    await tester.pumpAndSettle();

    // 5. Verify that the "Cancel" button exists
    expect(find.text('Cancel'), findsOneWidget);

    // 6. Verify that the instruction text is present
    expect(find.textContaining('Move your head'), findsOneWidget);

    // 7. Verify that a counter '0' (from older template) is NOT there
    expect(find.text('0'), findsNothing);
  });
}
