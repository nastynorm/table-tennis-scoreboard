import { BleClient, type ScanResult } from "@capacitor-community/bluetooth-le";
import { BLE_SERVICE, BLE_CHARACTERISTIC, type SyncTransport } from "./sync";

// --- string <-> DataView helpers (BLE characteristics carry raw bytes) ---
function strToDataView(s: string): DataView {
  const bytes = new TextEncoder().encode(s);
  return new DataView(bytes.buffer);
}
function dataViewToStr(v: DataView): string {
  return new TextDecoder().decode(v.buffer);
}

/**
 * Cross-device Bluetooth Low Energy transport.
 *
 *  - Controller = GATT *peripheral*: advertises BLE_SERVICE and exposes
 *    BLE_CHARACTERISTIC (read + notify) holding the latest snapshot JSON.
 *    Implemented with `cordova-plugin-ble-peripheral` (accessed via its runtime
 *    global so the web bundle never imports it).
 *  - Viewer = GATT *central*: scans for BLE_SERVICE, connects, and subscribes
 *    to notifications. Implemented with `@capacitor-community/bluetooth-le`.
 *
 * NOTE: the peripheral (controller) path requires on-device testing — Android
 * GATT-server behaviour varies by device. It is wrapped defensively so a
 * failure surfaces a friendly error instead of crashing.
 */
export class BleTransport implements SyncTransport {
  label = "Bluetooth (BLE)";
  private viewerDeviceId: string | null = null;
  private peripheral: any = null;

  private getPeripheral() {
    const g = globalThis as any;
    return g?.cordova?.plugins?.blePeripheral ?? g?.blePeripheral ?? null;
  }

  async startController(): Promise<void> {
    const bp = this.getPeripheral();
    if (!bp) {
      throw new Error(
        "BLE peripheral plugin not found. Install cordova-plugin-ble-peripheral and rebuild.",
      );
    }
    this.peripheral = bp;
    const call = (fn: string, ...args: any[]) =>
      new Promise<any>((resolve, reject) => {
        try {
          bp[fn](...args, resolve, reject);
        } catch (e) {
          reject(e);
        }
      });

    // Property/permission bit flags from the BLE spec.
    const READ = 0x02;
    const NOTIFY = 0x10;
    const PERM_READ = 0x01;

    await call("createService", BLE_SERVICE);
    await call(
      "addCharacteristic",
      BLE_SERVICE,
      BLE_CHARACTERISTIC,
      READ | NOTIFY,
      PERM_READ,
    );
    await call("publishService", BLE_SERVICE);
    await call("startAdvertising", BLE_SERVICE, "TT Scoreboard");
  }

  async send(payload: string): Promise<void> {
    if (!this.peripheral) return;
    const bp = this.peripheral;
    await new Promise<void>((resolve) => {
      try {
        bp.setCharacteristicValue(
          BLE_SERVICE,
          BLE_CHARACTERISTIC,
          strToDataView(payload).buffer,
          () => resolve(),
          () => resolve(),
        );
      } catch (_) {
        resolve();
      }
    });
  }

  async startViewer(onPayload: (payload: string) => void): Promise<void> {
    await BleClient.initialize({ androidNeverForLocation: true });
    // Let the user pick the advertising controller device.
    const device = await BleClient.requestDevice({ services: [BLE_SERVICE] });
    this.viewerDeviceId = device.deviceId;
    await BleClient.connect(device.deviceId, () => {
      this.viewerDeviceId = null;
    });
    // Read the current value immediately, then subscribe to changes.
    try {
      const initial = await BleClient.read(
        device.deviceId,
        BLE_SERVICE,
        BLE_CHARACTERISTIC,
      );
      const s = dataViewToStr(initial);
      if (s) onPayload(s);
    } catch (_) {
      /* characteristic may be notify-only */
    }
    await BleClient.startNotifications(
      device.deviceId,
      BLE_SERVICE,
      BLE_CHARACTERISTIC,
      (value) => {
        const s = dataViewToStr(value);
        if (s) onPayload(s);
      },
    );
  }

  async stop(): Promise<void> {
    // Viewer cleanup
    if (this.viewerDeviceId) {
      try {
        await BleClient.stopNotifications(
          this.viewerDeviceId,
          BLE_SERVICE,
          BLE_CHARACTERISTIC,
        );
      } catch (_) {}
      try {
        await BleClient.disconnect(this.viewerDeviceId);
      } catch (_) {}
      this.viewerDeviceId = null;
    }
    // Controller cleanup
    if (this.peripheral) {
      try {
        this.peripheral.stopAdvertising?.(() => {}, () => {});
      } catch (_) {}
      this.peripheral = null;
    }
  }
}

// Keep ScanResult referenced for type consumers / future scan-list UI.
export type { ScanResult };
