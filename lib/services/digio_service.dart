import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/digio_config.dart';

class DigioService {
  /// Create a sign request using DIGIO API
  Future<Map<String, dynamic>> createSignRequest({
    required String fullName,
    required String email,
    required String fathersName,
    required String address,
    required String aadhaarNumber,
  }) async {
    try {
      print('Creating DIGIO sign request for: $fullName');

      // Get current date in DD/MM/YY format
      final now = DateTime.now();
      final currentDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)}';

      final requestData = {
        "signers": [
          {"identifier": email, "name": fullName, "sign_type": "aadhaar"}
        ],
        "expire_in_days": DigioConfig.expireInDays,
        "generate_access_token": DigioConfig.generateAccessToken,
        "send_sign_link": DigioConfig.sendSignLink,
        "notify_signers": DigioConfig.notifySigners,
        "display_on_page": DigioConfig.displayOnPage,
        "templates": [
          {
            "template_key": DigioConfig.templateKey,
            "template_values": {
              "current_date": currentDate,
              "permanent_address": address,
              "parent_name": fathersName,
              "full_name": fullName,
              "aadhaar_number": aadhaarNumber,
              "sign_name": fullName
            }
          }
        ],
        "estamp_request": {
          "tags": {"TS-100-Sample": "1"},
          "sign_on_page": "ALL",
          "note_content": "This is dummy content",
          "note_on_page": "ALL"
        }
      };

      print('DIGIO sign request data: $requestData');

      final response = await http
          .post(
            Uri.parse(
                '${DigioConfig.baseUrl}${DigioConfig.createSignRequestEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Basic ${DigioConfig.authToken}',
            },
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      print('DIGIO API response status: ${response.statusCode}');
      print('DIGIO API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract entity_id and access_token from response
        final entityId = responseData['id'];
        final accessToken = responseData['access_token'];

        if (entityId != null && accessToken != null) {
          // Construct the signing URL
          final signingUrl =
              '${DigioConfig.gatewayBaseUrl}/#/gateway/login/$entityId/TMP25/$email?redirect_url=${DigioConfig.redirectUrl}&token_id=${accessToken['id']}';

          return {
            'success': true,
            'message': 'DIGIO sign request created successfully',
            'entity_id': entityId,
            'access_token': accessToken['id'],
            'signing_url': signingUrl,
            'expire_on': responseData['signing_parties']?[0]?['expire_on'],
            'created_at': responseData['created_at'],
          };
        } else {
          throw Exception('Invalid response format from DIGIO API');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('DIGIO sign request error: $e');
      throw Exception('DIGIO sign request error: $e');
    }
  }

  /// Check document status using DIGIO API
  Future<Map<String, dynamic>> checkDocumentStatus(String documentId) async {
    try {
      print('Checking DIGIO document status for: $documentId');

      final response = await http.get(
        Uri.parse(
            '${DigioConfig.baseUrl}/document/$documentId?name_validation=true'),
        headers: {
          'Authorization': 'Basic ${DigioConfig.authToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('DIGIO document status response: ${response.statusCode}');
      print('DIGIO document status body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'document_id': responseData['id'],
          'agreement_status': responseData['agreement_status'],
          'is_completed': responseData['agreement_status'] == 'completed',
          'file_name': responseData['file_name'],
          'created_at': responseData['created_at'],
          'updated_at': responseData['updated_at'],
          'signing_parties': responseData['signing_parties'],
          'data': responseData,
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('DIGIO document status error: $e');
      throw Exception('DIGIO document status error: $e');
    }
  }

  /// Download completed document using DIGIO API
  Future<Map<String, dynamic>> downloadDocument(String documentId) async {
    try {
      print('Downloading DIGIO document: $documentId');

      final response = await http.get(
        Uri.parse(
            '${DigioConfig.baseUrl}/document/download?document_id=$documentId'),
        headers: {
          'Authorization': 'Basic ${DigioConfig.authToken}',
        },
      ).timeout(const Duration(seconds: 60));

      print('DIGIO download response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'document_id': documentId,
          'file_data': response.bodyBytes,
          'content_type': response.headers['content-type'] ?? 'application/pdf',
          'message': 'Document downloaded successfully',
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('DIGIO download error: $e');
      throw Exception('DIGIO download error: $e');
    }
  }

  /// Handle callback URL - extract document ID and check status
  Future<Map<String, dynamic>> handleCallback(String callbackUrl) async {
    try {
      print('Handling DIGIO callback: $callbackUrl');

      // Extract document ID from callback URL
      // Expected format: https://yourapp.com/success?status=success&digio_doc_id=DID25101417390475853KNLTXZETV71U&message=Signed%20Successfully
      final uri = Uri.parse(callbackUrl);
      final documentId = uri.queryParameters['digio_doc_id'];
      final status = uri.queryParameters['status'];
      final message = uri.queryParameters['message'];

      if (documentId == null) {
        throw Exception('Document ID not found in callback URL');
      }

      print('Extracted document ID: $documentId');
      print('Status: $status, Message: $message');

      // Check if status indicates success
      if (status == 'success') {
        // Document is completed, download it
        print('Document is completed, downloading...');
        final downloadResult = await downloadDocument(documentId);

        return {
          'success': true,
          'status': 'completed',
          'document_id': documentId,
          'agreement_status': 'completed',
          'download_result': downloadResult,
          'message':
              message ?? 'Document completed and downloaded successfully',
        };
      } else {
        // Document not completed yet
        return {
          'success': true,
          'status': 'pending',
          'document_id': documentId,
          'agreement_status': status ?? 'unknown',
          'message': message ?? 'Document is not completed yet',
        };
      }
    } catch (e) {
      print('DIGIO callback handling error: $e');
      throw Exception('DIGIO callback handling error: $e');
    }
  }

  /// Test API connectivity
  Future<bool> testApiConnectivity() async {
    try {
      print('Testing DIGIO API connectivity...');

      // Simple test request to check if API is reachable
      final response = await http.get(
        Uri.parse('${DigioConfig.baseUrl}/health'),
        headers: {
          'Authorization': 'Basic ${DigioConfig.authToken}',
        },
      ).timeout(const Duration(seconds: 10));

      // Any response means API is reachable
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('DIGIO API connectivity test failed: $e');
      return false;
    }
  }
}
