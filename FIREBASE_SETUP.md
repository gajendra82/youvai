# Firebase Setup for YouVai Web App

## Overview
This document explains the Firebase configuration for the YouVai Flutter web application.

## Configuration Files

### 1. Web Configuration (`web/index.html`)
- Firebase JavaScript SDK is loaded dynamically with error handling
- Firebase configuration is embedded directly in the HTML
- SDKs loaded:
  - `firebase-app-compat.js`
  - `firebase-auth-compat.js`
  - `firebase-firestore-compat.js`

### 2. Flutter Configuration (`lib/main.dart`)
- Firebase is initialized using `FirebaseUtils.initializeFirebase()`
- Platform-specific handling for web and mobile
- Retry mechanism for server deployment scenarios
- Error handling to allow app to run even if Firebase fails

### 3. Firebase Utils (`lib/utils/firebase_utils.dart`)
- Centralized Firebase configuration
- Utility methods for initialization and debugging
- Status checking methods
- Retry mechanisms for server deployment

## Firebase Project Details
- **Project ID**: youvai-56995
- **Auth Domain**: youvai-56995.firebaseapp.com
- **API Key**: AIzaSyAlg92sDvJb8xmuMt8yA9MtjbWrHMWV1oY
- **App ID**: 1:377693730311:web:24dfc047db461c18c3dca2

## Server Deployment Fixes

### Key Changes for Server Deployment
1. **Dynamic Script Loading**: Firebase SDKs are loaded dynamically with proper error handling
2. **Retry Mechanism**: Multiple attempts to initialize Firebase with delays
3. **Readiness Check**: Firebase readiness is verified before use
4. **Graceful Degradation**: App continues to work even if Firebase fails

### Server-Specific Issues
- **Timing Issues**: Firebase SDK might not load before Flutter initialization
- **Network Issues**: CDN scripts might fail to load on some servers
- **CORS Issues**: Some servers might block external script loading

## Troubleshooting

### Common Issues

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Ensure Firebase SDK is loaded in `index.html`
   - Check that Firebase configuration is properly embedded
   - Verify initialization order (Firebase before Flutter)

2. **"Unable to establish connection on channel"**
   - This usually indicates Firebase JavaScript SDK is not loaded
   - Check browser console for JavaScript errors
   - Ensure all Firebase SDK scripts are loading correctly
   - Use the retry mechanism in `main.dart`

3. **Google Sign-In fails on web**
   - Verify Firebase Auth is properly initialized
   - Check that Google Auth provider is configured in Firebase Console
   - Ensure popup blockers are disabled
   - Use `FirebaseUtils.waitForFirebase()` before sign-in

4. **Server Deployment Issues**
   - Check if CDN scripts are accessible from your server
   - Verify network connectivity to Google's CDN
   - Use the debug page (`web/firebase-debug.html`) to test Firebase loading

### Debugging Steps

1. **Check Browser Console**
   - Look for Firebase initialization messages
   - Check for JavaScript errors
   - Verify Firebase SDK versions

2. **Use Firebase Utils**
   ```dart
   FirebaseUtils.printFirebaseStatus();
   await FirebaseUtils.checkFirebaseAuth();
   await FirebaseUtils.waitForFirebase();
   ```

3. **Test Firebase Connection**
   - Open browser console
   - Type `firebase` to check if SDK is loaded
   - Check `firebase.apps` to see initialized apps

4. **Use Debug Page**
   - Access `web/firebase-debug.html` on your server
   - Check the status messages for Firebase loading issues

### Server Deployment Checklist
- [ ] Firebase SDKs are loading from CDN
- [ ] No CORS issues blocking external scripts
- [ ] Network connectivity to Google's CDN
- [ ] Firebase initialization retry mechanism is working
- [ ] App gracefully handles Firebase failures

## Deployment Notes

### For Web Deployment
1. Ensure `web/index.html` includes dynamic Firebase SDK loading
2. Verify retry mechanism in `main.dart` is active
3. Check that Firebase configuration matches production settings
4. Test with `web/firebase-debug.html` on your server

### For Mobile Deployment
1. Firebase is initialized through Flutter plugins
2. No additional configuration needed beyond `main.dart`

## Security Notes
- API keys are public and safe to include in client-side code
- Firebase security rules should be configured in Firebase Console
- Authentication methods should be enabled in Firebase Console

## Recent Updates for Server Deployment
- Added dynamic script loading with error handling
- Implemented retry mechanism for Firebase initialization
- Added Firebase readiness checks
- Created debug page for troubleshooting
- Improved error handling and logging
