import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'detection_service.dart'; // ✅ Connects to your real Dio API calls

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? _cameraController;
  final SpeechToText _speech = SpeechToText();
  final ImagePicker _picker = ImagePicker();

  bool _isCameraReady = false;
  bool _isListening = false;
  bool _isProcessing = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initSpeech();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: "am_ET",
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          if (command.contains("ያዝ") ||
              command.contains("capture") ||
              command.contains("scan")) {
            _takePicture();
          }
        },
      );
    }
  }

  // 🚀 MAIN LOGIC: Real API Integration
  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing)
      return;

    try {
      HapticFeedback.mediumImpact();
      final XFile photo = await _cameraController!.takePicture();
      _speech.stop();

      // ✅ UI UPDATED: Freeze screen with captured image and show 0% bar
      setState(() {
        _capturedImage = File(photo.path);
        _isProcessing = true;
      });

      // ✅ REAL BACKEND CALL: Sending image to Node.js -> Python AI
      final aiResult = await DetectionService().getPrediction(_capturedImage!);

      if (mounted) {
        if (aiResult != null) {
          // ✅ SUCCESS: Navigate to result screen with real AI map
          context.push(
            '/result',
            extra: {'image': _capturedImage, 'data': aiResult},
          );
          // Reset processing state after navigation so back button works later
          setState(() => _isProcessing = false);
        } else {
          // ❌ FAILURE: API returned null (Check Node/Python terminals)
          setState(() => _isProcessing = false);
          _showErrorSnackBar(
            "AI Analysis failed. Is your Backend and AI running?",
          );
        }
      }
    } catch (e) {
      debugPrint("Capture Logic Error: $e");
      setState(() => _isProcessing = false);
    }
  }

  // Gallery support with real data flow
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null && mounted) {
      setState(() {
        _capturedImage = File(pickedFile.path);
        _isProcessing = true;
      });

      final aiResult = await DetectionService().getPrediction(_capturedImage!);
      if (aiResult != null && mounted) {
        context.push(
          '/result',
          extra: {'image': _capturedImage, 'data': aiResult},
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "RETRY",
          textColor: Colors.white,
          onPressed: _takePicture,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 📺 LAYER 1: LIVE PREVIEW OR CAPTURED IMAGE
          Positioned.fill(
            child:
                _isProcessing && _capturedImage != null
                    ? Image.file(_capturedImage!, fit: BoxFit.cover)
                    : CameraPreview(_cameraController!),
          ),

          // 🎯 LAYER 2: SCANNING OVERLAY (Brackets)
          if (!_isProcessing)
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.withOpacity(0.6),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

          // 💎 LAYER 3: PROFESSIONAL PROCESSING OVERLAY (The 0% bar view)
          if (_isProcessing) _buildProcessingOverlay(),

          // 🔙 LAYER 4: TOP NAVIGATION
          if (!_isProcessing)
            Positioned(
              top: 50,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),

          // 🎮 LAYER 5: BOTTOM CONTROLS
          if (!_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1B12),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _smallCircleBtn(Icons.photo_library, _pickFromGallery),
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const Center(
                          child: Text(
                            "ያዝ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AvatarGlow(
                      animate: _isListening,
                      glowColor: Colors.blue,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 30,
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 6,
            ),
            const SizedBox(height: 30),
            Text(
              "Processing with AI...",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "በአርቲፊሻል ኢንተለጀንስ እየተመረመረ ነው...",
              style: GoogleFonts.notoSansEthiopic(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 50),

            // ✅ THE 0% CONFIDENCE BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confidence",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        "0%",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.05,
                      minHeight: 12,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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

  Widget _smallCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white.withOpacity(0.05),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
