# Google Client ID Setup Guide

## Overview
This guide explains where to place Google Client IDs for different platforms in your Flutter app.

## Current Status

### ✅ **Web Platform** - CONFIGURED
**File**: `web/index.html`
```html
<meta name="google-signin-client_id" content="377693730311-24dfc047db461c18c3dca2.apps.googleusercontent.com">
```
**Status**: ✅ Working

### ✅ **Dart Code** - CONFIGURED
**File**: `lib/services/google_sign_in_service.dart`
```dart
clientId: kIsWeb ? '377693730311-24dfc047db461c18c3dca2.apps.googleusercontent.com' : null,
```
**Status**: ✅ Working

### ⚠️ **Android Platform** - NEEDS REAL FILE
**File**: `android/app/google-services.json`
**Status**: ⚠️ Placeholder file created - needs real file from Firebase Console

### ⚠️ **iOS Platform** - NEEDS REAL FILE
**File**: `ios/Runner/GoogleService-Info.plist`
**Status**: ⚠️ Placeholder file created - needs real file from Firebase Console

## Step-by-Step Setup

### **Step 1: Firebase Console Setup**

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: `youvai-56995`

2. **Project Settings**
   - Click the gear icon (⚙️) next to "Project Overview"
   - Select "Project settings"

### **Step 2: Android Configuration**

1. **Add Android App**
   - In Project Settings, go to "General" tab
   - Scroll down to "Your apps" section
   - Click "Add app" → "Android"

2. **App Details**
   - **Android package name**: `com.globalspace.youvai`
   - **App nickname**: `YouVai Android`
   - **Debug signing certificate SHA-1**: (leave blank for now)
   - Click "Register app"

3. **Download Configuration**
   - Download the `google-services.json` file
   - Replace the placeholder file at: `android/app/google-services.json`

### **Step 3: iOS Configuration (Optional)**

1. **Add iOS App**
   - In Project Settings, go to "General" tab
   - Scroll down to "Your apps" section
   - Click "Add app" → "iOS"

2. **App Details**
   - **iOS bundle ID**: `com.globalspace.youvai`
   - **App nickname**: `YouVai iOS`
   - Click "Register app"

3. **Download Configuration**
   - Download the `GoogleService-Info.plist` file
   - Replace the placeholder file at: `ios/Runner/GoogleService-Info.plist`

### **Step 4: Google Cloud Console Setup**

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select your project: `youvai-56995`

2. **OAuth 2.0 Client IDs**
   - Go to "APIs & Services" → "Credentials"
   - Look for existing OAuth 2.0 Client IDs
   - Or create new ones if needed

3. **Web Client ID** (Already configured)
   - Client ID: `377693730311-24dfc047db461c18c3dca2.apps.googleusercontent.com`
   - **Authorized JavaScript origins**:
     - `https://aesthetic.youv.ai`
     - `http://localhost:3000` (for development)
   - **Authorized redirect URIs**:
     - `https://aesthetic.youv.ai/__/auth/handler`
     - `http://localhost:3000/__/auth/handler` (for development)

## File Locations Summary

| Platform | File Location | Status |
|----------|---------------|---------|
| **Web** | `web/index.html` | ✅ Configured |
| **Dart** | `lib/services/google_sign_in_service.dart` | ✅ Configured |
| **Android** | `android/app/google-services.json` | ⚠️ Needs real file |
| **iOS** | `ios/Runner/GoogleService-Info.plist` | ⚠️ Needs real file |

## Testing

### **Web Testing**
1. Run `flutter build web`
2. Deploy to your server
3. Test at: `https://aesthetic.youv.ai/#/onboard`

### **Android Testing**
1. Replace `android/app/google-services.json` with real file
2. Run `flutter run` on Android device
3. Test Google Sign-In

### **iOS Testing**
1. Replace `ios/Runner/GoogleService-Info.plist` with real file
2. Run `flutter run` on iOS device
3. Test Google Sign-In

## Troubleshooting

### **Common Issues**

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

### **Debug Steps**
1. Check browser console for error messages
2. Verify Firebase initialization
3. Test with the debug page: `web/firebase-test.html`
4. Check network requests in browser dev tools

## Important Notes

- **Web Client ID**: Already configured and working
- **Android Client ID**: Needs real `google-services.json` from Firebase Console
- **iOS Client ID**: Needs real `GoogleService-Info.plist` from Firebase Console
- **Package Name**: Must match `com.globalspace.youvai` in all configurations

## Next Steps

1. **Download real configuration files** from Firebase Console
2. **Replace placeholder files** with real ones
3. **Test on all platforms**
4. **Deploy and verify** Google Sign-In works

## Files to Replace

- `android/app/google-services.json` ← Download from Firebase Console
- `ios/Runner/GoogleService-Info.plist` ← Download from Firebase Console
