# Nua

Nua is a minimal SwiftUI iOS app for translating copied Japanese chat messages into natural conversational English with a brief meaning note when useful.

## Local setup

Open `Nua.xcodeproj` in Xcode 15 or newer. Set the signing team and bundle identifier (`com.ykingtech.nua` by default). Create a local `Secrets.xcconfig` (ignored by git) with `GEMINI_API_KEY = your_key` and `GEMINI_MODEL = gemini-2.5-flash`, then add it to the Debug/Release configurations. Never commit the key.

Clipboard access is intentionally Apple-compliant: Nua reads the general pasteboard when active and also offers a clear Paste & Translate button.

## Codemagic

`codemagic.yaml` expects the secure Codemagic environment variable `GEMINI_API_KEY` and optionally `GEMINI_MODEL`. Configure Apple signing through the Codemagic App Store Connect integration; do not put private keys in the repository. Set `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_PRIVATE_KEY` as Codemagic secure variables if using API-key publishing. The workflow produces an IPA and dSYM and publishes to TestFlight.
