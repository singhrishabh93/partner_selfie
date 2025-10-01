# FLASHOOT - Setup Instructions

## Fixing the "FormatException: Unhandled Content format" Error

The error you're experiencing is caused by several configuration issues. Here's how to fix them:

## 1. Get Your Gemini API Key

1. **Visit Google AI Studio**: Go to [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
2. **Sign in** with your Google account
3. **Create API Key**: Click "Create API Key" button
4. **Copy the Key**: Copy the generated API key

## 2. Update Your API Key

1. **Open the config file**: Navigate to `lib/config/gemini_config.dart`
2. **Replace the placeholder**: Update the `apiKey` variable with your actual key:
   ```dart
   static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

## 3. Issues Fixed

✅ **Model Name**: Changed from `gemini-2.5-flash` to `gemini-1.5-flash` (valid model)
✅ **Image Encoding**: Fixed double encoding/decoding issue that caused format errors
✅ **Error Handling**: Added proper error handling for Gemini API responses
✅ **Safety Filters**: Added checks for content safety and recitation policies

## 4. Test the Fix

1. **Run the app**: `flutter run`
2. **Upload an image**: Select any image from your gallery
3. **Process with AI**: Tap "Process with AI" to test the fix
4. **Check the result**: The processed image should now work without format errors

## 5. Troubleshooting

If you still get errors:

- **API Key Error**: Make sure you've replaced the placeholder with your actual key
- **Network Issues**: Ensure you have internet connectivity
- **Processing Time**: AI processing can take 10-30 seconds depending on image size
- **Rate Limits**: Gemini has rate limits, so processing may take time

## 6. Important Notes

- **API Key Security**: Never commit your API key to version control
- **Costs**: Check Google's pricing for Gemini API usage
- **Model**: The app now uses `gemini-1.5-flash` for faster processing
- **Image Format**: The app now properly handles image encoding without double conversion

## 7. Next Steps

Once the API key is set up, your app should work without the FormatException error. The AI processing will now:
- Use the correct Gemini model
- Handle image encoding properly
- Provide better error messages
- Check for content safety issues
