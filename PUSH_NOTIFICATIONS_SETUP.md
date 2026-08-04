# Push notifications setup

The Flutter and Node.js code is integrated. Complete these one-time Firebase steps before testing.

## 1. Create the Android app in Firebase

1. Open Firebase Console and create/select a project.
2. Add an Android app with package name `com.example.intellekt_mobile`.
3. Download `google-services.json`.
4. Place it at `android/app/google-services.json`.
5. In Firebase Cloud Messaging, ensure the Cloud Messaging API is enabled.

## 2. Configure the Node.js server

1. Firebase Console -> Project settings -> Service accounts -> Generate new private key.
2. Keep the downloaded JSON private. Do not add it to Git.
3. Convert it to a single-line Base64 value in PowerShell:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\firebase-service-account.json"))
   ```

4. For local testing, add the output to `server/.env`:

   ```env
   FIREBASE_SERVICE_ACCOUNT_BASE64=PASTE_BASE64_VALUE_HERE
   ```

5. For Railway, add the same variable to the deployed mobile-server service.

## 3. Install and run

From the Flutter project folder:

```powershell
flutter pub get
```

From the `server` folder:

```powershell
npm install
npm start
```

The server automatically creates `student_device_tokens`. The same SQL is also available in `server/migrations/001_student_device_tokens.sql`.

Run the Flutter app on an Android emulator or physical Android phone. Sign in once so the app can request notification permission and register the device with the server.

## 4. Test one student

Replace the values below and call the deployed/local server:

```powershell
$body = @{
  roll_no = "IA001"
  title = "Test notification"
  body = "Push notification setup is working"
  module_name = "general"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:5050/mobile/push/send" `
  -ContentType "application/json" `
  -Body $body
```

The server also sends push notifications automatically when marks are uploaded, attendance is updated, or a new test is scheduled.

## Expected test order

1. Start the server and confirm `Firebase Cloud Messaging initialized`.
2. Run the Flutter app on Android.
3. Allow notification permission.
4. Log in as the target student.
5. Send the test request.
6. Put the app in the background or close it and repeat the test.

Do not test this feature through Edge; notification-bar delivery must be tested on Android.
