import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/usecases/camera_usecase.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  int _selectedCameraIndex = 1;
  bool _isRecording = false;
  XFile? _overlayImage;
  Timer? _recordTimer;
  int _recordDuration = 0;
  final CameraUseCase _cameraUseCase = CameraUseCase();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _controller?.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );
    await _controller?.initialize();
    if (!mounted) return;
    setState(() {});
  }

  void _toggleCamera() async {
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    await _initializeCamera();
  }

  void _pickOverlayImage() async {
    final image = await _cameraUseCase.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _overlayImage = image;
      });
    }
  }

  void _startStopRecording() async {
    if (_isRecording) {
      final video = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      _recordTimer?.cancel();
      _recordDuration = 0;
      await _cameraUseCase.saveVideo(video);
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
      _startTimer();
    }
  }

  void _startTimer() {
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _takePicture() async {
    final image = await _controller!.takePicture();
    await _cameraUseCase.savePhoto(image);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          if (_overlayImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.file(File(_overlayImage!.path), fit: BoxFit.cover),
              ),
            ),
          if (_isRecording)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Positioned(
            bottom: 61,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.settings_backup_restore, color: Colors.white, size: 30),
              onPressed: _toggleCamera,
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: _overlayImage != null
                      ? const Icon(Icons.cancel_outlined, color: Colors.white, size: 30)
                      : const Icon(Icons.photo_library, color: Colors.white, size: 30),
                  onPressed: _overlayImage != null
                      ? () {
                          setState(() {
                            _overlayImage = null;
                          });
                        }
                      : _pickOverlayImage,
                ),
                GestureDetector(
                  onTap: _startStopRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        color: _isRecording ? Colors.white : Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.camera,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: _takePicture,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
