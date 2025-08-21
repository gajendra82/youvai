# Google Sign-In Setup Guide

## Overview
This guide explains how to set up Google Sign-In for the YouVai Flutter application using the `google_sign_in` package.

## Changes Made

### 1. **Added Dependencies**
- Added `google_sign_in: ^6.2.1` to `pubspec.yaml`

### 2. **Created Google Sign-In Service**
- Created `lib/services/google_sign_in_service.dart`
- Centralized Google Sign-In functionality
- Handles both web and mobile platforms

### 3. **Updated Web Configuration**
- Added Google Sign-In client ID to `web/index.html`
- Client ID: `377693730311-24dfc047db461c18c3dca2.apps.googleusercontent.com`

### 4. **Updated Android Configuration**
- Added Google Services plugin to `android/app/build.gradle`
- Added Firebase dependencies
- Updated project-level `android/build.gradle`

### 5. **Updated Sign-In Button**
- Modified `lib/screens/guest/onboard_screen.dart`
- Now uses `GoogleSignInService` instead of Firebase Auth popup
- Better error handling and user feedback

## Required Configuration

### Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `youvai-56995`
3. Go to Authentication → Sign-in method
4. Enable Google Sign-In
5. Add your domain to authorized domains

### Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to APIs & Services → Credentials
4. Create OAuth 2.0 Client ID for web
5. Add authorized JavaScript origins:
   - `https://aesthetic.youv.ai`
   - `http://localhost:3000` (for development)
6. Add authorized redirect URIs:
   - `https://aesthetic.youv.ai/__/auth/handler`
   - `http://localhost:3000/__/auth/handler` (for development)

### Android Configuration
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Ensure your package name matches: `com.globalspace.youvai`

### iOS Configuration (if needed)
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`
3. Add it to your Xcode project

## Testing

### Web Testing
1. Run `flutter build web`
2. Deploy to your server
3. Test Google Sign-In at: `https://aesthetic.youv.ai/#/onboard`

### Mobile Testing
1. Run `flutter run` on Android/iOS device
2. Test Google Sign-In functionality

## Troubleshooting

### Common Issues

1. **"Sign in failed: PlatformException"**
   - Check if Google Sign-In is enabled in Firebase Console
   - Verify client ID configuration
   - Check domain authorization

2. **"Google Sign-In not available"**
   - Ensure `google-services.json` is properly placed
   - Check Android configuration
   - Verify package name matches

3. **Web Sign-In Issues**
   - Check browser console for errors
   - Verify authorized domains in Firebase Console
   - Check OAuth client configuration

### Debug Steps
1. Check browser console for error messages
2. Verify Firebase initialization
3. Test with the debug page: `web/firebase-test.html`
4. Check network requests in browser dev tools

## Benefits of Using google_sign_in Package

1. **Better Platform Support**: Native implementation for each platform
2. **Improved Reliability**: More stable than Firebase Auth popup
3. **Better UX**: Native sign-in flow on mobile
4. **Easier Debugging**: Clear error messages and status
5. **Consistent Behavior**: Works the same across platforms

## Next Steps

1. **Install Dependencies**: Run `flutter pub get`
2. **Configure Firebase**: Follow the setup steps above
3. **Test**: Verify Google Sign-In works on all platforms
4. **Deploy**: Build and deploy to your server

## Files Modified
- `pubspec.yaml` - Added google_sign_in dependency
- `web/index.html` - Added Google Sign-In configuration
- `android/app/build.gradle` - Added Google Services plugin
- `android/build.gradle` - Added Google Services classpath
- `lib/services/google_sign_in_service.dart` - New service file
- `lib/screens/guest/onboard_screen.dart` - Updated sign-in logic
