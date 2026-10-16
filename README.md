# Nua

Nua is a minimal SwiftUI iOS app for translating copied Japanese chat messages into natural conversational English with a brief meaning note when useful.

## Local setup

Open `Nua.xcodeproj` in Xcode 15 or newer. Set the signing team and bundle identifier (`com.ykingtech.nua` by default). Configure `NUA_WORKER_URL` with your deployed Cloudflare Worker URL. Never put a Gemini API key in the iOS app.

Clipboard access is intentionally Apple-compliant: Nua reads the general pasteboard when active and also offers a clear Paste & Translate button.

## Codemagic

`codemagic.yaml` expects `NUA_WORKER_URL` in its environment-variable group. Configure Apple signing through the Codemagic App Store Connect integration; do not put private keys in the repository. The workflow produces an IPA and dSYM and publishes to TestFlight.

## Cloudflare Worker

From `worker/`, run `npm install`, `npx wrangler login`, `npx wrangler secret put GEMINI_API_KEY`, then `npm run deploy`. Wrangler prints the Worker URL; add it as `NUA_WORKER_URL` in the `nua-secrets` Codemagic group and rebuild the app. Change `GEMINI_MODEL` in Worker Settings → Variables and Secrets whenever needed. The Worker keeps the Gemini key off-device.
