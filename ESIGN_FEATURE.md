# E-Signature Feature

This document describes the e-signature functionality added to the Partner Selfie app.

## Features

### 1. E-Signature Form
- **Name**: User's full name (required)
- **Email**: Valid email address (required)
- **Mobile Number**: 10-digit mobile number (required)
- **Place**: User's location (required)
- **Reason for E-sign**: Dropdown with options:
  - Agreement
  - Contract
  - Legal Document
  - NDA
  - Other
- **Aadhar Number**: 12-digit Aadhar number (required)

### 2. Form Validation
- All fields are validated for proper format
- Email validation with regex
- Mobile number length validation (10 digits)
- Aadhar number length validation (12 digits)
- Required field validation

### 3. E-Signature Process
1. User fills the form
2. Clicks "Proceed to E-Sign"
3. App authenticates with e-sign service
4. Generates e-sign token
5. Opens in-app browser for e-signature process
6. User completes e-signature
7. Shows success screen with download option

### 4. Success Screen
- Confirmation message
- Download button for signed document
- Option to return to home screen

## Technical Implementation

### Dependencies Added
- `webview_flutter`: For in-app browser
- `url_launcher`: For URL handling
- `path_provider`: For file system access
- `dio`: For HTTP requests

### API Integration
- **Authentication**: `POST /EsignServices/auth`
- **Generate Token**: `POST /EsignServices/generateEsignToken`
- **Download**: Direct download from signed document URL

### File Structure
```
lib/
├── services/
│   └── esign_service.dart          # API service for e-signature
├── presentation/
│   └── screens/
│       └── esign_form_screen.dart  # E-signature form and flow
```

## Usage

1. From the home screen, tap "E-Signature"
2. Fill in all required details
3. Tap "Proceed to E-Sign"
4. Complete the e-signature process in the in-app browser
5. Download the signed document from the success screen

## API Endpoints

### Authentication
```
POST https://esignuat.meon.co.in/EsignServices/auth
Content-Type: application/json

{
  "username": "shashankjWUe",
  "password": "APItest@123"
}
```

### Generate E-Sign Token
```
POST https://esignuat.meon.co.in/EsignServices/generateEsignToken
Authorization: Bearer {auth_token}
Content-Type: application/json

{
  "name": "User Name",
  "email": "user@example.com",
  "mobile": "9876543210",
  "aadhar": "123456789012",
  "reason": "Agreement",
  "place": "City Name"
}
```

## Error Handling

- Network errors are caught and displayed to user
- Form validation errors are shown inline
- Download errors are handled with user feedback
- Authentication failures are properly handled

## Future Enhancements

- Add support for multiple document types
- Implement document preview before signing
- Add signature verification
- Support for batch document signing
- Integration with cloud storage services
