# Building the Android APK (offline scoreboard)

The scoreboard is an Astro static web app wrapped with
[Capacitor](https://capacitorjs.com/). Capacitor bundles the entire built site
(`dist/`) inside the APK, so the installed app **runs fully offline** — no
server, no internet. (All remote dependencies were removed; the display fonts
are bundled under `public/fonts` and the body font falls back to the system
font.)

## What's already set up

- `@capacitor/core`, `@capacitor/cli`, `@capacitor/android` are installed.
- `capacitor.config.ts` — app id `com.steenbergttc.scoreboard`, name
  `TT Scoreboard`, `webDir: dist`.
- The native project lives in `android/` (committed; build output is gitignored).
- npm scripts:
  - `npm run android:sync` — build the web app and copy it into `android/`.
  - `npm run android:open` — build, sync, then open the project in Android Studio.
  - `npm run android:apk` — build, sync, then assemble a debug APK from the CLI.

## Prerequisites — already installed on this machine ✅

The toolchain is set up and the APK builds successfully here:

- **JDK 21** — `C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot`
  (installed via `winget install Microsoft.OpenJDK.21`).
- **Android SDK** — `C:\Android\sdk` (command-line tools), with
  `platform-tools`, `platforms;android-36`, `build-tools;36.0.0` installed and
  all licenses accepted.
- `JAVA_HOME` and `ANDROID_HOME` are set (user environment), and
  `android/local.properties` points at the SDK.

If you build on a **different machine**, install:

1. **JDK 21**: `winget install Microsoft.OpenJDK.21` (or download from Adoptium).
2. **Android SDK**: either install **Android Studio**, or just the
   command-line tools and run
   `sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"`
   then `sdkmanager --licenses`.
3. Set `JAVA_HOME` (JDK 21) and `ANDROID_HOME` (SDK), and create
   `android/local.properties` with `sdk.dir=<path-to-sdk>`.

## Build options

### Option A — Android Studio (recommended, easiest)

```
npm install
npm run android:open
```

In Android Studio: **Build ▸ Build Bundle(s) / APK(s) ▸ Build APK(s)**.
When it finishes, click the “locate” link, or find it at:

```
android/app/build/outputs/apk/debug/app-debug.apk
```

Copy that `.apk` to the Android device and install it (enable “install from
unknown sources”). To run on a connected device/emulator instead, press ▶ Run.

### Option B — Command line (debug APK)

After the prerequisites are installed:

```
npm install
npm run android:apk
```

Output: `android/app/build/outputs/apk/debug/app-debug.apk`.

### Option C — Signed release APK (for distribution)

1. Create a keystore (one time):
   ```
   keytool -genkey -v -keystore scoreboard.keystore -alias scoreboard \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
2. In Android Studio: **Build ▸ Generate Signed Bundle / APK ▸ APK**, choose the
   keystore, pick `release`, finish. (Or configure `signingConfigs` in
   `android/app/build.gradle` and run `gradlew assembleRelease`.)

## After changing the web app

Any time you edit the web code, re-sync before rebuilding:

```
npm run android:sync
```

(`android:open` / `android:apk` already do this for you.)

## Using it offline with an external monitor + Bluetooth

The intended match-day setup:

1. Run the app on an Android device (or the Pi kiosk — see `README.md`).
2. Send the picture to the big external monitor over **HDMI** (the standard way
   external displays connect; phones/tablets use a USB‑C→HDMI adapter, the Pi
   uses HDMI directly).
3. Control scoring with a **Bluetooth presentation remote / clicker**, which the
   OS presents as a keyboard. In the app go to **Menu ▸ Setup ▸ Scoring Keys**
   and record the buttons your remote sends for:
   - Player 1 scored / Player 2 scored
   - Correction mode
   - (optional) instant per-player correction keys

The app stays awake during play via the Screen Wake Lock API.

> **Note on “Bluetooth to connect to external monitors.”** Standard external
> monitors do not receive video over Bluetooth — that path is HDMI/cable, with
> Bluetooth used for the *remote control*. If instead you want a **second
> Android device acting as a spectator screen that syncs scores over Bluetooth**
> from the operator device, that needs a native Bluetooth (BLE) Capacitor plugin
> and a small sync layer. That is not included yet — tell me and I’ll add it as
> a follow-up.
