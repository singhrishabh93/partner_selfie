# FLASHOOT - Simple Image Processing App

A simplified Flutter app for uploading images and processing them with AI.

## Features

- **Simple Upload**: Upload an image from your device
- **AI Processing**: Process the image with AI (currently simulated)
- **Download**: Save the processed image to your device gallery

## How to Use

1. **Upload Image**: Tap the "Upload Image" button to select a photo from your gallery
2. **Process**: Tap "Process with AI" to start the AI processing (currently shows a progress indicator)
3. **Download**: Once processing is complete, tap "Download" to save the image to your gallery

## Technical Details

### Dependencies
- `flutter_bloc`: State management
- `image_picker`: Image selection from gallery
- `permission_handler`: Handle storage permissions
- `image_gallery_saver`: Save images to device gallery
- `google_generative_ai`: AI processing (ready for integration)

### Project Structure
```
lib/
├── main.dart                           # App entry point
└── presentation/
    ├── cubits/
    │   └── simple_upload_cubit.dart    # State management for upload/processing
    └── screens/
        └── simple_upload_screen.dart   # Main UI screen
```

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## AI Integration

The app is ready for AI integration. To connect with your AI service:

1. Update the `processImage()` method in `simple_upload_cubit.dart`
2. Replace the simulation with actual AI API calls
3. Handle the AI processing according to your specific prompt requirements

## Customization

- **Colors**: Update the color scheme in `simple_upload_screen.dart`
- **UI**: Modify the layout and styling as needed
- **AI Processing**: Integrate with your preferred AI service

## Requirements

- Flutter SDK
- Android/iOS device or emulator
- Storage permissions for saving images