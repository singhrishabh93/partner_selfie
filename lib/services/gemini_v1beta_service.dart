import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';

class GeminiV1BetaService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash-image-preview';

  /// Generate image using Gemini 2.5 Flash Image Preview via v1beta API
  static Future<File> generateImage(String prompt) async {
    try {
      print('Starting image generation with Gemini 2.5 Flash Image Preview...');

      final url = Uri.parse('$_baseUrl/models/$_model:generateContent');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 8192,
        }
      };

      print('Sending request to: $url');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': GeminiConfig.apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final imageData = part['inlineData']['data'];
                final mimeType = part['inlineData']['mimeType'];

                print(
                    'Found image data: ${imageData.length} characters, mimeType: $mimeType');

                // Decode base64 image data
                final imageBytes = base64Decode(imageData);

                // Save the generated image
                final tempDir = Directory.systemTemp;
                final imageFile = File(
                    '${tempDir.path}/gemini_generated_${DateTime.now().millisecondsSinceEpoch}.jpg');

                await imageFile.writeAsBytes(imageBytes);
                print('Image saved successfully: ${imageFile.path}');
                return imageFile;
              }
            }
          }
        }

        // If no image was found, check for text response
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            final textParts = candidate['content']['parts']
                .where((part) => part['text'] != null)
                .map((part) => part['text'])
                .join(' ');

            if (textParts.isNotEmpty) {
              print('Gemini response: $textParts');
              throw Exception('Gemini did not generate an image: $textParts');
            }
          }
        }

        throw Exception('No image generated in response');
      } else {
        throw Exception(
            'API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in Gemini v1beta image generation: $e');
      throw Exception('Gemini v1beta processing failed: $e');
    }
  }

  /// Generate stylized portrait with specific prompt
  static Future<File> generateStylizedPortrait(String userPrompt) async {
    const prompt = '''
Create a stylized portrait of a person standing with arms crossed, looking confidently at the camera. 
Use the face from the uploaded image. 
Create a modern, clean background with subtle gradients. 
Position the person slightly to the right side of the frame, not centered. 
The person should wear a plain black fitted t-shirt with the "FLASHOOT" logo printed on it in white text, seamlessly blended into the fabric so it looks naturally printed. 
Lighting should be soft, with a clean professional finish. 
Minimal shadows, modern look, sharp contrast between person and background. 
Final output should be exactly 1600x1200 pixels (4:3 aspect ratio).
''';

    return await generateImage(prompt);
  }

  /// Generate stylized portrait with user image, logo, and background
  static Future<File> generateStylizedPortraitWithAssets(
    Uint8List userImageBytes,
    Uint8List logoBytes,
    Uint8List backgroundBytes,
  ) async {
    try {
      print('Starting image generation with Gemini 2.5 Flash Image Preview...');

      final url = Uri.parse('$_baseUrl/models/$_model:generateContent');

      // Convert images to base64
      final userImageBase64 = base64Encode(userImageBytes);
      final logoBase64 = base64Encode(logoBytes);
      final backgroundBase64 = base64Encode(backgroundBytes);

      const prompt = '''
I'm providing you with 3 images:
1. A person's photo (use their face and body as reference)
2. A logo image (use this exact logo design)
3. A background image (use this as the background)

Create a stylized portrait where:
- Use the person's face and body from the first image
- Apply the exact logo from the second image onto a black fitted t-shirt
- Use the background from the third image as the backdrop
- Position the person slightly to the right side of the frame, not centered
- The logo should be seamlessly blended into the t-shirt fabric so it looks naturally printed
- Lighting should be soft, with a clean professional finish
- Minimal shadows, modern look, sharp contrast between person and background
- Final output should be exactly 1600x1200 pixels (4:3 aspect ratio)
- Make sure the logo is clearly visible and properly integrated into the clothing
''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': userImageBase64,
                }
              },
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': logoBase64,
                }
              },
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': backgroundBase64,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 8192,
        }
      };

      print('Sending request to: $url');
      print('Request body size: ${jsonEncode(requestBody).length} characters');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': GeminiConfig.apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final imageData = part['inlineData']['data'];
                final mimeType = part['inlineData']['mimeType'];

                print(
                    'Found image data: ${imageData.length} characters, mimeType: $mimeType');

                // Decode base64 image data
                final imageBytes = base64Decode(imageData);

                // Save the generated image
                final tempDir = Directory.systemTemp;
                final imageFile = File(
                    '${tempDir.path}/gemini_generated_${DateTime.now().millisecondsSinceEpoch}.jpg');

                await imageFile.writeAsBytes(imageBytes);
                print('Image saved successfully: ${imageFile.path}');
                return imageFile;
              }
            }
          }
        }

        // If no image was found, check for text response
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            final textParts = candidate['content']['parts']
                .where((part) => part['text'] != null)
                .map((part) => part['text'])
                .join(' ');

            if (textParts.isNotEmpty) {
              print('Gemini response: $textParts');
              throw Exception('Gemini did not generate an image: $textParts');
            }
          }
        }

        throw Exception('No image generated in response');
      } else {
        throw Exception(
            'API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in Gemini v1beta image generation: $e');
      throw Exception('Gemini v1beta processing failed: $e');
    }
  }
}
