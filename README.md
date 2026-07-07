# Melodeia Sleep

Melodeia Sleep is a sleep-aid app workspace for planning, documenting, and building a Flutter mobile prototype for guided bedtime sessions.

## Contents

- `melodeia_sleep_app/` - Flutter iOS/Android app for guided sleep sessions.
- `SLEEP_APP_PLAN.md` - product and implementation plan for the Flutter app.
- `AGENTS.md` - contributor guidance for coding agents.

## Flutter App

The app is a mobile-first relaxation and sleep-routine aid. It includes:

- Configurable guided breathing sessions.
- Light modes for breathing pulse and sunrise fade.
- Sound-mode foundation for white noise, breath cues, heartbeat, and mixed modes.
- Sleep journal logging with good/okay/bad rating and notes.
- Firebase-ready anonymous auth and Firestore sync hooks.
- Local-first config and journal persistence.

Run app checks from `melodeia_sleep_app/`:

```sh
flutter analyze
flutter test
dart format lib test
```

Start the app:

```sh
cd melodeia_sleep_app
flutter run
```

## Firebase

Firebase packages are installed, but the app is not connected to a real Firebase project yet. It runs in offline/local mode until Firebase is configured.

From `melodeia_sleep_app/`, configure Firebase with:

```sh
flutterfire configure
```

The planned backend uses:

- Firebase Auth for anonymous sign-in and later account upgrade.
- Cloud Firestore for users, sessions, logs, and presets.

Do not commit private credentials or secrets.

## Medical Disclaimer

Melodeia Sleep is intended as a relaxation and sleep-routine aid. It is not a medical device and does not provide diagnosis, treatment, or clinical advice.
