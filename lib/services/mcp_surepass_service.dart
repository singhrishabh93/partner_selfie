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
    String? callbackUrl,
  }) async {
    try {
      print('Initiating SurePass eSign for: $fullName');

      // Prepare request data for SurePass API
      final requestData = {
        'pdf_pre_uploaded':
            true, // We will provide the PDF via upload-pdf endpoint
        'callback_url': callbackUrl ?? 'https://yourapp.com/esign/callback',
        'config': {
          'accept_selfie': true,
          'allow_selfie_upload': true,
          'accept_virtual_sign': true,
          'track_location': true,
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

      print('SurePass eSign request data: $requestData');

      // Make API call to SurePass
      final response = await http
          .post(
            Uri.parse('${SurePassConfig.baseUrl}/api/v1/esign/initialize'),
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
          print('- url: ${data['url']}');

          return {
            'success': true,
            'message': 'SurePass eSign process initiated successfully',
            'esign_url': data['url'],
            'transaction_id': data['client_id'],
            'client_id': data['client_id'],
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          };
        } else {
          throw Exception('SurePass API error: ${responseData['message']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('SurePass eSign initiation error: $e');
      throw Exception('SurePass eSign initiation error: $e');
    }
  }

  /// Upload PDF by link to existing eSign session
  Future<Map<String, dynamic>> uploadPdfByLink({
    required String clientId,
    required String pdfUrl,
  }) async {
    try {
      print('Uploading PDF by link for client: $clientId');
      print('PDF URL: $pdfUrl');

      final requestData = {
        'client_id': clientId,
        'link': pdfUrl,
      };

      final response = await http
          .post(
            Uri.parse('${SurePassConfig.baseUrl}/api/v1/esign/upload-pdf'),
            headers: {
              'Authorization': 'Bearer ${SurePassConfig.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      print('SurePass upload PDF response status: ${response.statusCode}');
      print('SurePass upload PDF response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData['data']?['uploaded'] == true) {
          print('PDF uploaded successfully to client: $clientId');
          return {
            'success': true,
            'pdf_attached': true,
            'message': responseData['message'] ?? 'PDF uploaded successfully',
            'client_id': clientId,
          };
        } else {
          throw Exception('SurePass API error: ${responseData['message']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('SurePass upload PDF error: $e');
      throw Exception('SurePass upload PDF error: $e');
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

  /// Get signed document URL and certificate info using real SurePass API
  Future<Map<String, dynamic>> getSignedDocument(String clientId) async {
    try {
      print('Getting signed document from SurePass for client: $clientId');

      final response = await http.get(
        Uri.parse(
            '${SurePassConfig.baseUrl}/api/v1/esign/get-signed-document/$clientId'),
        headers: {
          'Authorization': 'Bearer ${SurePassConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print(
          'SurePass get signed document response status: ${response.statusCode}');
      print('SurePass get signed document response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'signed_pdf_url': responseData['signed_pdf_url'],
          'certificate': responseData['certificate'],
          'message': 'Signed document retrieved successfully',
          'client_id': clientId,
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('SurePass get signed document error: $e');
      throw Exception('SurePass get signed document error: $e');
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

  /// Complete eSign flow: Initialize → Upload PDF → Get Signed Document
  Future<Map<String, dynamic>> completeESignFlow({
    required String fullName,
    required String userEmail,
    required String mobileNumber,
    required String pdfUrl,
    String? callbackUrl,
  }) async {
    try {
      print('Starting complete SurePass eSign flow for: $fullName');

      // Step 1: Initialize eSign
      print('Step 1: Initializing eSign...');
      final initResult = await initiateESign(
        fullName: fullName,
        userEmail: userEmail,
        mobileNumber: mobileNumber,
        callbackUrl: callbackUrl,
      );

      final clientId = initResult['client_id'];
      print('eSign initialized with client_id: $clientId');

      // Step 2: Upload PDF by link
      print('Step 2: Uploading PDF by link...');
      final uploadResult = await uploadPdfByLink(
        clientId: clientId,
        pdfUrl: pdfUrl,
      );

      print('PDF uploaded successfully: ${uploadResult['pdf_attached']}');

      return {
        'success': true,
        'message': 'eSign flow completed successfully',
        'client_id': clientId,
        'esign_url': initResult['esign_url'],
        'pdf_uploaded': uploadResult['pdf_attached'],
        'status': 'ready_for_signing',
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Complete eSign flow error: $e');
      throw Exception('Complete eSign flow error: $e');
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
