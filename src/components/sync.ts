import type { GameConfig, MatchState } from "./common";

// Channel / BLE identifiers shared by controller and viewer.
export const SYNC_CHANNEL = "tt-scoreboard-sync";
// 128-bit UUIDs for the BLE GATT service + characteristic (random, app-specific).
export const BLE_SERVICE = "7f3e0001-9b2a-4c5d-8e6f-1a2b3c4d5e6f";
export const BLE_CHARACTERISTIC = "7f3e0002-9b2a-4c5d-8e6f-1a2b3c4d5e6f";

/**
 * Compact, display-only snapshot of a match, sent to spectator screens.
 * Short keys keep the BLE payload well under the ~512 byte attribute limit.
 */
export type Snapshot = {
  p1n: string; p1p: string; p1s: number; p1g: number; p1y: number;
  p2n: string; p2p: string; p2s: number; p2g: number; p2y: number;
  sw: boolean; // swapped
  fs: number; // firstServer
  dss: number; // doublesServerStart
  ta: boolean; tp: number; tr: number; // timeout active / player / remaining
  htn: string; vtn: string; hts: number; vts: number; // team names + scores
  tm: number; cmn: number; // totalMatches, currentMatchNumber
  ws: number; ml: number; db: boolean; ss: boolean; mt: string; // winningScore, matchLength, doubles, showServer, matchType
  gl: { a: number; b: number }[]; // per-game scoreline (a=player1, b=player2)
};

export function makeSnapshot(state: MatchState, config: GameConfig): Snapshot {
  return {
    p1n: state.player1.name,
    p1p: state.player1.partnerName,
    p1s: state.player1.score,
    p1g: state.player1.games,
    p1y: state.player1.yellowCards,
    p2n: state.player2.name,
    p2p: state.player2.partnerName,
    p2s: state.player2.score,
    p2g: state.player2.games,
    p2y: state.player2.yellowCards,
    sw: state.swapped,
    fs: state.firstServer,
    dss: state.doublesServerStart,
    ta: state.timeoutActive,
    tp: state.timeoutPlayer,
    tr: state.timeoutRemaining,
    htn: state.homeTeamName,
    vtn: state.visitorTeamName,
    hts: state.homeTeamScore,
    vts: state.visitorTeamScore,
    tm: state.totalMatches,
    cmn: state.currentMatchNumber,
    ws: config.winningScore,
    ml: config.matchLength,
    db: config.doubles,
    ss: config.showServer,
    mt: config.matchType,
    gl: state.gameLog.map((g) => ({ a: g.player1Score, b: g.player2Score })),
  };
}

export type SyncRole = "off" | "controller" | "viewer";

/**
 * A transport moves serialized snapshots from the controller device to one or
 * more viewer devices. Implementations: BroadcastChannel (same browser, for
 * testing / a second window) and BLE (across devices on native Android).
 */
export interface SyncTransport {
  readonly label: string;
  startController(): Promise<void>;
  send(payload: string): Promise<void> | void;
  startViewer(onPayload: (payload: string) => void): Promise<void>;
  stop(): Promise<void> | void;
}

/** Same-browser transport — lets a second window/tab mirror the board. */
export class BroadcastChannelTransport implements SyncTransport {
  label = "Local window (BroadcastChannel)";
  private ch: BroadcastChannel | null = null;

  async startController() {
    this.ch = new BroadcastChannel(SYNC_CHANNEL);
  }
  send(payload: string) {
    this.ch?.postMessage(payload);
  }
  async startViewer(onPayload: (payload: string) => void) {
    this.ch = new BroadcastChannel(SYNC_CHANNEL);
    this.ch.onmessage = (e) => {
      if (typeof e.data === "string") onPayload(e.data);
    };
  }
  async stop() {
    this.ch?.close();
    this.ch = null;
  }
}

/**
 * Pick the best transport for the current platform. On native Android we use
 * BLE (loaded lazily so the web build never imports the native plugin);
 * everywhere else we fall back to BroadcastChannel.
 */
export async function createTransport(): Promise<SyncTransport> {
  try {
    const { Capacitor } = await import("@capacitor/core");
    if (Capacitor?.isNativePlatform?.()) {
      const { BleTransport } = await import("./bleTransport");
      return new BleTransport();
    }
  } catch (_) {
    /* @capacitor/core not available in this context — use the web transport */
  }
  return new BroadcastChannelTransport();
}
