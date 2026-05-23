# Sanathan Flutter Guruji App

This is the Guruji, guide, astrologer, and partner mobile app for Sanathan.

The app supports the supply/partner side of the Sanathan platform. It is being evolved from the original astrologer app into a Sanathan guide workspace for consultations, Personal Guruji support, listings, premium learning visibility, AI tools, and future teacher/service provider workflows.

## Current Sanathan Features

- Sanathan partner hub
- Guruji guidance chat surface
- AI tools visibility
- Listings and submitted listings visibility
- Official Sanathan live courses visibility
- Premium INR 99 positioning for courses and platform benefits
- Existing consultation, wallet, chat, call, live, and profile flows

## Setup

Prerequisites:

- Flutter SDK
- Android Studio or Xcode
- A running Sanathan Laravel backend

Install dependencies:

```bash
flutter pub get
```

Run:

```bash
flutter run
```

## API Configuration

The app reads API configuration from `lib/utils/config.dart`. For local development, point the API URL to the Laravel backend API.

For emulator/device testing, use the correct host IP reachable from the device.

## Developer Notes

- Keep Sanathan-specific screens under `lib/views/sanathan`.
- Use `SanathanFeatureApi` for Sanathan modules instead of older generic APIs where possible.
- The legacy `Courses` module remains for existing course purchase flows; Sanathan live course visibility now comes through the official Sanathan course APIs.
- Do not commit signing keys, API keys, Firebase secrets, or build output.
- Existing Astroway naming is legacy and should be replaced as modules are redesigned.
