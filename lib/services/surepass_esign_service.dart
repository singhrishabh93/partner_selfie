import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

class SurePassESignService {
  final Dio _dio = Dio();

  // SurePass eSign API Configuration
  static const String _baseUrl = 'https://kyc-api.surepass.app';
  static const String _apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc1OTQ4OTAxMywianRpIjoiM2Y0NWIyYWYtYjU5ZS00ZTYyLThhZmQtM2YxMGYzZmE2YTNkIiwidHlwZSI6ImFjY2VzcyIsImlkZW50aXR5IjoiZGV2LmtvbmNoYW1rb2RlQHN1cmVwYXNzLmlvIiwibmJmIjoxNzU5NDg5MDEzLCJleHAiOjE3NjA3ODUwMTMsImVtYWlsIjoia29uY2hhbWtvZGVAc3VyZXBhc3MuaW8iLCJ0ZW5hbnRfaWQiOiJtYWluIiwidXNlcl9jbGFpbXMiOnsic2NvcGVzIjpbInVzZXIiXX19.BOCbJX9mQw34EtdYTyFPMokoZTqu-w7_gTXuc5E6f1k';

  /// Test API connectivity
  Future<bool> testApiConnectivity() async {
    try {
      print('Testing SurePass API connectivity...');
      print('Base URL: $_baseUrl');
      print('Token (first 20 chars): ${_apiKey.substring(0, 20)}...');

      final response = await _dio.get(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Accept': 'application/json',
          },
        ),
      );

      print('Connectivity test response: ${response.statusCode}');
      print('Connectivity test data: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print('Connectivity test failed: $e');
      if (e.toString().contains('401')) {
        print('⚠️ 401 Unauthorized - Token might be invalid or expired');
      }
      return false;
    }
  }

  /// Initialize eSign process with PDF upload
  Future<Map<String, dynamic>> initiateESign({
    required String fullName,
    required String userEmail,
    required String mobileNumber,
  }) async {
    try {
      print('Initiating SurePass eSign for: $fullName');

      // Step 1: Upload PDF and get upload link
      final uploadLink = await _getUploadLink();
      print('Got upload link: $uploadLink');

      // Step 2: Upload PDF file
      final pdfUrl = await _uploadPDF(uploadLink);
      print('PDF uploaded to: $pdfUrl');

      // Step 3: Initialize eSign with uploaded PDF
      final esignUrl = await _initializeESign(
        fullName: fullName,
        userEmail: userEmail,
        mobileNumber: mobileNumber,
        pdfUrl: pdfUrl,
      );

      return {
        'success': true,
        'message': 'SurePass eSign process initiated successfully',
        'esign_url': esignUrl,
        'transaction_id': 'sp_${DateTime.now().millisecondsSinceEpoch}',
        'client_id': 'sp_client_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('SurePass eSign initiation error: $e');
      throw Exception('SurePass eSign initiation error: $e');
    }
  }

  /// Get upload link for PDF
  Future<String> _getUploadLink() async {
    try {
      print('Getting SurePass upload link...');

      final response = await _dio.post(
        '$_baseUrl/api/v1/esign/get-upload-link',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Upload link response: ${response.statusCode}');
      print('Upload link data: ${response.data}');

      if (response.statusCode == 200) {
        final uploadUrl = response.data['upload_url'] ?? response.data['url'];
        if (uploadUrl != null) {
          print('Upload link received: $uploadUrl');
          return uploadUrl;
        } else {
          throw Exception('No upload URL in response');
        }
      } else {
        throw Exception('Failed to get upload link: ${response.statusCode}');
      }
    } catch (e) {
      print('Get upload link error: $e');
      throw Exception('Get upload link error: $e');
    }
  }

  /// Upload PDF file
  Future<String> _uploadPDF(String uploadUrl) async {
    try {
      print('Uploading PDF to SurePass...');

      // Load the dummy PDF file from assets
      final pdfBytes = await rootBundle.load('assets/dummy-pdf_2.pdf');
      final pdfData = pdfBytes.buffer.asUint8List();
      print('Loaded PDF file, size: ${pdfData.length} bytes');

      // Upload PDF to SurePass
      final response = await _dio.post(
        uploadUrl,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            pdfData,
            filename: 'dummy-pdf_2.pdf',
            contentType: DioMediaType('application', 'pdf'),
          ),
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      print('PDF upload response: ${response.statusCode}');
      print('PDF upload data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final pdfUrl = response.data['url'] ?? response.data['file_url'];
        if (pdfUrl != null) {
          print('PDF uploaded successfully: $pdfUrl');
          return pdfUrl;
        } else {
          throw Exception('No PDF URL in upload response');
        }
      } else {
        throw Exception('Failed to upload PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('PDF upload error: $e');
      throw Exception('PDF upload error: $e');
    }
  }

  /// Initialize eSign with uploaded PDF
  Future<String> _initializeESign({
    required String fullName,
    required String userEmail,
    required String mobileNumber,
    required String pdfUrl,
  }) async {
    try {
      print('Initializing SurePass eSign with PDF...');

      final requestData = {
        'pdf_pre_uploaded': true,
        'pdf_url': pdfUrl,
        'callback_url': 'https://example.com?state=test',
        'config': {
          'accept_selfie': true,
          'allow_selfie_upload': true,
          'accept_virtual_sign': true,
          'track_location': true,
          'auth_mode': '1',
          'reason': 'Non Disclosure Agreement',
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

      print('SurePass eSign request data: $requestData');

      final response = await _dio.post(
        '$_baseUrl/api/v1/esign/initialize',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('eSign initialize response: ${response.statusCode}');
      print('eSign initialize data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final esignUrl = response.data['esign_url'] ?? response.data['url'];
        if (esignUrl != null) {
          print('eSign URL received: $esignUrl');
          return esignUrl;
        } else {
          throw Exception('No eSign URL in response');
        }
      } else {
        throw Exception('Failed to initialize eSign: ${response.statusCode}');
      }
    } catch (e) {
      print('Initialize eSign error: $e');
      throw Exception('Initialize eSign error: $e');
    }
  }

  /// Check eSign status
  Future<Map<String, dynamic>> checkESignStatus(String transactionId) async {
    try {
      print('Checking SurePass eSign status for transaction: $transactionId');

      final response = await _dio.get(
        '$_baseUrl/api/v1/esign/status/$transactionId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      print('Status check response: ${response.statusCode}');
      print('Status check data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': response.data['status'] ?? 'completed',
          'is_completed': response.data['is_completed'] ?? true,
          'signed_document_url': response.data['signed_document_url'],
          'message': 'Document status checked successfully',
          'signed_at': response.data['signed_at'],
          'transaction_id': transactionId,
        };
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      print('SurePass Status check error: $e');
      throw Exception('SurePass Status check error: $e');
    }
  }

  /// Download signed document
  Future<void> downloadSignedDocument(
      String documentUrl, String filePath) async {
    try {
      print('Downloading signed document from SurePass: $documentUrl');

      final response = await _dio.get(
        documentUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        // Save the downloaded file
        final file = File(filePath);
        await file.writeAsBytes(response.data);
        print('Document downloaded successfully to: $filePath');
      } else {
        throw Exception('Failed to download document: ${response.statusCode}');
      }
    } catch (e) {
      print('SurePass Download error: $e');
      throw Exception('SurePass Download error: $e');
    }
  }

  /// Get eSign history
  Future<List<Map<String, dynamic>>> getESignHistory(String userEmail) async {
    try {
      print('Fetching SurePass eSign history for: $userEmail');

      final response = await _dio.get(
        '$_baseUrl/api/v1/esign/history',
        queryParameters: {'email': userEmail},
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      print('History response: ${response.statusCode}');
      print('History data: ${response.data}');

      if (response.statusCode == 200) {
        final history = response.data['history'] ?? response.data;
        if (history is List) {
          return List<Map<String, dynamic>>.from(history);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      print('SurePass History fetch error: $e');
      throw Exception('SurePass History fetch error: $e');
    }
  }
}
