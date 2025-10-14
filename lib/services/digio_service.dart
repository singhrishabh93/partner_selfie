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
