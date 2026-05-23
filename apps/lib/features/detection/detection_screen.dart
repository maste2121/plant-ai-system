import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));

      // Connection-Ready: This is where Member 3's AI model will be called
      _proceedToAnalysis();
    }
  }

  void _proceedToAnalysis() {
    // Navigate to results page (passing the image)
    context.push('/result', extra: _image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark camera feel
      appBar: AppBar(
        title: const Text("Scan Plant / ተክል ምርመራ"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _image != null
                    ? Image.file(_image!)
                    : Center(
                      child: Icon(
                        Icons.camera_enhance,
                        size: 100,
                        color: Colors.green.withOpacity(0.5),
                      ),
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(40),
            color: const Color(0xFF0D1B12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionCircle(
                  Icons.photo_library,
                  () => _pickImage(ImageSource.gallery),
                ),
                _actionCircle(
                  Icons.camera_alt,
                  () => _pickImage(ImageSource.camera),
                  isLarge: true,
                ),
                _actionCircle(Icons.flash_on, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCircle(
    IconData icon,
    VoidCallback onTap, {
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: isLarge ? 40 : 30,
        backgroundColor: isLarge ? Colors.green : Colors.white10,
        child: Icon(icon, color: Colors.white, size: isLarge ? 40 : 25),
      ),
    );
  }
}
