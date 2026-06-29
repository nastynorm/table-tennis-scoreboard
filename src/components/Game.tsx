import {
  createSignal,
  createEffect,
  Switch,
  Match,
  onMount,
  Show,
} from "solid-js";
import { createStore } from "solid-js/store";
import {
  GameMode,
  type MatchState,
  type GameConfig,
  type MatchType,
  defaultGameConfig,
  generatePlayerNames,
} from "./common";
import PlayingGame from "./PlayingGame";
import MatchTypeModal from "./MatchTypeModal";
import SpectatorBoard from "./SpectatorBoard";
import CastHelpModal from "./CastHelpModal";
import {
  createTransport,
  makeSnapshot,
  type Snapshot,
  type SyncRole,
  type SyncTransport,
} from "./sync";
import GameOver from "./GameOver";
import SwitchingSides from "./SwitchingSides";
import MatchOver from "./MatchOver";
import LeagueOver from "./LeagueOver";
import Setup from "./Setup";
import Menu from "./Menu";

// TODO: make option to download match data
// TODO: load initial config from localStorage
//

export default function Game() {
  const [mode, setMode] = createSignal<GameMode>(GameMode.Game);
  const [showMatchTypeModal, setShowMatchTypeModal] = createSignal(false);
  const [showCastHelp, setShowCastHelp] = createSignal(false);
  // Presentation mode hides all controls for a clean board when mirroring.
  const [presentation, setPresentation] = createSignal(false);
  // Second-screen sync (controller broadcasts, viewer mirrors).
  const [syncRole, setSyncRole] = createSignal<SyncRole>("off");
  const [viewerSnap, setViewerSnap] = createSignal<Snapshot | null>(null);
  let transport: SyncTransport | null = null;
  let heartbeat: ReturnType<typeof setInterval> | null = null;
  const [matchState, setMatchState] = createStore<MatchState>({
    player1: {
      name: "Player 1",
      score: 0,
      games: 0,
      timeoutsUsed: 0,
      yellowCards: 0,
      partnerName: "Partner 1",
    },
    player2: {
      name: "Player 2",
      score: 0,
      games: 0,
      timeoutsUsed: 0,
      yellowCards: 0,
      partnerName: "Partner 2",
    },
    // A game is an object with keys winner, player1score, and player2score
    gameLog: [],
    swapped: false,
    timeoutActive: false,
    timeoutPlayer: 0,
    timeoutRemaining: 0,
    firstServer: 1,
    doublesServerStart: 0,
    homeTeamName: "Home Team",
    visitorTeamName: "Visitor Team",
    homeTeamScore: 0,
    visitorTeamScore: 0,
    totalMatches: 7,
    currentMatchNumber: 1,
  });
  const [config, setConfig] = createStore<GameConfig>({
    ...defaultGameConfig,
  });

  onMount(() => {
    if (globalThis.localStorage) {
      const loadedConfig = JSON.parse(localStorage.getItem("config") ?? "{}");
      if (loadedConfig instanceof Object) {
        // Defaults first so newly-added keys are present, then the saved values
        // override them (so a saved config actually persists across reloads).
        setConfig({
          ...defaultGameConfig,
          ...loadedConfig,
        });
      }
      const player1Name = localStorage.getItem("player1Name");
      const player2Name = localStorage.getItem("player2Name");
      const player1Partner = localStorage.getItem("player1Partner");
      const player2Partner = localStorage.getItem("player2Partner");
      const homeTeamName = localStorage.getItem("homeTeamName");
      const visitorTeamName = localStorage.getItem("visitorTeamName");
      const totalMatches = localStorage.getItem("totalMatches");

      setMatchState((state) => ({
        ...state,
        player1: {
          ...state.player1,
          name: player1Name ?? state.player1.name,
          partnerName: player1Partner ?? state.player1.partnerName,
        },
        player2: {
          ...state.player2,
          name: player2Name ?? state.player2.name,
          partnerName: player2Partner ?? state.player2.partnerName,
        },
        homeTeamName: homeTeamName ?? state.homeTeamName,
        visitorTeamName: visitorTeamName ?? state.visitorTeamName,
        totalMatches: totalMatches ? parseInt(totalMatches, 10) : state.totalMatches,
      }));
    }
  });

  const newGame = () => {
    setMatchState((state) => ({
      ...state,
      swapped: config.switchSides ? !state.swapped : state.swapped,
      player1: {
        ...state.player1,
        score: 0,
      },
      player2: {
        ...state.player2,
        score: 0,
      },
      timeoutActive: false,
      timeoutPlayer: 0,
      timeoutRemaining: 0,
      // The receiver of the previous game serves first in the next one.
      firstServer: state.firstServer === 1 ? 2 : 1,
    }));
    if (config.switchSides) {
      setMode(GameMode.SwitchingSides);
      setTimeout(() => {
        setMode(GameMode.Game);
      }, 3000);
    } else {
      setMode(GameMode.Game);
    }
  };
  const newMatch = () => {
    setMode(GameMode.Game);
    setMatchState((state) => {
      // Generate initial player names for league format
      const homeTeamName = state.homeTeamName || "Home";
      const visitorTeamName = state.visitorTeamName || "Visitor";
      const initialPlayer1Name = `H1`;
    const initialPlayer2Name = `V1`;
      
      return {
        player1: {
          name: initialPlayer1Name,
          score: 0,
          games: 0,
          timeoutsUsed: 0,
          yellowCards: 0,
          partnerName: state.player1.partnerName,
        },
        player2: {
          name: initialPlayer2Name,
          score: 0,
          games: 0,
          timeoutsUsed: 0,
          yellowCards: 0,
          partnerName: state.player2.partnerName,
        },
        gameLog: [],
        swapped: false,
        timeoutActive: false,
        timeoutPlayer: 0,
        timeoutRemaining: 0,
        firstServer: 1,
        doublesServerStart: 0,
        homeTeamName: state.homeTeamName,
        visitorTeamName: state.visitorTeamName,
        homeTeamScore: 0,
        visitorTeamScore: 0,
        totalMatches: state.totalMatches,
        currentMatchNumber: 1,
      };
    });
  };

  // League only: after a sub-match is won (MatchOver), advance to the next
  // fixture, or finish the league night.
  const advanceLeague = () => {
    setMatchState((state) => {
      const next = state.currentMatchNumber + 1;
      if (next > (state.totalMatches || 7)) {
        setMode(GameMode.LeagueOver);
        return state;
      }
      const { player1Name, player2Name } = generatePlayerNames(next);
      setMode(GameMode.Game);
      return {
        ...state,
        player1: { ...state.player1, name: player1Name, games: 0, score: 0, yellowCards: 0 },
        player2: { ...state.player2, name: player2Name, games: 0, score: 0, yellowCards: 0 },
        gameLog: [],
        swapped: false,
        timeoutActive: false,
        timeoutPlayer: 0,
        timeoutRemaining: 0,
        firstServer: 1,
        doublesServerStart: 0,
        currentMatchNumber: next,
      };
    });
  };

  // Start a brand-new match of the chosen format (driven by the modal).
  const startMatch = (type: MatchType) => {
    setShowMatchTypeModal(false);
    setConfig("matchType", type);
    if (globalThis.localStorage) {
      localStorage.setItem(
        "config",
        JSON.stringify({ ...config, matchType: type }),
      );
    }
    if (type === "league") {
      // League night keeps its Home/Visitor fixture flow.
      newMatch();
      return;
    }
    // normal / knockout / summer: a fresh single match keeping configured names.
    setMatchState((state) => ({
      ...state,
      player1: { ...state.player1, score: 0, games: 0, yellowCards: 0 },
      player2: { ...state.player2, score: 0, games: 0, yellowCards: 0 },
      gameLog: [],
      swapped: false,
      timeoutActive: false,
      timeoutPlayer: 0,
      timeoutRemaining: 0,
      firstServer: 1,
      doublesServerStart: 0,
      homeTeamScore: 0,
      visitorTeamScore: 0,
      currentMatchNumber: 1,
    }));
    setMode(GameMode.Game);
  };

  // --- Second-screen sync ---
  const stopSync = async () => {
    if (heartbeat) {
      clearInterval(heartbeat);
      heartbeat = null;
    }
    if (transport) {
      try {
        await transport.stop();
      } catch (_) {}
      transport = null;
    }
    setSyncRole("off");
    setViewerSnap(null);
  };

  const startController = async () => {
    await stopSync();
    try {
      transport = await createTransport();
      await transport.startController();
      setSyncRole("controller");
      const push = () =>
        transport?.send(JSON.stringify(makeSnapshot(matchState, config)));
      push();
      heartbeat = setInterval(push, 1500);
    } catch (e) {
      await stopSync();
      if (globalThis.alert) alert("Could not start broadcasting: " + (e as Error).message);
    }
  };

  const startViewer = async () => {
    await stopSync();
    try {
      transport = await createTransport();
      setSyncRole("viewer");
      await transport.startViewer((payload) => {
        try {
          setViewerSnap(JSON.parse(payload) as Snapshot);
        } catch (_) {}
      });
    } catch (e) {
      await stopSync();
      if (globalThis.alert) alert("Could not start viewer: " + (e as Error).message);
    }
  };

  // Whenever the screen (mode) changes, jump back to the top so result
  // headings like "<Player> Wins the Match" are always visible.
  createEffect(() => {
    mode();
    if (globalThis.scrollTo) globalThis.scrollTo(0, 0);
  });

  // Push a fresh snapshot to viewers whenever the match state changes.
  createEffect(() => {
    const snap = makeSnapshot(matchState, config);
    if (syncRole() === "controller" && transport) {
      transport.send(JSON.stringify(snap));
    }
  });

  // URL-driven startup (used by the Raspberry Pi dual-screen kiosk):
  //   ?screen=control          -> auto-broadcast (the touch control screen)
  //   ?screen=viewer           -> auto-spectator (the big HDMI screen)
  //   ?present=1               -> start in presentation (button-free) mode
  //   ?spawnViewer=1&vx&vy&vw&vh-> control window opens the spectator window on
  //                               the 2nd display (same browser instance, so it
  //                               stays in sync over BroadcastChannel).
  onMount(() => {
    if (!globalThis.location) return;
    const p = new URLSearchParams(globalThis.location.search);
    if (p.get("present") === "1") setPresentation(true);
    const screen = p.get("screen");
    if (screen === "viewer") {
      startViewer();
    } else if (screen === "control") {
      startController();
      if (p.get("spawnViewer") === "1" && globalThis.open) {
        const vx = p.get("vx") ?? "800";
        const vy = p.get("vy") ?? "0";
        const vw = p.get("vw") ?? "1280";
        const vh = p.get("vh") ?? "768";
        globalThis.open(
          "?screen=viewer",
          "ttsViewer",
          `left=${vx},top=${vy},width=${vw},height=${vh}`,
        );
      }
    }
  });

  return (
    <Show
      when={syncRole() !== "viewer"}
      fallback={
        <div class="relative">
          <SpectatorBoard snapshot={viewerSnap()} />
          <button
            type="button"
            class="fixed top-3 right-3 z-[70] py-2 px-4 font-mono font-bold text-black uppercase bg-white rounded-lg shadow-lg"
            onClick={() => stopSync()}
            data-testid="exit-viewer-button"
          >
            Exit Viewer
          </button>
        </div>
      }
    >
    <div
      classList={{
        "transition-colors duration-300": true,
        // Fit the whole app to the screen (no vertical scroll) except the Setup
        // form, which is allowed to scroll.
        "h-[100dvh] overflow-hidden": mode() !== GameMode.Setup,
        "min-h-screen overflow-y-auto": mode() === GameMode.Setup,
        "bg-gradient-to-br from-slate-900 via-slate-950 to-black":
          mode() === GameMode.Game,
        "bg-gradient-to-br from-rose-950 via-slate-950 to-black":
          mode() === GameMode.Correction,
        "bg-gradient-to-br from-emerald-900 via-slate-950 to-black": // game completion states
          mode() === GameMode.GameOver ||
          mode() === GameMode.MatchOver ||
          mode() === GameMode.LeagueOver ||
          mode() === GameMode.SwitchingSides,
        "bg-gradient-to-br from-sky-100 to-slate-200": mode() === GameMode.Setup,
      }}
      id="main-content"
    >
      <div
        classList={{
          "px-3 sm:px-6 mx-auto w-full max-w-[1700px] text-white": true,
          "h-full": mode() !== GameMode.Setup,
          "min-h-screen": mode() === GameMode.Setup,
        }}
      >
        <Switch fallback={<div>Not Implemented</div>}>
          <Match
            when={mode() === GameMode.Game || mode() === GameMode.Correction}
          >
            <PlayingGame
              mode={mode()}
              setMode={setMode}
              setMatchState={setMatchState}
              config={config}
              matchState={matchState}
              presentation={presentation()}
            />
          </Match>
          <Match when={mode() === GameMode.GameOver}>
            <GameOver matchState={matchState} newGame={newGame} />
          </Match>
          <Match when={mode() === GameMode.SwitchingSides}>
            <SwitchingSides setMode={setMode} />
          </Match>
          <Match when={mode() === GameMode.MatchOver}>
            <MatchOver
              newMatch={
                config.matchType === "league"
                  ? advanceLeague
                  : () => setShowMatchTypeModal(true)
              }
              matchState={matchState}
            />
          </Match>
          <Match when={mode() === GameMode.LeagueOver}>
            <LeagueOver
              newMatch={() => setShowMatchTypeModal(true)}
              matchState={matchState}
            />
          </Match>
          <Match when={mode() === GameMode.Setup}>
            <Setup
              config={config}
              setConfig={setConfig}
              setMode={setMode}
              matchState={matchState}
              setMatchState={setMatchState}
            />
          </Match>
        </Switch>
      </div>

      <Show when={mode() !== GameMode.Setup}>
        <Menu>
          <ul class="min-w-28 max-h-[85dvh] overflow-y-auto text-center bg-white rounded-lg shadow-xl text-black font-mono font-bold divide-y divide-gray-200">
            <li class="p-2">
              <a href="/help" target="_blank" data-testid="help-button">
                Help
              </a>
            </li>
            <li class="p-2">
              <button
                class="cursor-pointer"
                onClick={() => setShowMatchTypeModal(true)}
                title="Start a new match"
                data-testid="new-match-menu-button"
              >
                New Match
              </button>
            </li>
            <li class="p-2">
              <button
                class="cursor-pointer"
                onClick={() => setMode(GameMode.Setup)}
                title="Configure Match Settings"
                data-testid="setup-button"
              >
                Setup
              </button>
            </li>
            <li class="p-2">
              <Show
                when={syncRole() === "controller"}
                fallback={
                  <button
                    class="cursor-pointer"
                    onClick={() => startController()}
                    title="Broadcast this scoreboard to a second screen"
                    data-testid="broadcast-button"
                  >
                    Broadcast
                  </button>
                }
              >
                <button
                  class="cursor-pointer text-rose-600"
                  onClick={() => stopSync()}
                  title="Stop broadcasting"
                  data-testid="stop-broadcast-button"
                >
                  Stop Broadcast
                </button>
              </Show>
            </li>
            <li class="p-2">
              <button
                class="cursor-pointer"
                onClick={() => startViewer()}
                title="Mirror another device's scoreboard"
                data-testid="view-screen-button"
              >
                View 2nd Screen
              </button>
            </li>
            <li class="p-2">
              <button
                class="cursor-pointer"
                onClick={() => setPresentation((p) => !p)}
                title="Hide controls for a clean board when mirroring"
                data-testid="presentation-toggle-button"
              >
                {presentation() ? "Exit Presentation" : "Presentation Mode"}
              </button>
            </li>
            <li class="p-2">
              <button
                class="cursor-pointer"
                onClick={() => setShowCastHelp(true)}
                title="How to show the scoreboard on a big screen"
                data-testid="cast-help-button"
              >
                Cast / 2nd Screen
              </button>
            </li>
          </ul>
        </Menu>
      </Show>

      <Show when={showCastHelp()}>
        <CastHelpModal onClose={() => setShowCastHelp(false)} />
      </Show>

      <Show when={syncRole() === "controller"}>
        <div
          class="fixed top-3 left-3 z-50 flex items-center gap-2 py-1 px-3 rounded-full bg-emerald-500/90 text-black font-mono text-sm font-bold shadow-lg"
          data-testid="broadcasting-indicator"
        >
          <span class="w-2 h-2 rounded-full bg-black animate-pulse" />
          Broadcasting
        </div>
      </Show>

      <Show when={showMatchTypeModal()}>
        <MatchTypeModal
          current={config.matchType}
          onSelect={startMatch}
          onClose={() => setShowMatchTypeModal(false)}
        />
      </Show>
    </div>
    </Show>
  );
}

// swap sides button in menu
//<button
//  class="py-2 px-4 font-mono font-bold text-black uppercase bg-white border border-r-4 border-b-4 border-black active:border-r-0 active:border-b-0 active:border-t-4 active:border-l-4 border-t border-l selectable"
//  onClick={() =>
//    setMatchState((state) => ({ ...state, swapped: !state.swapped }))
//  }
//  title="Correct a scoring mistake"
//  data-testid="end-correction-button"
//>
//  swap
//</button>
/*
 *
      {mode() !== GameMode.Setup && (
        <>
          <div
            id="help"
            class="fixed bottom-0 right-1/2 mb-4 transform translate-x-1/2"
          >
            <a
              class="block py-2 px-4 font-mono font-bold text-black uppercase bg-white border border-r-4 border-b-4 border-black active:border-r-0 active:border-b-0 active:border-t-4 active:border-l-4 border-t border-l selectable"
              href="/help"
              target="_blank"
              data-testid="help-button"
            >
              Help
            </a>
          </div>
          <div id="config" class="fixed right-0 bottom-0 mr-4 mb-4">
            <button
              class="py-2 px-4 font-mono font-bold text-black uppercase bg-white border border-r-4 border-b-4 border-black active:border-r-0 active:border-b-0 active:border-t-4 active:border-l-4 border-t border-l-1 selectable"
              onClick={() => setMode(GameMode.Setup)}
              title="Configure Match Settings"
              data-testid="setup-button"
            >
              Setup
            </button>
          </div>
        </>
      )}
*/
