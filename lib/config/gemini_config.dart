import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  // Load API key from environment variables
  static String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    return key;
  }

  // Gemini model to use
  static String get model {
    return dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-image-preview';
  }

  // Image generation settings
  static int get imageWidth {
    return int.tryParse(dotenv.env['IMAGE_WIDTH'] ?? '1600') ?? 1600;
  }

  static int get imageHeight {
    return int.tryParse(dotenv.env['IMAGE_HEIGHT'] ?? '1200') ?? 1200;
  }

  static String get imageFormat {
    return dotenv.env['IMAGE_FORMAT'] ?? 'jpeg';
  }
}
