import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../cubits/simple_upload_cubit.dart';

class SimpleUploadScreen extends StatelessWidget {
  const SimpleUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'FLASHOOT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<SimpleUploadCubit, SimpleUploadState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo/Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFfe002a), Color(0xFFcc0022)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Title
                  const Text(
                    'Transform Your Photos',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload a selfie and let AI create a professional portrait',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Upload Button
                  if (state.selectedImage == null)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<SimpleUploadCubit>().pickImage();
                      },
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text(
                        'Upload Image',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFfe002a),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),

                  // Selected Image Preview
                  if (state.selectedImage != null && !state.isProcessing)
                    Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(
                              state.selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<SimpleUploadCubit>().processImage();
                          },
                          icon: const Icon(Icons.auto_awesome,
                              color: Colors.white),
                          label: const Text(
                            'Process with AI',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFfe002a),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            context.read<SimpleUploadCubit>().reset();
                          },
                          child: const Text(
                            'Choose Different Image',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),

                  // Processing Indicator
                  if (state.isProcessing)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFfe002a)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'AI Processing... ${(state.progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Creating stylized portrait with AI...',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: state.progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFfe002a)),
                        ),
                      ],
                    ),

                  // Processed Image
                  if (state.processedImageUrl != null && !state.isProcessing)
                    Column(
                      children: [
                        const Text(
                          'AI Processed Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Stylized portrait with FLASHOOT branding',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Tap image to view full size',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Full-size image with 16:9 aspect ratio
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 9 / 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: GestureDetector(
                              onTap: () => _showFullScreenImage(
                                  context, state.processedImageUrl!),
                              child: Image.file(
                                File(state.processedImageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _downloadImage(
                                    context, state.processedImageUrl!);
                              },
                              icon: const Icon(Icons.download,
                                  color: Colors.white),
                              label: const Text(
                                'Download',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFfe002a),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<SimpleUploadCubit>().reset();
                              },
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              label: const Text(
                                'New Image',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // Error Message
                  if (state.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              context.read<SimpleUploadCubit>().clearError();
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(
                      height: 40), // Bottom padding for better scrolling
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context, String imagePath) async {
    try {
      // Request permission
      final permission = await Permission.storage.request();
      if (permission.isGranted) {
        // Save to gallery
        final result = await ImageGallerySaver.saveFile(imagePath);
        if (result['isSuccess'] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image saved to gallery!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save image'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'AI Generated Image',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await _downloadImage(context, imagePath);
                },
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Download',
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
