# INTELLEKT student app and API

## Architecture

Deploy the `server` directory as a separate Railway service and keep it connected to PostgreSQL. Deploy the Next.js dashboard as another Railway service. The Flutter app calls only the API service. Therefore, a dashboard crash does not stop the API or mobile app.

## Railway API service

1. Create a new service from the `server` directory.
2. Add `DATABASE_URL` from the PostgreSQL service.
3. Set `NODE_ENV=production` and `DB_POOL_MAX=10`.
4. Use `npm start`. Railway supplies `PORT` automatically.
5. Configure the health-check path as `/health`.

Do not upload a real `.env` file or commit database credentials.

## Flutter app

Production (default API):

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Use another API URL without editing source code:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api-service.up.railway.app
```

For an Android emulator accessing a server on your computer:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5050
```

The mobile login endpoint accepts only student IDs beginning with `IA`.
