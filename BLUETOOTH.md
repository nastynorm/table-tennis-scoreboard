# Second-screen sync (Bluetooth & local)

The scoreboard can drive a **second display** that shows a clean, read-only
spectator view while you keep scoring on the controller device. It works fully
offline.

## Roles

- **Controller** — the device you score on. Open **Menu ▸ Broadcast**. It starts
  sending the live match state and shows a green “Broadcasting” badge.
- **Viewer / spectator** — the second device/screen. Open **Menu ▸ View 2nd
  Screen**. It connects to the controller and mirrors the board (scores, games,
  serve indicator, yellow cards, doubles partners, timeouts, team scores). Tap
  **Exit Viewer** to leave.

## Transports (chosen automatically)

| Platform | Transport | Notes |
|----------|-----------|-------|
| Installed Android APK | **Bluetooth LE** | True device-to-device, no Wi-Fi/internet. |
| Browser / PWA | **BroadcastChannel** | Mirrors to another tab/window on the *same* machine — great for a laptop driving an external monitor as a second window, and for testing. |

The transport is selected at runtime: native Android uses BLE, everything else
uses BroadcastChannel. Both speak the same compact JSON snapshot, sent on every
score change plus a heartbeat every 1.5 s so a viewer that joins late catches up.

## How the BLE sync works

- Controller acts as a BLE **peripheral**: it advertises service
  `7f3e0001-…` with a notify/read characteristic `7f3e0002-…` holding the
  snapshot JSON (`src/components/sync.ts`).
- Viewer acts as a BLE **central**: scans for that service, connects, reads the
  current value and subscribes to notifications (`src/components/bleTransport.ts`).
- Manifest permissions for Android 12+ (`BLUETOOTH_SCAN` with
  `neverForLocation`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`) and legacy
  fallbacks are already declared.

### ⚠️ Status / testing note

The **viewer (central)** path uses `@capacitor-community/bluetooth-le`, which is
well supported. The **controller (peripheral / GATT-server)** path uses
`cordova-plugin-ble-peripheral`; Android GATT-server behaviour varies by device,
so this side **needs testing on two physical Android devices**. The code is
written defensively — if peripheral mode is unavailable it surfaces a friendly
error rather than crashing, and the BroadcastChannel path keeps working for a
same-machine second window.

To test on devices: install the APK on two phones/tablets, enable Bluetooth on
both, **Broadcast** on one and **View 2nd Screen** on the other (grant the
Bluetooth permission prompt), then pick the “TT Scoreboard” device.

## Using a single laptop + external monitor (no Bluetooth)

Open the scoreboard in two browser windows: drag one onto the external monitor
and choose **View 2nd Screen** there; keep the laptop window as the controller.
They sync instantly over BroadcastChannel.
