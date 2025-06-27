import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class StatusUploadScreen extends StatefulWidget {
  const StatusUploadScreen({super.key});

  @override
  State<StatusUploadScreen> createState() => _StatusUploadScreenState();
}

class _StatusUploadScreenState extends State<StatusUploadScreen> {
  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Add Status"),
        actions: [
          if (_selectedImage != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadStatus,
              child: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "SHARE",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _selectedImage == null ? _buildImageSelector() : _buildImagePreview(),
    );
  }

  Widget _buildImageSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "Share a photo or video",
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.camera_alt, "Camera", () => _pickImage(ImageSource.camera)),
              _buildActionButton(Icons.photo_library, "Gallery", () => _pickImage(ImageSource.gallery)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Add a caption...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit, color: Colors.grey),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _captionController.clear();
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Retake"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadStatus,
                      icon: _isUploading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.send),
                      label: Text(_isUploading ? "Sharing..." : "Share"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1080, maxHeight: 1920);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _uploadStatus() async {
    if (_selectedImage == null || !_selectedImage!.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid image."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Prepare Cloudinary upload
      final cloudinaryUrl = Uri.parse('https://api.cloudinary.com/v1_1/shivamsingh04/image/upload');
      final uploadPreset = 'flutter_demo';

      final request = http.MultipartRequest('POST', cloudinaryUrl)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (response.statusCode != 200) {
        throw Exception(data['error']['message'] ?? 'Upload failed');
      }

      final imageUrl = data['secure_url'];

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('stories').doc(currentUser!.uid).set({
        'uid': currentUser!.uid,
        'name': currentUser!.displayName ?? 'User',
        'photoUrl': imageUrl,
        'caption': _captionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'userPhotoUrl': currentUser!.photoURL,
        'viewedBy': [],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status uploaded!"), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload status: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }


  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
