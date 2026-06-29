import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:to_do_app/core/utils/permission_helper.dart';
import 'photo_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCamera = 0;
  bool _isFlashOn = false;
  bool _isTakingPhoto = false;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  bool _hasCameraHardware = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Windows/Desktop check or web
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      setState(() {
        _hasCameraHardware = false;
        _initError = 'Camera không hỗ trợ trên nền tảng Desktop hiện tại. Vui lòng chọn ảnh từ tệp.';
      });
      return;
    }

    try {
      final granted = await PermissionHelper.requestCamera();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập máy ảnh bị từ chối.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _hasCameraHardware = false;
          _initError = 'Không tìm thấy phần cứng máy ảnh.';
        });
        return;
      }

      await _startCamera(_cameras[_selectedCamera]);
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() {
        _hasCameraHardware = false;
        _initError = 'Lỗi khởi động máy ảnh: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription cam) async {
    _controller?.dispose();

    final ctrl = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await ctrl.initialize();
      _minZoom = await ctrl.getMinZoomLevel();
      _maxZoom = await ctrl.getMaxZoomLevel();

      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _hasCameraHardware = true;
      });
    } catch (e) {
      debugPrint('Start camera error: $e');
      setState(() {
        _hasCameraHardware = false;
        _initError = 'Không thể kết nối máy ảnh: $e';
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCamera = (_selectedCamera + 1) % _cameras.length;
    await _startCamera(_cameras[_selectedCamera]);
  }

  Future<void> _toggleFlash() async {
    _isFlashOn = !_isFlashOn;
    await _controller?.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails d) async {
    final zoom = (_currentZoom * d.scale).clamp(_minZoom, _maxZoom);
    await _controller?.setZoomLevel(zoom);
    setState(() => _currentZoom = zoom);
  }

  Future<void> _onTapFocus(TapDownDetails d) async {
    if (_controller == null) return;
    final size = MediaQuery.of(context).size;
    final offset = Offset(
      d.localPosition.dx / size.width,
      d.localPosition.dy / size.height,
    );
    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    if (_controller == null || _isTakingPhoto) return;
    setState(() => _isTakingPhoto = true);

    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;

      final result = await Navigator.pushReplacement<String, void>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(imagePath: file.path),
        ),
      );
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp ảnh: $e')),
      );
    } finally {
      setState(() => _isTakingPhoto = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null && mounted) {
        final localPath = result.files.single.path!;
        final finalUrl = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoPreviewScreen(imagePath: localPath),
          ),
        );
        if (finalUrl != null && mounted) {
          Navigator.pop(context, finalUrl);
        }
      }
    } catch (e) {
      debugPrint('Pick file error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCameraHardware) {
      return _buildFallbackView();
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          GestureDetector(
            onScaleUpdate: _onScaleUpdate,
            onTapDown: _onTapFocus,
            child: CameraPreview(_controller!),
          ),

          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Flash
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gallery picker
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 32),
                  onPressed: _pickFromGallery,
                ),

                // Shutter button
                GestureDetector(
                  onTap: _takePhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _isTakingPhoto ? 68 : 76,
                    height: _isTakingPhoto ? 68 : 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isTakingPhoto ? Colors.white70 : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black12,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Flip camera
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 32),
                  onPressed: _flipCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MÁY ẢNH', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera không hoạt động',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _initError ?? 'Thiết bị này không hỗ trợ camera hoặc đang chạy giả lập. Hãy chọn một ảnh từ máy tính của bạn.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.insert_drive_file_rounded),
                label: const Text('Chọn ảnh từ tệp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
