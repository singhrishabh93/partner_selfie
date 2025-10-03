# SurePass eSign Integration

This document describes the SurePass eSign integration that has been implemented to replace the previous Meon eSign service.

## Overview

The SurePass eSign integration allows users to digitally sign documents with the following features:
- **Skip OTP**: Bypass OTP verification for faster signing
- **Accept Virtual Sign**: Allow virtual signatures
- **Allow Download**: Enable document download after signing
- **Track Location**: Track user location during signing process

## Configuration

### API Configuration
The SurePass API configuration is managed in `lib/config/surepass_config.dart`:

```dart
class SurePassConfig {
  static const String baseUrl = 'https://api.surepass.io/api/v1';
  static const String apiKey = 'YOUR_SUREPASS_API_KEY';
  
  // eSign Configuration
  static const String reason = 'Non Disclosure Agreement';
  static const bool skipOtp = true;
  static const bool acceptVirtualSign = true;
  static const bool allowDownload = true;
  static const bool trackLocation = true;
}
```

### Required Setup
1. **✅ SurePass Sandbox Token**: Already configured with sandbox token for testing
2. **✅ Configuration**: Token is set up in `lib/config/surepass_config.dart`
3. **✅ Test Integration**: Ready for testing in sandbox environment

## User Flow

### 1. Form Input
Users need to provide:
- **Full Name**: Complete name of the signer
- **User Email**: Email address for notifications and verification
- **Mobile Number**: 10-digit mobile number for contact

### 2. eSign Process
1. User fills the form with required details
2. System initiates SurePass eSign process
3. User is redirected to SurePass signing interface
4. User completes the digital signature
5. System receives confirmation and shows success message

### 3. Success Handling
- Success message is displayed upon completion
- Signed document can be downloaded
- Transaction ID is stored for reference

## API Endpoints

### Initiate eSign
- **Endpoint**: `POST /esign/initiate`
- **Purpose**: Start the eSign process
- **Parameters**:
  - `full_name`: User's full name
  - `user_email`: User's email address
  - `mobile_number`: User's mobile number
  - `reason`: "Non Disclosure Agreement"
  - `skip_otp`: true
  - `accept_virtual_sign`: true
  - `allow_download`: true
  - `track_location`: true

### Check Status
- **Endpoint**: `GET /esign/status/{transaction_id}`
- **Purpose**: Check the status of an eSign transaction

### Get History
- **Endpoint**: `GET /esign/history`
- **Purpose**: Retrieve eSign history for a user

## Implementation Details

### Service Layer
The `ESignService` class handles all SurePass API interactions:
- `initiateESign()`: Start the eSign process
- `checkESignStatus()`: Check transaction status
- `downloadSignedDocument()`: Download completed documents
- `getESignHistory()`: Retrieve user's eSign history

### UI Components
- **ESignFormScreen**: Form for user input
- **EsignWebViewScreen**: WebView for signing process
- **EsignSuccessScreen**: Success confirmation and download

## Security Considerations

1. **API Key Security**: Store API keys securely, never commit them to version control
2. **Data Validation**: Validate all user inputs before sending to API
3. **Error Handling**: Implement proper error handling for API failures
4. **User Privacy**: Ensure user data is handled according to privacy regulations

## Testing

### Test Scenarios
1. **Valid Input**: Test with valid user details
2. **Invalid Email**: Test with invalid email format
3. **Invalid Mobile**: Test with invalid mobile number
4. **Network Errors**: Test with network connectivity issues
5. **API Failures**: Test with invalid API responses

### Test Data
Use the "Fill My Data" button for quick testing with pre-filled valid data.

## Troubleshooting

### Common Issues
1. **API Key Invalid**: Ensure the correct API key is configured
2. **Network Timeout**: Check internet connectivity
3. **Invalid Parameters**: Verify all required fields are provided
4. **WebView Issues**: Ensure WebView permissions are granted

### Debug Information
The service includes comprehensive logging for debugging:
- Request data logging
- Response status and data logging
- Error message logging

## Migration from Meon

The integration has been completely migrated from Meon to SurePass:
- ✅ Removed Meon-specific authentication
- ✅ Updated API endpoints to SurePass
- ✅ Simplified form fields (removed unnecessary fields)
- ✅ Updated success handling
- ✅ Maintained existing UI/UX flow

## Support

For SurePass API support, refer to the official SurePass documentation or contact their support team.
