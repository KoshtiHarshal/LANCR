# LANCR — Play Store release checklist

## ✅ Already done (in repo)
- `firebase_crashlytics` wired (Gradle plugin + `main.dart` error handlers).
- `android/app/build.gradle.kts`: `targetSdk = 35`, release **signingConfig** that reads `android/key.properties` and **falls back to debug** until that file exists (so it still builds now).
- `key.properties.example` template added.
- Privacy / Terms / Account-deletion docs in `docs/` (host these for the Play listing).

## �ﾃYou do — Step 1: Release keystore
From the `android/` folder:
```
keytool -genkey -v -keystore lancr-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lancr
```
- Answer the prompts; **remember the passwords** (store them in a password manager — losing them means you can never update the app).
- Copy `key.properties.example` → `android/key.properties` and fill in your real passwords / alias / `storeFile=../lancr-release.jks`.
- `key.properties` and `*.jks` are already gitignored — **never commit them**.

## 🔧 You do — Step 2: Firebase re-registration for `com.lancr.app`
1. Firebase Console → project **lancr-h0195** → Project settings → **Add app → Android**.
2. Package name: **`com.lancr.app`**. (App nickname/debug SHA optional now.)
3. Download the new **`google-services.json`** and **replace** `android/app/google-services.json`.
4. Tell me when done — I'll flip `applicationId` to `com.lancr.app` in `build.gradle.kts`
   (one line; `namespace`/`MainActivity` can stay `com.example.lancr_app`, so no code moves).
5. Re-test **FCM push** on a release build with the new id.

## 🔧 Build the release bundle (after Steps 1–2)
```
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab` → upload to Play Console.

## 📋 Play Console (you)
- Create app → **Store listing**: title, short + full description, **512×512 icon**, **1024×500 feature graphic**, phone (+tablet) screenshots.
- **Privacy policy URL** (host `docs/privacy_policy.md`), **account-deletion URL** (host `docs/account_deletion.md`).
- **Data safety** form: collected = email, profile, messages, photos; encrypted in transit; deletion available.
- **Content rating** questionnaire; target audience; category = Business.
- Roll out: **Internal testing → Closed testing → Production**; review the Pre-launch report.

## ⏭️ Deferred (post-launch, optional)
- R8/`minify` + `shrinkResources` (needs ProGuard keep-rules for Supabase/Firebase + a tested release build).
- Infinite-scroll pagination + full-text search index.
- Switch support email from `lancrapp0@gmail.com` to a real `support@` inbox.
