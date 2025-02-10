import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/take_picture_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  print('cameras: $cameras');
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TakePictureScreen(cameras: cameras);
  }
}
