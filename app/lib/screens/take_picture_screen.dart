import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tenkabutsu/screens/display_picture_screen.dart';

class TakePictureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const TakePictureScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);

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
      widget.cameras[3],
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

      if (x < 0 || x > size.width || y < 0 || y > size.height) {
        print('画面外のタップを無視: x=$x, y=$y');
        return;
      }

      final normalizedX = (x / size.width).clamp(0.0, 1.0);
      final normalizedY = (y / size.height).clamp(0.0, 1.0);
      final point = Offset(normalizedX, normalizedY);

      await _controller.setFocusPoint(point);
      await _controller.setExposurePoint(point);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/icon_ai.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                GestureDetector(
                  onTapUp: _onTap,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 3/4,
                              child: CameraPreview(_controller),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54, width: 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      if (showFocusCircle) 
                        Positioned(
                          top: y - 20,
                          left: x - 20,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
