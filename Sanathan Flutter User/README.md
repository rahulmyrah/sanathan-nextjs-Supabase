# Sanathan Flutter User App

This is the customer mobile app for Sanathan.

The app is being reskinned and extended from the original astrology app into a Sanathan spiritual companion for users. It connects to the Laravel backend APIs for Personal Guruji, AI tools, listings, courses, Panchang, Rashi guidance, Kundali, reports, shop, chat/call flows, and account features.

## Current Sanathan Features

- Personal Guruji entry point
- Sanathan AI Tools
- Listings directory
- Premium Sanathan Courses
- Course detail and premium access messaging
- Live class link support after course access is unlocked
- Existing astrology, Kundali, reports, wallet, shop, chat, and call flows

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

The app reads API configuration from the existing config files under `lib/utils`. For local development, point the API URL to the Laravel backend, commonly:

```text
http://127.0.0.1:8000/api
```

Use the host machine IP instead of `127.0.0.1` when testing on a physical device.

## Developer Notes

- Prefer Sanathan naming in new screens and labels.
- Keep new Sanathan screens under `lib/views/sanathan`.
- Reuse `SanathanFeatureApi` for new Sanathan modules where possible.
- Do not commit local signing files, Firebase private keys, API keys, or build output.
- Existing Astroway names are legacy and should be replaced gradually as modules are redesigned.
