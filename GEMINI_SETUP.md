# Gemini AI Setup Guide

## Getting Your Gemini API Key

1. **Visit Google AI Studio**: Go to [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)

2. **Sign in**: Use your Google account to sign in

3. **Create API Key**: Click "Create API Key" button

4. **Copy the Key**: Copy the generated API key

## Setting Up the API Key in the App

1. **Create .env file**: In the root directory of your project, create a file named `.env`

2. **Add your API key**: Add the following content to the `.env` file:
   ```
   # Gemini AI Configuration
   # Get your API key from: https://makersuite.google.com/app/apikey
   GEMINI_API_KEY=your_actual_api_key_here
   
   # Optional: Gemini model configuration
   GEMINI_MODEL=gemini-2.5-flash-image-preview
   
   # Optional: Image generation settings
   IMAGE_WIDTH=1600
   IMAGE_HEIGHT=1200
   IMAGE_FORMAT=jpeg
   ```

3. **Replace the placeholder**: Replace `your_actual_api_key_here` with your actual Gemini API key

4. **Save the file**: The app will now use your API key for Gemini AI processing

## Testing the Integration

1. **Run the app**: `flutter run`

2. **Upload an image**: Select any image from your gallery

3. **Process with AI**: Tap "Process with AI" to see Gemini in action

4. **Check the result**: The processed image will be different from the original

## Important Notes

- **API Key Security**: Never commit your API key to version control
- **Rate Limits**: Gemini has rate limits, so processing may take time
- **Costs**: Check Google's pricing for Gemini API usage
- **Model**: The app uses `gemini-1.5-flash` for faster processing

## Troubleshooting

- **API Key Error**: Make sure you've replaced the placeholder with your actual key
- **Network Issues**: Ensure you have internet connectivity
- **Processing Time**: AI processing can take 10-30 seconds depending on image size

## Customization

You can modify the AI prompt in `lib/presentation/cubits/simple_upload_cubit.dart` to change how images are processed.
