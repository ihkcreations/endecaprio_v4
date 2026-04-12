# EnDecaprio V4

A high-security text encryption app using a proprietary 6-layer encryption pipeline. All data is stored locally with no cloud dependencies.

## Features

- 🔐 6-layer proprietary encryption pipeline
- 📂 Organized table-based storage
- 🔒 Optional PIN lock with 12-word recovery key
- 💾 Secure offline SQLite storage
- 🖥️ Cross-platform (Windows, Android, iOS, macOS, Linux)

## Setup

1. Copy `lib/core/secrets/secrets_config.template.dart`  
   to `lib/core/secrets/secrets_config.dart`
2. Fill in your own values — generate random bytes for all seed arrays  
   (see comments in template)
3. Run:
   ```bash
   flutter pub get && flutter run
   ```

> ⚠️ **Important:** `secrets_config.dart` contains your encryption keys and must NEVER be committed. It is already in `.gitignore`.

## Architecture

- **State Management:** Flutter Riverpod
- **Database:** SQLite (`sqflite` / `sqflite_common_ffi`)
- **Security:** `flutter_secure_storage` for PIN hashes, recovery keys, and app state
- **Organization:** `com.ihkcreations.endecaprio_v4`

## Project Structure

```
lib/
├── app.dart                       # App entry & routing
├── core/
│   ├── constants/                 # App-wide constants
│   ├── secrets/                   # Encryption keys (gitignored)
│   ├── security/                  # PIN, recovery, secure storage
│   ├── theme/                     # App theme & colors
│   └── utils/                     # Helpers
├── data/
│   ├── database/                  # SQLite database
│   ├── models/                    # Data models
│   └── repositories/              # Data access layer
├── features/
│   ├── encrypt_decrypt/           # Main encrypt/decrypt UI
│   ├── onboarding/                # Welcome, PIN setup, recovery key
│   ├── recovery/                  # Forgot PIN flow
│   ├── settings/                  # App settings
│   └── tables/                    # Table management & entries
└── navigation/                    # Route definitions
```