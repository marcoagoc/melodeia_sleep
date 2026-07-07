# Flutter Sleep Aid App Plan

## Summary

Build **Melodeia Sleep** as a mobile-first Flutter app for guided sleep sessions. The app targets iOS and Android first, uses Firebase Auth with anonymous sign-in and later account upgrade, stores sleep sessions/logs in Cloud Firestore, and keeps audio assets bundled offline for reliable bedtime use.

The v1 experience provides configurable sleep sessions with sound modes, light modes, session parameters, and sleep-quality journaling.

## Core Features

- Sound modes: off, white noise, guided breath in/out cue, heartbeat, or mixed.
- Light modes: off, breathing pulse, or sunrise-style fade.
- Session parameters: duration, start/end BPM, inhale/exhale ratio, brightness range, color warmth, sound mix, and optional notes.
- Sleep logs: good/okay/bad rating, mood, notes, tags, linked session, and simple history/trends.
- Auth: anonymous first launch, with upgrade path for email/Google sign-in later.
- Backend: Cloud Firestore for synced user profile, sessions, logs, and presets.
- Local-first behavior: active session, selected preset, and draft log remain usable before cloud sync.

## Project Structure

- `melodeia_sleep_app/`: Flutter app.
- `melodeia_sleep_app/lib/features/session/`: session setup, timer, audio, light engines.
- `melodeia_sleep_app/lib/features/journal/`: sleep quality logs and notes.
- `melodeia_sleep_app/lib/features/auth/`: anonymous auth and account upgrade.
- `melodeia_sleep_app/lib/features/settings/`: defaults, preferences, privacy controls.
- `melodeia_sleep_app/assets/audio/`: bundled white noise, breath cue, and heartbeat loops.

## Firebase Data Model

- `users/{uid}`: profile, createdAt, authMode, defaultSettings.
- `users/{uid}/sessions/{sessionId}`: planned config, actual start/end, completion status.
- `users/{uid}/logs/{logId}`: date, sleepRating, mood, notes, tags, linkedSessionId.
- `users/{uid}/presets/{presetId}`: reusable sound/light/session configurations.

## Implementation Phases

1. Create planning artifact and Flutter scaffold.
2. Add Firebase dependencies and app-side initialization placeholders.
3. Implement pure Dart sleep-session engine.
4. Build bedtime UI for session setup and active session modes.
5. Add offline bundled audio asset placeholders and audio service abstraction.
6. Add journal/history UI and local-first repository layer.
7. Add tests for session timing, light curves, serialization, and key widgets.

## Test Plan

- Unit tests:
  - BPM interpolation from start to end BPM.
  - Inhale/exhale phase timing.
  - Session countdown and completion.
  - Sunrise brightness curve.
  - Firestore model serialization/deserialization.
- Widget tests:
  - Session setup form validation.
  - Sound/light mode switching.
  - Post-session log prompt.
  - Anonymous onboarding path.
- Manual tests:
  - Start a one-minute breath light session.
  - Start a sunrise-only session.
  - Save good/bad sleep logs with notes.
  - Verify anonymous data sync and later account upgrade once Firebase project configuration is supplied.

## Assumptions

- App name defaults to **Melodeia Sleep**.
- v1 targets iOS and Android only.
- v1 auth starts anonymous and upgrades later.
- v1 audio is bundled offline.
- Firestore is the backend database.
- The app is a relaxation and sleep-routine aid, not a medical device.
