import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.steenbergttc.scoreboard",
  appName: "TT Scoreboard",
  // Astro builds the static site into dist/. Capacitor bundles this whole
  // folder into the APK and loads it from the device, so the app runs fully
  // offline with no server required.
  webDir: "dist",
  android: {
    // Keep the system from sleeping is handled in-app; this just makes the
    // splash background match the dark scoreboard theme.
    backgroundColor: "#020617",
  },
};

export default config;
