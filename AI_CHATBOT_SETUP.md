# AI Chatbot Setup Instructions

## Setting up the Gemini API Key

1. **Get your Gemini API Key:**
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Click on "Create API Key"
   - Copy your API key

2. **Add the API key to the .env file:**
   - Open the `.env` file in the root directory of the project
   - Replace `your_gemini_api_key_here` with your actual API key:
     ```
     GEMINI_API_KEY=AIzaSy...your_actual_key_here
     ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## Features

- **AI-Powered Chatbot**: Powered by Google's Gemini Pro model
- **Food Donation Help**: Get information about food donation process
- **Waste Reduction Tips**: Learn how to reduce food waste
- **Platform Guidance**: Ask questions about using CrumbChain
- **Government Schemes**: Get info about food donation schemes and programs

## Usage

1. Navigate to the AI Chat page by clicking the "AI Chat" icon in the bottom navigation bar
2. Type your question in the text field
3. Press send or hit enter
4. The AI will respond with helpful information

## Troubleshooting

- **"API key not found" error**: Make sure you've added your API key to the .env file
- **Network errors**: Check your internet connection
- **Slow responses**: Gemini API might be experiencing high traffic, try again in a moment
