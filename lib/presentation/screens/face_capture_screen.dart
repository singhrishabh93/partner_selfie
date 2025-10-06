import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'simple_upload_screen.dart';

class AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  AnimatedBorderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the animated line directly on the existing oval border
    // The oval container is 280x350 with border radius 140
    final center = Offset(size.width / 2, size.height / 2);

    // Create a proper elliptical path that matches the oval container
    final path = Path();
    final ovalRect = Rect.fromCenter(
      center: center,
      width: 280.0, // Same as container width
      height: 350.0, // Same as container height
    );

    // Create elliptical path with rounded corners
    path.addRRect(
        RRect.fromRectAndRadius(ovalRect, const Radius.circular(140.0)));

    // Create path metrics to measure the path
    final pathMetrics = path.computeMetrics();
    final pathMetric = pathMetrics.first;

    // Calculate how much of the path should be drawn
    final totalLength = pathMetric.length;
    final drawLength = totalLength * progress;

    // Extract the path segment to draw
    final extractPath = pathMetric.extractPath(0, drawLength);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is AnimatedBorderPainter &&
        (oldDelegate.progress != progress || oldDelegate.color != color);
  }
}

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isCapturing = false;
  String _statusText = 'Position your face in the front camera';
  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedImageBytes;
  bool _showCapturedImage = false;
  bool _hasCaptured = false; // Prevent multiple captures

  // Face detection
  late FaceDetector _faceDetector;
  List<Face> _faces = [];
  bool _isFaceDetected = false;
  bool _isFaceInPerfectPosition = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _borderController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;

  // Face detection parameters
  static const double _minFaceSize = 0.25; // More flexible minimum size
  static const double _maxFaceSize = 0.85; // More flexible maximum size
  static const double _faceCenterThreshold =
      0.2; // More lenient for better centered detection

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: _minFaceSize,
      ),
    );
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _borderController = AnimationController(
      duration:
          const Duration(milliseconds: 2000), // 2 seconds for border completion
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _borderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _borderController,
      curve: Curves.linear,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera
        CameraDescription? frontCamera;
        for (final camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }

        // Use front camera if available, otherwise fall back to first camera
        final selectedCamera = frontCamera ?? _cameras![0];

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset
              .medium, // Use medium resolution for better performance
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _startFaceDetection();
        }
      } else {
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _statusText = 'Camera not available. Use gallery option.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _statusText = 'Camera error. Use gallery option.';
        });
      }
    }
  }

  void _startFaceDetection() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream(_processImage);
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isDetecting || _isCapturing) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            _faces = faces;
            _isFaceDetected = faces.isNotEmpty;
            _isFaceInPerfectPosition = _checkFacePosition(faces);
          });

          if (_isFaceInPerfectPosition && !_hasCaptured) {
            if (!_borderController.isAnimating) {
              _statusText = 'Perfect! Capturing...';
              _pulseController.repeat(reverse: true);
              _scaleController.forward();
              _borderController.forward().then((_) {
                if (mounted &&
                    _isFaceInPerfectPosition &&
                    !_isCapturing &&
                    !_hasCaptured) {
                  _captureImage();
                }
              });
            }
          } else if (_isFaceDetected) {
            _statusText = 'Adjust your position';
            _pulseController.stop();
            _scaleController.reverse();
            _borderController.reset();
          } else {
            _statusText = 'Position your face in the frame';
            _pulseController.stop();
            _scaleController.reverse();
            _borderController.reset();
          }
        }
      }
    } catch (e) {
      // Handle face detection errors gracefully
      if (mounted) {
        setState(() {
          _faces = [];
          _isFaceDetected = false;
          _isFaceInPerfectPosition = false;
          _statusText = 'Position your face in the frame';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  bool _checkFacePosition(List<Face> faces) {
    if (faces.isEmpty) return false;

    final face = faces.first;
    final imageSize = _cameraController!.value.previewSize!;
    final faceRect = face.boundingBox;

    // Check if face is centered
    final faceCenterX = faceRect.left + faceRect.width / 2;
    final imageCenterX = imageSize.width / 2;
    final centerOffset = (faceCenterX - imageCenterX).abs() / imageSize.width;

    // Check face size
    final faceSize = faceRect.width / imageSize.width;

    // Check if face is looking at camera (head pose)
    final headPose = face.headEulerAngleY;
    final isLookingAtCamera =
        headPose != null && headPose.abs() < 15; // Within 15 degrees

    return centerOffset < _faceCenterThreshold &&
        faceSize >= _minFaceSize &&
        faceSize <= _maxFaceSize &&
        isLookingAtCamera;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      if (_cameras == null || _cameras!.isEmpty) return null;

      final camera = _cameras![0];
      final sensorOrientation = camera.sensorOrientation;

      final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      if (image.planes.isEmpty) return null;

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || _cameraController == null || _hasCaptured) return;

    _hasCaptured = true; // Set flag immediately to prevent multiple captures

    setState(() {
      _isCapturing = true;
      _statusText = 'Capturing...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await File(image.path).readAsBytes();

      // Flip the image horizontally to remove mirror effect
      final flippedImageBytes = await _flipImageHorizontally(imageBytes);

      // Show captured image with retake option
      if (mounted) {
        setState(() {
          _capturedImageBytes = flippedImageBytes;
          _showCapturedImage = true;
          _statusText = 'Image captured! Review and retake if needed.';
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imageBytes = await File(image.path).readAsBytes();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleUploadScreen(
                capturedImageBytes: imageBytes,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _retakePhoto() {
    setState(() {
      _showCapturedImage = false;
      _capturedImageBytes = null;
      _hasCaptured = false; // Reset capture flag for retake
      _statusText = 'Position your face in the front camera';
    });
  }

  void _proceedWithPhoto() {
    if (_capturedImageBytes != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleUploadScreen(
            capturedImageBytes: _capturedImageBytes!,
          ),
        ),
      );
    }
  }

  Future<Uint8List> _flipImageHorizontally(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Flip horizontally
    canvas.scale(-1.0, 1.0);
    canvas.translate(-image.width.toDouble(), 0);
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _pulseController.dispose();
    _scaleController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  Widget _buildCapturedImagePreview() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Review Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Captured image
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(140),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(136),
                    child: Image.memory(
                      _capturedImageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Retake button
                  ElevatedButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Retake',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),

                  // Proceed button
                  ElevatedButton.icon(
                    onPressed: _proceedWithPhoto,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Use Photo',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show captured image with retake option
    if (_showCapturedImage && _capturedImageBytes != null) {
      return _buildCapturedImagePreview();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // Dark blue gradient background
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview (moved to oval area)
            if (!_isInitialized && _statusText.contains('error'))
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2a2a4e), Color(0xFF1a1a2e)],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.white54,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Camera not available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use the gallery button to select a photo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2a2a4e), Color(0xFF1a1a2e)],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),

            // Main content with oval guide
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2a2a4e), Color(0xFF1a1a2e)],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    // Avatar icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Instructions
                    const Text(
                      'Put your face in the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Large oval guide with camera preview
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _borderAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 280,
                              height: 350,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(140),
                                border: Border.all(
                                  color: _isFaceInPerfectPosition
                                      ? Colors.green
                                      : Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Camera preview inside oval
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(136),
                                    child: Stack(
                                      children: [
                                        if (_isInitialized &&
                                            _cameraController != null)
                                          Positioned.fill(
                                            child: CameraPreview(
                                                _cameraController!),
                                          )
                                        else
                                          Container(
                                            color: _isFaceInPerfectPosition
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.white.withOpacity(0.1),
                                          ),

                                        // Overlay for perfect position
                                        if (_isFaceInPerfectPosition)
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(136),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Animated border overlay
                                  if (_isFaceInPerfectPosition)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: AnimatedBorderPainter(
                                          progress: _borderAnimation.value,
                                          color: Colors.green,
                                          strokeWidth: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Bottom instructions
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Stay in lighting area and\nkeep your face in the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Overlay with face detection circle (hidden, only for detection)
            if (_isInitialized)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceDetectionPainter(
                    faces: _faces,
                    isFaceInPerfectPosition: _isFaceInPerfectPosition,
                    pulseAnimation: _pulseAnimation,
                    scaleAnimation: _scaleAnimation,
                    showCircle: false, // Hide the detection circle
                  ),
                ),
              ),

            // Status text (top)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final bool isFaceInPerfectPosition;
  final Animation<double> pulseAnimation;
  final Animation<double> scaleAnimation;
  final bool showCircle;

  FaceDetectionPainter({
    required this.faces,
    required this.isFaceInPerfectPosition,
    required this.pulseAnimation,
    required this.scaleAnimation,
    this.showCircle = true,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty || !showCircle) return;

    final face = faces.first;
    final faceRect = face.boundingBox;

    // Calculate circle position and size
    final centerX = faceRect.left + faceRect.width / 2;
    final centerY = faceRect.top + faceRect.height / 2;
    final radius = (faceRect.width + faceRect.height) / 4;

    // Apply animations
    final animatedRadius = radius * scaleAnimation.value;
    final pulseRadius = animatedRadius * pulseAnimation.value;

    // Draw the face detection circle
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    if (isFaceInPerfectPosition) {
      // Green circle with pulse animation
      paint.color = Colors.green;
      canvas.drawCircle(
        Offset(centerX, centerY),
        pulseRadius,
        paint,
      );

      // Inner circle
      paint.color = Colors.green.withOpacity(0.3);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(centerX, centerY),
        animatedRadius * 0.8,
        paint,
      );
    } else {
      // White circle
      paint.color = Colors.white;
      canvas.drawCircle(
        Offset(centerX, centerY),
        animatedRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
