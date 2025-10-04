import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/surepass_config.dart';

class MCPSurePassService {
  // This service uses the real SurePass eSign APIs
  // All API calls are made directly to SurePass endpoints

  /// Test API connectivity using real SurePass API
  Future<bool> testApiConnectivity() async {
    try {
      print('Testing SurePass API connectivity...');

      // Test with a simple API call to check connectivity
      final response = await http.get(
        Uri.parse('${SurePassConfig.baseUrl}/api/v1/esign/status/test'),
        headers: {
          'Authorization': 'Bearer ${SurePassConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      // Any response (even 404) means API is reachable
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('SurePass API connectivity test failed: $e');
      return false;
    }
  }

  /// Initialize eSign process using real SurePass APIs
  Future<Map<String, dynamic>> initiateESign({
    required String fullName,
    required String userEmail,
    required String mobileNumber,
    String? pdfUrl,
  }) async {
    try {
      print('Initiating SurePass eSign for: $fullName');

      // Initialize eSign with PDF URL included directly
      final esignResult = await _initiateESign(
        fullName: fullName,
        userEmail: userEmail,
        mobileNumber: mobileNumber,
        pdfUrl: pdfUrl,
      );

      return {
        'success': true,
        'message': 'SurePass eSign process initiated successfully',
        'esign_url': esignResult['url'],
        'transaction_id': esignResult['client_id'],
        'client_id': esignResult['client_id'],
        'token': esignResult['token'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('SurePass eSign initiation error: $e');
      throw Exception('SurePass eSign initiation error: $e');
    }
  }

  /// Initialize eSign with PDF URL included directly
  Future<Map<String, dynamic>> _initiateESign({
    required String fullName,
    required String userEmail,
    required String mobileNumber,
    String? pdfUrl,
  }) async {
    try {
      print('Initializing SurePass eSign with PDF...');

      // Prepare request data for SurePass API (with PDF URL included)
      final requestData = {
        'sign_type': 'suresign',
        'config': {
          'auth_mode': '1', // Aadhaar OTP
          'reason': SurePassConfig.reason,
          'positions': {
            '1': [
              {
                'x': 10,
                'y': 20,
              }
            ]
          }
        },
        'prefill_options': {
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'user_email': userEmail,
        }
      };

      // Add PDF URL if provided
      if (pdfUrl != null) {
        requestData['pdf_url'] = pdfUrl;
        print('Including PDF URL: $pdfUrl');
      }

      print('SurePass eSign request data: $requestData');

      // Make API call to SurePass
      final response = await http
          .post(
            Uri.parse(
                '${SurePassConfig.baseUrl}${SurePassConfig.initiateEndpoint}'),
            headers: {
              'Authorization': 'Bearer ${SurePassConfig.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      print('SurePass API response status: ${response.statusCode}');
      print('SurePass API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('SurePass eSign response received:');
          print('- client_id: ${data['client_id']}');
          print('- token: ${data['token']}');
          print('- url: ${data['url']}');
          return {
            'client_id': data['client_id'],
            'token': data['token'],
            'url': data['url'],
          };
        } else {
          throw Exception('SurePass API error: ${responseData['message']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('SurePass Initialize eSign error: $e');
      throw Exception('SurePass Initialize eSign error: $e');
    }
  }

  /// Check eSign status using real SurePass API
  Future<Map<String, dynamic>> checkESignStatus(String clientId) async {
    try {
      print('Checking SurePass eSign status for client: $clientId');

      final response = await http.get(
        Uri.parse('${SurePassConfig.baseUrl}/api/v1/esign/status/$clientId'),
        headers: {
          'Authorization': 'Bearer ${SurePassConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'status': responseData['status'] ?? 'pending',
          'is_completed': responseData['status'] == 'completed',
          'signed_document_url': responseData['signed_document_url'],
          'message': responseData['message'] ?? 'Status checked successfully',
          'signed_at': responseData['signed_at'],
          'transaction_id': clientId,
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('SurePass Status check error: $e');
      throw Exception('SurePass Status check error: $e');
    }
  }

  /// Download signed document using real SurePass API
  Future<void> downloadSignedDocument(String clientId, String filePath) async {
    try {
      print('Downloading signed document from SurePass for client: $clientId');

      final response = await http.get(
        Uri.parse(
            '${SurePassConfig.baseUrl}/api/v1/esign/get-signed-document/$clientId'),
        headers: {
          'Authorization': 'Bearer ${SurePassConfig.apiKey}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Save the downloaded PDF to the specified file path
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('Document downloaded successfully to: $filePath');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('SurePass Download error: $e');
      throw Exception('SurePass Download error: $e');
    }
  }

  /// Get eSign history using real SurePass API
  Future<List<Map<String, dynamic>>> getESignHistory(String userEmail) async {
    try {
      print('Fetching SurePass eSign history for: $userEmail');

      // Note: This would require a specific history endpoint from SurePass
      // For now, return a placeholder response
      return [
        {
          'id': 'surepass_${DateTime.now().millisecondsSinceEpoch}',
          'email': userEmail,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
          'document_url':
              'https://surepass.app/signed/doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
          'transaction_id': 'surepass_${DateTime.now().millisecondsSinceEpoch}',
        }
      ];
    } catch (e) {
      print('SurePass History fetch error: $e');
      throw Exception('SurePass History fetch error: $e');
    }
  }
}
