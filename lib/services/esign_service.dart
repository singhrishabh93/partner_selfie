import 'package:dio/dio.dart';
import '../config/surepass_config.dart';

class ESignService {
  final Dio _dio = Dio();

  /// Test API connectivity
  Future<bool> testApiConnectivity() async {
    try {
      print('Testing API connectivity...');
      print('Base URL: ${SurePassConfig.baseUrl}');
      print(
          'Token (first 20 chars): ${SurePassConfig.apiKey.substring(0, 20)}...');

      // Try a simple GET request to test connectivity
      final response = await _dio.get(
        SurePassConfig.baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${SurePassConfig.apiKey}',
            'Accept': 'application/json',
          },
        ),
      );

      print('Connectivity test response: ${response.statusCode}');
      print('Connectivity test data: ${response.data}');
      return response.statusCode == 200 ||
          response.statusCode == 404; // 404 is OK, means server is reachable
    } catch (e) {
      print('Connectivity test failed: $e');
      if (e.toString().contains('401')) {
        print('⚠️ 401 Unauthorized - Token might be invalid or expired');
      }
      return false;
    }
  }

  /// Initialize eSign process with SurePass API
  Future<Map<String, dynamic>> initiateESign({
    required String fullName,
    required String userEmail,
    required String mobileNumber,
  }) async {
    try {
      print('Initiating SurePass eSign for: $fullName');
      print('Using base URL: ${SurePassConfig.baseUrl}');
      print(
          'Full endpoint: ${SurePassConfig.baseUrl}${SurePassConfig.initiateEndpoint}');

      final requestData = {
        'pdf_pre_uploaded': false,
        'callback_url': 'https://example.com?state=test',
        'config': {
          'accept_selfie': true,
          'allow_selfie_upload': true,
          'accept_virtual_sign': SurePassConfig.acceptVirtualSign,
          'track_location': SurePassConfig.trackLocation,
          'auth_mode': '1',
          'reason': SurePassConfig.reason,
          'positions': {
            '1': [
              {
                'x': 10,
                'y': 20,
              }
            ]
          },
          'stamp_paper_amount': 100,
          'stamp_paper_state': 'Maharashtra',
          'stamp_data': {
            'Name': fullName,
            'Email': userEmail,
            'Mobile': mobileNumber,
          }
        },
        'prefill_options': {
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'user_email': userEmail,
        }
      };

      print('Request data: $requestData');
      print(
          'Authorization header: Bearer ${SurePassConfig.apiKey.substring(0, 20)}...');

      // Validate required fields
      if (fullName.isEmpty || userEmail.isEmpty || mobileNumber.isEmpty) {
        throw Exception(
            'Missing required fields: fullName, userEmail, or mobileNumber');
      }

      print('✅ All required fields present');
      print('Full Name: $fullName');
      print('Email: $userEmail');
      print('Mobile: $mobileNumber');

      // Add timeout and connection settings
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);
      _dio.options.sendTimeout = const Duration(seconds: 30);

      final response = await _dio.post(
        '${SurePassConfig.baseUrl}${SurePassConfig.initiateEndpoint}',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${SurePassConfig.apiKey}',
            'Accept': 'application/json',
          },
        ),
      );

      print('SurePass eSign response status: ${response.statusCode}');
      print('SurePass eSign response data: ${response.data}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true || data['status'] == 'success') {
          print('SurePass eSign initiated successfully');
          return {
            'success': true,
            'esign_url':
                data['esign_url'] ?? data['url'] ?? data['redirect_url'],
            'transaction_id':
                data['transaction_id'] ?? data['id'] ?? data['request_id'],
            'message':
                data['message'] ?? 'eSign process initiated successfully',
          };
        } else {
          throw Exception(
              'eSign initiation failed: ${data['message'] ?? data['error'] ?? 'Unknown error'}');
        }
      } else {
        // Log detailed error information
        print('API Error Details:');
        print('- Status Code: ${response.statusCode}');
        print('- Response Data: ${response.data}');
        print('- Response Headers: ${response.headers}');

        String errorMessage =
            'Failed to initiate eSign: ${response.statusCode}';
        if (response.data != null) {
          if (response.data is Map) {
            final errorData = response.data as Map;
            if (errorData.containsKey('message')) {
              errorMessage += ' - ${errorData['message']}';
            } else if (errorData.containsKey('error')) {
              errorMessage += ' - ${errorData['error']}';
            } else {
              errorMessage += ' - ${response.data}';
            }
          } else {
            errorMessage += ' - ${response.data}';
          }
        }

        // Add specific 401 error handling
        if (response.statusCode == 401) {
          errorMessage +=
              '\n\n🔑 Authentication Error: This could be due to:\n';
          errorMessage += '• Invalid or expired token\n';
          errorMessage += '• Incorrect API endpoint\n';
          errorMessage += '• Missing required permissions\n';
          errorMessage += '• Wrong authentication method';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('SurePass eSign initiation error: $e');

      // If it's a connection error, try alternative endpoints
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('connection error')) {
        print('Connection error detected, trying alternative endpoints...');

        // Recreate request data for fallback attempts
        final fallbackRequestData = {
          'pdf_pre_uploaded': false,
          'callback_url': 'https://example.com?state=test',
          'config': {
            'accept_selfie': true,
            'allow_selfie_upload': true,
            'accept_virtual_sign': SurePassConfig.acceptVirtualSign,
            'track_location': SurePassConfig.trackLocation,
            'auth_mode': '1',
            'reason': SurePassConfig.reason,
            'positions': {
              '1': [
                {
                  'x': 10,
                  'y': 20,
                }
              ]
            },
            'stamp_paper_amount': 100,
            'stamp_paper_state': 'Maharashtra',
            'stamp_data': {
              'Name': fullName,
              'Email': userEmail,
              'Mobile': mobileNumber,
            }
          },
          'prefill_options': {
            'full_name': fullName,
            'mobile_number': mobileNumber,
            'user_email': userEmail,
          }
        };

        // Try alternative base URLs
        final alternativeUrls = [
          'https://kyc-api.surepass.app',
          'https://kyc-api.surepass.app/api/v1',
          'https://kyc-api.surepass.app/v1',
        ];

        for (final altUrl in alternativeUrls) {
          try {
            print('Trying alternative URL: $altUrl');
            final response = await _dio.post(
              '$altUrl${SurePassConfig.initiateEndpoint}',
              data: fallbackRequestData,
              options: Options(
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${SurePassConfig.apiKey}',
                  'Accept': 'application/json',
                },
              ),
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              final data = response.data;
              if (data['success'] == true) {
                print('Alternative URL successful: $altUrl');
                return {
                  'success': true,
                  'esign_url': data['esign_url'],
                  'transaction_id': data['transaction_id'],
                  'message':
                      data['message'] ?? 'eSign process initiated successfully',
                };
              }
            }
          } catch (altError) {
            print('Alternative URL $altUrl also failed: $altError');
            continue;
          }
        }
      }

      throw Exception('eSign initiation error: $e');
    }
  }

  /// Check eSign status
  Future<Map<String, dynamic>> checkESignStatus(String transactionId) async {
    try {
      print('Checking eSign status for transaction: $transactionId');

      final response = await _dio.get(
        '${SurePassConfig.baseUrl}${SurePassConfig.statusEndpoint}/$transactionId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${SurePassConfig.apiKey}',
            'Accept': 'application/json',
          },
        ),
      );

      print('Status check response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'status': data['status'],
          'is_completed': data['is_completed'] ?? false,
          'signed_document_url': data['signed_document_url'],
          'message': data['message'],
        };
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      print('Status check error: $e');
      throw Exception('Status check error: $e');
    }
  }

  /// Download signed document
  Future<void> downloadSignedDocument(
      String documentUrl, String filePath) async {
    try {
      print('Downloading signed document from: $documentUrl');
      await _dio.download(documentUrl, filePath);
      print('Document downloaded successfully to: $filePath');
    } catch (e) {
      print('Download error: $e');
      throw Exception('Download error: $e');
    }
  }

  /// Get eSign history for user
  Future<List<Map<String, dynamic>>> getESignHistory(String userEmail) async {
    try {
      print('Fetching eSign history for: $userEmail');

      final response = await _dio.get(
        '${SurePassConfig.baseUrl}${SurePassConfig.historyEndpoint}',
        queryParameters: {'user_email': userEmail},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${SurePassConfig.apiKey}',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      print('History fetch error: $e');
      throw Exception('History fetch error: $e');
    }
  }
}
