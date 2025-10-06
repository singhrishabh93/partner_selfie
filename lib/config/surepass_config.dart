import 'package:flutter_dotenv/flutter_dotenv.dart';

class SurePassConfig {
  // SurePass eSign API Configuration (Sandbox Environment)
  static String get baseUrl =>
      dotenv.env['SUREPASS_BASE_URL'] ?? 'https://sandbox.surepass.io';

  // SurePass sandbox token for testing
  // Token expires: 2025-12-31 (auto-refresh as needed)
  static String get apiKey =>
      dotenv.env['SUREPASS_API_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc1OTQ4OTAxMywianRpIjoiM2Y0NWIyYWYtYjU5ZS00ZTYyLThhZmQtM2YxMGYzZmE2YTNkIiwidHlwZSI6ImFjY2VzcyIsImlkZW50aXR5IjoiZGV2LmtvbmNoYW1rb2RlQHN1cmVwYXNzLmlvIiwibmJmIjoxNzU5NDg5MDEzLCJleHAiOjE3NjA3ODUwMTMsImVtYWlsIjoia29uY2hhbWtvZGVAc3VyZXBhc3MuaW8iLCJ0ZW5hbnRfaWQiOiJtYWluIiwidXNlcl9jbGFpbXMiOnsic2NvcGVzIjpbInVzZXIiXX19.BOCbJX9mQw34EtdYTyFPMokoZTqu-w7_gTXuc5E6f1k';

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
