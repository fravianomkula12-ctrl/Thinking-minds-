# Thinking Minds Android — Firebase-connected starter (v1.1)

This project contains the Android Flutter app source plus Firebase integration scaffolding.

## Implemented in source
- Firebase email/password registration and login.
- New registrations create a `pending` membership profile.
- Pending applicants cannot access member content until approved.
- Approved members get Home, Community Chat, Innovation Ideas, Research and Profile.
- Admin dashboard can approve/reject pending membership applications.
- Firestore-backed group chat, idea submissions and announcements.
- English / Kiswahili switch.

## Important: not yet a ready-to-install APK
You must connect this source to a Firebase project and generate `lib/firebase_options.dart` before it can build. No Firebase project credentials are included. Do not share service-account private keys or passwords.

## Setup
1. Install Flutter SDK and Android Studio on a computer.
2. In the extracted project folder, generate the Android platform files: `flutter create --platforms=android --org com.example .` (this starter contains the app source, not generated Android build scaffolding).
3. Create a Firebase project at https://console.firebase.google.com/.
4. In Firebase, add an Android app. Use Android application ID `com.example.thinking_minds` (or change it consistently in `android/app/build.gradle`).
5. Install Firebase CLI and FlutterFire CLI:
   - `npm install -g firebase-tools`
   - `firebase login`
   - `dart pub global activate flutterfire_cli`
6. In this project folder run:
   - `flutter pub get`
   - `flutterfire configure`
   Choose your Firebase project and Android platform. This creates `lib/firebase_options.dart`.
7. In Firebase Console enable Authentication > Sign-in method > Email/Password.
8. Create Firestore Database (production mode), then publish the contents of `firestore.rules` in Firestore > Rules.
9. In Firebase Authentication, create your own account through the app. In Firestore, open `users/{your-uid}` and change:
   - `status` to `approved`
   - `role` to `admin`
   This first admin bootstrap must be done by the project owner in the Firebase Console. Never allow public users to grant themselves admin.
10. Run `flutter run` with an Android phone connected, or build:
   - `flutter build apk --release`
   APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Admin workflow
- Applicants register with email/password and receive `status: pending`, `role: member`.
- The first admin is assigned manually in Firebase Console as described above.
- Admin opens the Admin tab and approves or rejects applications.
- Only approved members can read/write group messages and ideas.

## Production hardening still required
- Configure Firebase App Check and email verification.
- Add password reset and abuse/reporting controls.
- Add moderation, message deletion/retention policy and upload validation.
- Add Cloud Storage rules before enabling file uploads.
- Add privacy notice and terms of membership.
- Firebase free-tier quotas and pricing can change; monitor usage and set budget alerts.
- Push notification package is included for the next stage but push notification setup/handlers are not yet implemented.
- File uploads/research document storage are not yet implemented in this build.
