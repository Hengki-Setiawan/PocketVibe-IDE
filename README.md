# PocketVibe IDE

Asisten coding AI yang berjalan 100% di perangkat Android-mu sendiri.

## Arsitektur

PocketVibe menggunakan arsitektur **Companion Bridge**:

- **Flutter GUI** — Antarmuka pengguna (Dart)
- **Termux** — Runtime Linux di Android (APK terpisah)
- **OpenCode AI** — AI coding assistant berjalan di Ubuntu via proot-distro

## Persyaratan

- Android 10+ (API 29)
- Termux & Termux:API (dari F-Droid)
- Koneksi internet (hanya untuk setup awal)
- ~2GB ruang kosong

## Tech Stack

- **Frontend**: Flutter 3.24+, Riverpod, GoRouter
- **Android Native**: Kotlin, MethodChannel
- **Runtime**: Termux, proot-distro Ubuntu, OpenCode AI
- **Penyimpanan**: flutter_secure_storage, SharedPreferences

## Build

```bash
flutter pub get
flutter build apk --debug
```

## Struktur Proyek

```
lib/
  core/
    constants/     — Warna, text style, konfigurasi
    routing/       — GoRouter (8 rute)
    services/      — API client, storage, setup orchestrator
    theme/         — Dark theme
  models/          — Data classes
  providers/       — Riverpod state management
  views/           — UI screens & widgets
android/
  app/src/main/kotlin/com/pocketvibe/ide/
    MainActivity.kt       — MethodChannel handler
    termux/               — TermuxBridge, Constants, CommandResult
assets/
  termux_scripts/   — Bootstrap, install, start server
test/               — Unit tests (9 test cases)
integration_test/   — Integration tests (2 test cases)
scripts/            — CI provisioning & verification
tool/               — OpenCode API probe utility
```
