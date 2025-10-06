import 'package:flutter_dotenv/flutter_dotenv.dart';

class SurePassConfig {
  // SurePass eSign API Configuration (Sandbox Environment)
  static String get baseUrl {
    final url = dotenv.env['SUREPASS_BASE_URL'];
    if (url == null) {
      throw Exception('SUREPASS_BASE_URL not found in environment variables');
    }
    return url;
  }

  // SurePass sandbox token for testing
  // Token expires: 2025-12-31 (auto-refresh as needed)
  static String get apiKey {
    final key = dotenv.env['SUREPASS_API_KEY'];
    if (key == null) {
      throw Exception('SUREPASS_API_KEY not found in environment variables');
    }
    return key;
  }

  // eSign Configuration
  static const String reason = 'Non Disclosure Agreement';
  static const bool skipOtp = true;
  static const bool acceptVirtualSign = true;
  static const bool allowDownload = true;
  static const bool trackLocation = true;

  // API Endpoints
  static const String initiateEndpoint = '/api/v1/esign/initialize';
  static const String statusEndpoint = '/api/v1/esign/status';
  static const String historyEndpoint = '/api/v1/esign/history';
}
