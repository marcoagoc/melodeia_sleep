# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

This workspace contains planning, documentation, and implementation artifacts for the Melodeia Sleep Flutter app.

- `melodeia_sleep_app/`: Flutter mobile app for guided sleep sessions using sound, light, journaling, and Firebase-backed sync.
- `SLEEP_APP_PLAN.md`: product and implementation plan for the Flutter app.

## Flutter App

Work inside `melodeia_sleep_app/` for app changes.

Common commands:

```sh
flutter analyze
flutter test
dart format lib test
```

The app currently targets iOS and Android. It uses:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `shared_preferences`
- `just_audio`

Firebase app-side dependencies are installed, but a real Firebase project still needs to be connected with:

```sh
flutterfire configure
```

Until that is done, the app intentionally runs in offline/local mode and shows a Firebase-not-configured message.

## Implementation Notes

- Keep sleep timing and breathing behavior in pure Dart where possible, especially under `lib/features/session/domain/`.
- Keep Firebase and platform services behind small service/repository classes so tests can run without a live Firebase project.
- The app is a relaxation and sleep-routine aid, not a medical device. Do not add diagnosis, treatment, or clinical claims.
- Offline bedtime behavior matters: local config and journal drafts should continue working without network.
- Audio assets belong in `melodeia_sleep_app/assets/audio/`.

## Testing Expectations

Before handing off app changes, run:

```sh
flutter analyze
flutter test
```

## Editing Guidelines

- Prefer small, focused changes.
- Do not commit generated build output.
- Do not add real secrets, Firebase service credentials, or private API keys to the repo.
