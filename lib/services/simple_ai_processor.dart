import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'gemini_v1beta_service.dart';

class SimpleAIProcessor {
  // Local asset paths
  static const String logoAssetPath = 'assets/logo.png';
  static const String backgroundAssetPath = 'assets/background.png';

  /// Load image from assets and return as bytes
  static Future<Uint8List> loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to load asset $assetPath: $e');
    }
  }

  /// Process image with Gemini AI using v1beta API
  static Future<File> processImageWithAI(File originalImage) async {
    try {
      print(
          'Starting AI processing with Gemini 2.5 Flash Image Preview via v1beta API...');

      // Load all images as bytes
      final originalImageBytes = await originalImage.readAsBytes();
      final logoBytes = await loadAssetImage(logoAssetPath);
      final backgroundBytes = await loadAssetImage(backgroundAssetPath);

      print('All images loaded - processing with Gemini v1beta...');

      // Use the v1beta service for image generation with assets
      return await GeminiV1BetaService.generateStylizedPortraitWithAssets(
          originalImageBytes, logoBytes, backgroundBytes);
    } catch (e) {
      print('Error in Gemini v1beta processing: $e');
      throw Exception('Gemini v1beta processing failed: $e');
    }
  }
}
