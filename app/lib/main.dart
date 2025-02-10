import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  print('cameras: $cameras');
  runApp(const MaterialApp(home: TakePictureScreen()));
}


class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({Key? key}) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String? imagePath;
  Offset? _focusPoint;

  bool showFocusCircle = false;
  double x = 0;
  double y = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      cameras[3],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;

    await _controller.setFocusMode(FocusMode.auto);
    await _controller.setExposureMode(ExposureMode.auto);
    setState(() {});
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    // final String filePath = join(dirPath, '${DateTime.now()}.png');

    try {
      await _initializeControllerFuture;

      final XFile image = await _controller.takePicture();
      if (!context.mounted) return;

      setState(() {
        imagePath = imagePath;
      });
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (!_controller.value.isInitialized) {
      print('カメラが初期化されていないためフォーカスを設定できません');
      return;
    }

    try {
      final size = MediaQuery.of(context).size;
      final x = details.globalPosition.dx;
      final y = details.globalPosition.dy;

      // 画面外のタップを無視
      if (x < 0 || x > size.width || y < 0 || y > size.height) {
        print('画面外のタップを無視: x=$x, y=$y');
        return;
      }

      // タップ位置を0-1の範囲に正規化
      final normalizedX = (x / size.width).clamp(0.0, 1.0);
      final normalizedY = (y / size.height).clamp(0.0, 1.0);
      final point = Offset(normalizedX, normalizedY);

      print('タップ位置: x=${point.dx.toStringAsFixed(3)}, y=${point.dy.toStringAsFixed(3)}');
      print('画面サイズ: width=${size.width.toStringAsFixed(1)}, height=${size.height.toStringAsFixed(1)}');
      print('カメラ情報:');
      print('- 解像度: ${_controller.value.previewSize}');
      print('- フォーカスモード: ${_controller.value.focusMode}');
      print('- 露出モード: ${_controller.value.exposureMode}');

      await _controller.setFocusPoint(point);
      await _controller.setExposurePoint(point);
      print('フォーカスと露出ポイント設定完了: $point');

      setState(() {
        showFocusCircle = true;
        this.x = x;
        this.y = y;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showFocusCircle = false;
          });
        }
      });
    } catch (e) {
      print('フォーカス/露出設定エラー: $e');
      print('スタックトレース: ${StackTrace.current}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onTapUp: (details) => _onTap(details),
                        child: Stack(
                          children: [
                            Center(
                                child: CameraPreview(_controller)
                            ),
                            if(showFocusCircle) Positioned(
                                top: y-20,
                                left: x-20,
                                child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white,width: 1.5)
                              ),
                            ))
                          ],
                        )
                      ),
                    ],
                  );
                },
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}


class DisplayPictureScreen extends StatelessWidget {
  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  Future<void> _uploadImage() async {
    // if (imagePath == null) return;

    var uri = Uri.parse('https://api-747779889828.asia-northeast1.run.app/');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print((await http.Response.fromStream(response)).body);
        print('successfully');
      } else {
        print('failed');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadImage,
        child: const Icon(Icons.upload),
      ),
    );
  }
}
