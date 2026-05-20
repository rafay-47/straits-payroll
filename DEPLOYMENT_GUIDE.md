# Deployment Guide - Straights Psyroll App

## Overview
This guide provides step-by-step instructions for deploying the Straights Psyroll application to production environments.

---

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Firebase Setup](#firebase-setup)
3. [Mobile App Deployment](#mobile-app-deployment)
4. [Web App Deployment](#web-app-deployment)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Rollback Procedures](#rollback-procedures)

---

## Pre-Deployment Checklist

### Code Quality
- [ ] All lint errors resolved
- [ ] All tests passing (unit, integration, e2e)
- [ ] Code review completed and approved
- [ ] No hardcoded credentials or secrets
- [ ] All TODO comments addressed or documented
- [ ] Version number updated in `pubspec.yaml`

### Documentation
- [ ] README.md updated
- [ ] API documentation complete
- [ ] User manual prepared
- [ ] Known issues documented
- [ ] Release notes prepared

### Testing
- [ ] All test cases executed (see TESTING_GUIDE.md)
- [ ] Pass rate ≥ 95%
- [ ] Performance testing completed
- [ ] Security audit completed
- [ ] Cross-platform testing verified

### Configuration
- [ ] Environment variables configured
- [ ] Firebase configuration files ready
- [ ] API endpoints verified
- [ ] Feature flags set correctly
- [ ] Analytics tracking configured

---

## Firebase Setup

### 1. Create Firebase Project

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init
```

### 2. Configure Firebase Services

#### A. Authentication
```bash
# Enable Authentication providers in Firebase Console
# 1. Go to Firebase Console > Authentication > Sign-in method
# 2. Enable Email/Password
# 3. Configure authorized domains
```

#### B. Firestore Database
```bash
# Set up Firestore rules
# 1. Go to Firebase Console > Firestore Database > Rules
# 2. Copy and paste rules from firestore.rules file
# 3. Publish rules
```

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isSupervisor() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'supervisor';
    }
    
    function isEmployee() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'employee';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin() || isSupervisor();
      allow create: if isAuthenticated();
      allow update: if isOwner(userId) || isAdmin() || isSupervisor();
      allow delete: if isAdmin();
      
      // User subcollections
      match /attendance/{attendanceId} {
        allow read: if isOwner(userId) || isAdmin() || isSupervisor();
        allow create: if isOwner(userId) || isSupervisor();
        allow update: if isAdmin() || isSupervisor();
        allow delete: if isAdmin();
      }
      
      match /documents/{documentId} {
        allow read: if isOwner(userId) || isAdmin() || isSupervisor();
        allow create: if isAdmin() || isSupervisor();
        allow update: if isAdmin() || isSupervisor();
        allow delete: if isAdmin() || isSupervisor();
      }
      
      match /deviceResetRequests/{requestId} {
        allow read: if isOwner(userId) || isAdmin() || isSupervisor();
        allow create: if isOwner(userId);
        allow update: if isAdmin() || isSupervisor();
        allow delete: if isAdmin();
      }
    }
    
    // Projects collection
    match /projects/{projectId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isSupervisor();
    }
    
    // Audit logs collection
    match /auditLogs/{logId} {
      allow read: if isAdmin();
      allow write: if isAuthenticated();
    }
    
    // System settings collection
    match /systemSettings/{settingId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

#### C. Storage
```bash
# Set up Storage rules
# 1. Go to Firebase Console > Storage > Rules
# 2. Copy and paste rules from storage.rules file
# 3. Publish rules
```

**Storage Security Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isSupervisor() {
      return isAuthenticated() && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'supervisor';
    }
    
    // Documents folder
    match /documents/{userId}/{documentId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isSupervisor();
      allow delete: if isAdmin() || isSupervisor();
    }
  }
}
```

### 3. Firebase Configuration Files

#### Android
```xml
<!-- android/app/google-services.json -->
<!-- Download from Firebase Console > Project Settings > Your apps > Android app -->
<!-- Place in android/app/ directory -->
```

#### iOS
```xml
<!-- ios/Runner/GoogleService-Info.plist -->
<!-- Download from Firebase Console > Project Settings > Your apps > iOS app -->
<!-- Place in ios/Runner/ directory -->
```

#### Web
```dart
// lib/firebase_options_web.dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get web => const FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    messagingSenderId: 'YOUR_SENDER_ID',
    appId: 'YOUR_APP_ID',
  );
}
```

---

## Mobile App Deployment

### iOS Deployment (App Store)

#### 1. Prerequisites
- [ ] Apple Developer Account ($99/year)
- [ ] Xcode installed (latest version)
- [ ] Certificates and provisioning profiles configured

#### 2. Prepare iOS Build
```bash
# Navigate to project directory
cd straights_psyroll

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS app (production)
flutter build ios --release

# Or build archive for App Store
flutter build ipa --release
```

#### 3. Configure App in Xcode
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Configure the following in Xcode:
# 1. Bundle Identifier: com.yourdomain.straights_psyroll
# 2. Team: Select your Apple Developer team
# 3. Version: Match version in pubspec.yaml
# 4. Build number: Increment for each build
# 5. Signing & Capabilities: Auto-manage signing ON
```

#### 4. Update Info.plist
```xml
<!-- ios/Runner/Info.plist -->
<dict>
  <!-- Add required permissions -->
  <key>NSCameraUsageDescription</key>
  <string>This app requires camera access to capture documents</string>
  
  <key>NSPhotoLibraryUsageDescription</key>
  <string>This app requires photo library access to upload documents</string>
  
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>This app requires location access for GPS check-in</string>
  
  <key>NSLocationAlwaysUsageDescription</key>
  <string>This app requires location access for attendance tracking</string>
  
  <key>NFCReaderUsageDescription</key>
  <string>This app uses NFC for check-in</string>
  
  <key>NSFaceIDUsageDescription</key>
  <string>This app uses Face ID for biometric authentication</string>
</dict>
```

#### 5. Archive and Upload
```bash
# In Xcode:
# 1. Product > Archive
# 2. Wait for archive to complete
# 3. Window > Organizer
# 4. Select archive > Distribute App
# 5. Choose App Store Connect
# 6. Upload
# 7. Follow prompts

# Or use command line:
xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa \
  --username "your-apple-id@email.com" \
  --password "app-specific-password"
```

#### 6. Submit for Review
```bash
# In App Store Connect:
# 1. Go to My Apps > Your App
# 2. Select version > Submit for Review
# 3. Fill in required information
# 4. Answer questionnaire
# 5. Submit
```

### Android Deployment (Play Store)

#### 1. Prerequisites
- [ ] Google Play Developer Account ($25 one-time)
- [ ] Android Studio installed
- [ ] Keystore file created

#### 2. Create Keystore
```bash
# Generate keystore (if not already created)
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Move keystore to project
mv ~/upload-keystore.jks android/app/
```

#### 3. Configure Keystore in Project
```properties
# android/key.properties (create this file)
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=upload-keystore.jks
```

#### 4. Update build.gradle
```gradle
// android/app/build.gradle

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

#### 5. Update AndroidManifest.xml
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add required permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.NFC"/>
    <uses-feature android:name="android.hardware.nfc" android:required="false"/>
    
    <application
        android:label="Straights Psyroll"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false">
        ...
    </application>
</manifest>
```

#### 6. Build Release APK/AAB
```bash
# Build Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi

# Output locations:
# AAB: build/app/outputs/bundle/release/app-release.aab
# APK: build/app/outputs/apk/release/app-release.apk
```

#### 7. Upload to Play Console
```bash
# Manual upload:
# 1. Go to Google Play Console
# 2. Select your app > Production
# 3. Create new release
# 4. Upload AAB file
# 5. Fill in release notes
# 6. Review and roll out

# Or use fastlane (optional):
# fastlane supply --aab build/app/outputs/bundle/release/app-release.aab
```

---

## Web App Deployment

### Option 1: Firebase Hosting (Recommended)

#### 1. Build Web App
```bash
# Clean and build
flutter clean
flutter pub get
flutter build web --release

# Output: build/web/
```

#### 2. Deploy to Firebase Hosting
```bash
# Initialize Firebase Hosting (if not done)
firebase init hosting

# Configure:
# - Public directory: build/web
# - Single-page app: Yes
# - Automatic builds: No (optional)

# Deploy
firebase deploy --only hosting

# Output will show your app URL:
# https://your-project-id.web.app
```

#### 3. Custom Domain (Optional)
```bash
# In Firebase Console:
# 1. Hosting > Add custom domain
# 2. Enter your domain name
# 3. Verify ownership (DNS records)
# 4. Wait for SSL provisioning
```

### Option 2: Other Hosting Providers

#### Netlify
```bash
# Build
flutter build web --release

# Deploy using Netlify CLI
npm install -g netlify-cli
netlify deploy --dir=build/web --prod
```

#### Vercel
```bash
# Build
flutter build web --release

# Deploy using Vercel CLI
npm install -g vercel
vercel --prod
```

#### AWS S3 + CloudFront
```bash
# Build
flutter build web --release

# Upload to S3
aws s3 sync build/web s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

---

## Post-Deployment Verification

### 1. Smoke Testing
- [ ] Can access app/website
- [ ] Login works for all roles
- [ ] Core features functional
- [ ] No console errors
- [ ] Firebase connection working

### 2. Monitoring Setup
```bash
# Enable Firebase Analytics
# Firebase Console > Analytics > Dashboard

# Set up Crashlytics (optional)
# Firebase Console > Crashlytics
```

### 3. Performance Monitoring
```bash
# Monitor key metrics:
# - App load time
# - API response times
# - Error rates
# - User engagement
```

### 4. User Feedback Channels
- [ ] In-app feedback mechanism
- [ ] Support email configured
- [ ] Bug reporting system ready

---

## Rollback Procedures

### Mobile Apps

#### iOS Rollback
```bash
# In App Store Connect:
# 1. Go to My Apps > Your App
# 2. App Store > Version History
# 3. Select previous version
# 4. Submit for expedited review if critical
```

#### Android Rollback
```bash
# In Google Play Console:
# 1. Go to Production
# 2. Manage track
# 3. Roll back to previous release
# 4. Confirm rollback
```

### Web App Rollback

#### Firebase Hosting
```bash
# View release history
firebase hosting:channel:list

# Rollback to previous version
firebase hosting:rollback

# Or deploy specific version
firebase hosting:clone source:VERSION_ID target:live
```

#### Other Hosts
```bash
# Use your hosting provider's rollback mechanism
# Or redeploy previous build from source control
git checkout previous-release-tag
flutter build web --release
# Deploy using your provider's method
```

---

## Environment-Specific Configuration

### Development
```dart
// lib/config/environment.dart
class Environment {
  static const String env = 'development';
  static const String apiUrl = 'https://dev-api.example.com';
  static const bool enableLogging = true;
}
```

### Staging
```dart
class Environment {
  static const String env = 'staging';
  static const String apiUrl = 'https://staging-api.example.com';
  static const bool enableLogging = true;
}
```

### Production
```dart
class Environment {
  static const String env = 'production';
  static const String apiUrl = 'https://api.example.com';
  static const bool enableLogging = false;
}
```

---

## CI/CD Pipeline (Optional)

### GitHub Actions Example
```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-firebase-project-id

  deploy-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build appbundle --release
      # Add Play Store upload step
```

---

## Security Checklist

- [ ] All API keys in environment variables
- [ ] Firebase security rules properly configured
- [ ] HTTPS enforced for all connections
- [ ] Sensitive data encrypted
- [ ] Authentication tokens secure
- [ ] No debug logs in production
- [ ] App signing keys secure
- [ ] Dependency vulnerabilities checked

---

## Monitoring & Maintenance

### Regular Tasks
- [ ] **Daily**: Check error logs
- [ ] **Weekly**: Review analytics
- [ ] **Monthly**: Update dependencies
- [ ] **Quarterly**: Security audit

### Key Metrics to Monitor
- Active users (DAU/MAU)
- Crash-free rate (target: >99%)
- App performance (load times)
- User retention
- Feature usage

---

## Support Contacts

**Technical Issues:**
- Email: dev-support@example.com
- Slack: #tech-support

**Business Issues:**
- Email: business@example.com
- Phone: +1-XXX-XXX-XXXX

**Emergency Hotline:**
- Phone: +1-XXX-XXX-XXXX (24/7)

---

## Version History

| Version | Release Date | Key Changes |
|---------|--------------|-------------|
| 1.0.0   | 2025-XX-XX   | Initial release |

---

## Conclusion

Follow this guide carefully for a smooth deployment. Always test thoroughly in staging before deploying to production.

**Remember:** 
- Keep backups of previous versions
- Have rollback plan ready
- Monitor closely after deployment
- Communicate with stakeholders

For questions or issues, contact the development team.

