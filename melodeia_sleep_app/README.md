# Melodeia Sleep App

Flutter mobile app prototype for guided sleep sessions.

## Features

- Configurable session duration, start/end BPM, inhale/exhale ratio, brightness, and warmth.
- Light modes: off, breathing pulse, and sunrise fade.
- Sound mode model: off, white noise, breath guide, heartbeat, and mixed.
- Active session screen with breathing/sunrise animation and pause support.
- Post-session sleep journal prompt with good/okay/bad rating and notes.
- Local-first persistence with `shared_preferences`.
- Firebase-ready anonymous auth and Firestore sync hooks.

## Setup

Install Flutter, then run:

```sh
flutter pub get
```

Firebase packages are installed, but no Firebase project is configured yet. The app handles that gracefully and runs in offline/local mode.

When ready to connect Firebase:

```sh
flutterfire configure
```

## Run

```sh
flutter run
```

## Verify

```sh
flutter analyze
flutter test
dart format lib test
```

## Structure

- `lib/app/` - root app widget and theme.
- `lib/features/auth/` - Firebase bootstrap and anonymous auth service.
- `lib/features/session/` - session config, timing engine, audio service, repository, and UI.
- `lib/features/journal/` - sleep log model.
- `assets/audio/` - placeholder folder for bundled offline audio.

## Notes

Production audio files are not included yet. Add loopable bedtime-safe assets under `assets/audio/` and map them in `SleepAudioService`.

Melodeia Sleep is a relaxation and sleep-routine aid, not a medical device.
