# Firebase Setup for YouVai Web App

## Overview
This document explains the Firebase configuration for the YouVai Flutter web application.

## Configuration Files

### 1. Web Configuration (`web/index.html`)
- Firebase JavaScript SDK is loaded from CDN
- Firebase configuration is initialized in `web/firebase-config.js`
- SDKs loaded:
  - `firebase-app-compat.js`
  - `firebase-auth-compat.js`
  - `firebase-firestore-compat.js`

### 2. Flutter Configuration (`lib/main.dart`)
- Firebase is initialized using `FirebaseUtils.initializeFirebase()`
- Platform-specific handling for web and mobile
- Error handling to allow app to run even if Firebase fails

### 3. Firebase Utils (`lib/utils/firebase_utils.dart`)
- Centralized Firebase configuration
- Utility methods for initialization and debugging
- Status checking methods

## Firebase Project Details
- **Project ID**: youvai-56995
- **Auth Domain**: youvai-56995.firebaseapp.com
- **API Key**: AIzaSyAlg92sDvJb8xmuMt8yA9MtjbWrHMWV1oY
- **App ID**: 1:377693730311:web:24dfc047db461c18c3dca2

## Troubleshooting

### Common Issues

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Ensure Firebase SDK is loaded in `index.html`
   - Check that `firebase-config.js` is properly loaded
   - Verify initialization order (Firebase before Flutter)

2. **"Unable to establish connection on channel"**
   - This usually indicates Firebase JavaScript SDK is not loaded
   - Check browser console for JavaScript errors
   - Ensure all Firebase SDK scripts are loading correctly

3. **Google Sign-In fails on web**
   - Verify Firebase Auth is properly initialized
   - Check that Google Auth provider is configured in Firebase Console
   - Ensure popup blockers are disabled

### Debugging Steps

1. **Check Browser Console**
   - Look for Firebase initialization messages
   - Check for JavaScript errors
   - Verify Firebase SDK versions

2. **Use Firebase Utils**
   ```dart
   FirebaseUtils.printFirebaseStatus();
   await FirebaseUtils.checkFirebaseAuth();
   ```

3. **Test Firebase Connection**
   - Open browser console
   - Type `firebase` to check if SDK is loaded
   - Check `firebase.apps` to see initialized apps

## Deployment Notes

### For Web Deployment
1. Ensure `web/index.html` includes Firebase SDK
2. Verify `web/firebase-config.js` is included in build
3. Check that Firebase configuration matches production settings

### For Mobile Deployment
1. Firebase is initialized through Flutter plugins
2. No additional configuration needed beyond `main.dart`

## Security Notes
- API keys are public and safe to include in client-side code
- Firebase security rules should be configured in Firebase Console
- Authentication methods should be enabled in Firebase Console
