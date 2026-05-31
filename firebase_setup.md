# BahiKhata — Firebase Setup Guide

## Prerequisites
- A Google account
- Flutter SDK installed (3.41+)
- Android Studio or VS Code

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Name it: `BahiKhata` (or any name you prefer)
4. Disable Google Analytics (optional for MVP)
5. Click **Create Project**

## Step 2: Add Android App

1. In Firebase Console, click the **Android icon** to add an app
2. **Android package name**: `com.bahikhata.app`
3. **App nickname**: `BahiKhata`
4. **SHA-1**: Not needed for email/password auth (skip)
5. Click **Register App**
6. **Download `google-services.json`**
7. Place it in: `android/app/google-services.json`

## Step 3: Enable Authentication

1. In Firebase Console → **Authentication** → **Get Started**
2. Go to **Sign-in method** tab
3. Enable **Email/Password** provider
4. Click **Save**

## Step 4: Create Firestore Database

1. In Firebase Console → **Firestore Database** → **Create Database**
2. Choose **Start in test mode** (we'll add real rules next)
3. Select a location close to your users
4. Click **Enable**

## Step 5: Deploy Security Rules

1. In Firestore Console → **Rules** tab
2. Copy the contents of `firestore.rules` from this project
3. Paste and click **Publish**

Alternatively, if you have Firebase CLI installed:
```bash
firebase login
firebase init firestore
firebase deploy --only firestore:rules
```

## Step 6: Configure Flutter

### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (follow prompts, select your project and Android)
flutterfire configure

# This auto-generates lib/firebase_options.dart
```

### Option B: Manual Configuration
1. Make sure `google-services.json` is in `android/app/`
2. The `lib/firebase_options.dart` file is a placeholder
3. Replace the placeholder values with your Firebase project's values
4. You can find these values in Firebase Console → Project Settings

## Step 7: Install Dependencies

```bash
flutter pub get
```

## Step 8: Create First User

Since this is a private app, you need to create the first user manually:

### Option A: Firebase Console
1. Go to Firebase Console → Authentication → Users
2. Click **Add User**
3. Email: `owner@bahikhata.local`
4. Password: (choose a strong password)
5. Note the **User UID**

### Option B: Create via the app
The first run will redirect to login. You'll need to create the user first via Firebase Console.

## Step 9: Set Up Initial Data

After creating the first user:

1. Login to the app with `owner` / your password
2. Go to **Settings** → **Seed Demo Data** to populate sample data
3. OR manually create organization data in Firestore Console:

### Manual Firestore Setup:
```
organizations/{auto-id}
  ├── name: "My Shop"
  ├── ownerId: "{user-uid-from-step-8}"
  ├── businessType: "tailorShop"
  ├── currency: "$"
  ├── createdAt: {timestamp}
  ├── updatedAt: {timestamp}
  └── users/{user-uid}
        ├── uid: "{user-uid}"
        ├── name: "Owner"
        ├── email: "owner@bahikhata.local"
        ├── username: "owner"
        ├── role: "owner"
        ├── active: true
        ├── organizationId: "{organization-id}"
        ├── createdAt: {timestamp}
        └── updatedAt: {timestamp}
```

## Step 10: Run the App

```bash
# Run on connected device or emulator
flutter run

# Or run in debug mode
flutter run --debug
```

## Step 11: Build Release APK

```bash
# Build release APK
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk

# Transfer to Android device and install
# You may need to enable "Install from unknown sources" on the device
```

## Firestore Indexes

The app uses compound queries that may require Firestore indexes.
When you first run a query that requires an index, Firestore will
show an error with a direct link to create the required index.

Common indexes needed:
- `productionEntries`: `month` ASC, `date` DESC
- `productionEntries`: `staffId` ASC, `date` DESC
- `productionEntries`: `date` ASC, `staffId` ASC
- `moneyEntries`: `month` ASC, `date` DESC
- `moneyEntries`: `staffId` ASC, `date` DESC
- `monthlyRates`: `month` ASC

## Troubleshooting

### "google-services.json not found"
Make sure the file is at `android/app/google-services.json`

### "Firebase not initialized"
Run `flutterfire configure` or verify `firebase_options.dart` has correct values

### "Permission denied" on Firestore
1. Check that the user document exists in `organizations/{orgId}/users/{uid}`
2. Verify the security rules are deployed
3. Check the user's role allows the operation

### Build fails on release
Make sure `minSdkVersion` is 23 in `android/app/build.gradle.kts`
