import { createSignal, type Setter } from "solid-js";
import { GameMode, type GameConfig, type MatchState } from "./common";

interface SetupProps {
  config: GameConfig;
  setConfig: Setter<GameConfig>;
  setMode: Setter<GameMode>;
  matchState: MatchState;
  setMatchState: Setter<MatchState>;
}

enum Listening {
  None = 0,
  Player1Key = 1,
  Player2Key = 2,
  ScoreCorrectionKey = 3,
  Player1CorrectionKey = 4,
  Player2CorrectionKey = 5,
}

// Setup is now GLOBAL PREFERENCES only. Per-match settings (format, best-of,
// team/player names, doubles) live in the New Match wizard.
export default function Setup(props: SetupProps) {
  let formRef!: HTMLFormElement;

  const [listeningFor, setListeningFor] = createSignal<Listening>(Listening.None);
  const [player1Key, setPlayer1Key] = createSignal(props.config.player1Key);
  const [player2Key, setPlayer2Key] = createSignal(props.config.player2Key);
  const [player1CorrectionKey, setPlayer1CorrectionKey] = createSignal(
    props.config.player1CorrectionKey,
  );
  const [player2CorrectionKey, setPlayer2CorrectionKey] = createSignal(
    props.config.player2CorrectionKey,
  );
  const [scoreCorrectionKey, setScoreCorrectionKey] = createSignal(
    props.config.scoreCorrectionKey,
  );

  const recordKey = (
    setter: (k: string) => void,
    which: Listening,
  ) => {
    const handler = (ev: KeyboardEvent) => {
      ev.preventDefault();
      if (ev.key !== "Escape") setter(ev.key);
      document.removeEventListener("keyup", handler);
      setListeningFor(Listening.None);
    };
    document.addEventListener("keyup", handler);
    setListeningFor(which);
  };

  const saveConfig = (ev: SubmitEvent) => {
    ev.preventDefault();
    const data = new FormData(formRef);

    let winningScore = parseInt(data.get("winningScore") as string, 10);
    if (isNaN(winningScore) || winningScore < 2) winningScore = props.config.winningScore;

    let timeoutDuration = parseInt(data.get("timeoutDuration") as string, 10);
    if (isNaN(timeoutDuration) || timeoutDuration < 5) timeoutDuration = props.config.timeoutDuration;

    let warmupDuration = parseInt(data.get("warmupDuration") as string, 10);
    if (isNaN(warmupDuration) || warmupDuration < 5) warmupDuration = props.config.warmupDuration;

    const switchSides = data.get("switchSides") === "on";
    const showServer = data.get("showServer") === "on";

    // Only touch global keys — leave matchType / matchLength / doubles (per-match)
    // and player/team names alone.
    props.setConfig("winningScore", winningScore);
    props.setConfig("timeoutDuration", timeoutDuration);
    props.setConfig("warmupDuration", warmupDuration);
    props.setConfig("switchSides", switchSides);
    props.setConfig("showServer", showServer);
    props.setConfig("player1Key", player1Key());
    props.setConfig("player2Key", player2Key());
    props.setConfig("scoreCorrectionKey", scoreCorrectionKey());
    props.setConfig("player1CorrectionKey", player1CorrectionKey());
    props.setConfig("player2CorrectionKey", player2CorrectionKey());

    if (globalThis.localStorage) {
      localStorage.setItem(
        "config",
        JSON.stringify({
          ...props.config,
          winningScore,
          timeoutDuration,
          warmupDuration,
          switchSides,
          showServer,
          player1Key: player1Key(),
          player2Key: player2Key(),
          scoreCorrectionKey: scoreCorrectionKey(),
          player1CorrectionKey: player1CorrectionKey(),
          player2CorrectionKey: player2CorrectionKey(),
        }),
      );
    }

    props.setMode(GameMode.Game);
  };

  return (
    <form
      action="#"
      onSubmit={saveConfig}
      id="main-content"
      class="mx-auto pt-8 max-w-2xl text-black pb-24"
      ref={formRef}
    >
      <header class="text-center mb-6">
        <h1 class="text-3xl font-normal font-sports tracking-wider">Settings</h1>
        <p class="font-mono text-sm text-gray-600 mt-1">
          Match format & names are set in <b>New Match</b>. These are global
          preferences.
        </p>
      </header>

      <section class="mb-6">
        <h4 class="mb-2 text-xl font-normal tracking-wider font-sports">
          Scoring Keys
        </h4>
        <p class="font-mono text-xs text-gray-600 mb-3">
          Use a Bluetooth remote or keyboard. Click “Record”, then press the key.
        </p>
        <div class="flex flex-wrap gap-4">
          <RecordKeyInput label="Left Side Scored" listening={listeningFor() === Listening.Player1Key} onRecordKey={() => recordKey(setPlayer1Key, Listening.Player1Key)} keyName={player1Key()} testid="player1-keybind-button" />
          <RecordKeyInput label="Right Side Scored" listening={listeningFor() === Listening.Player2Key} onRecordKey={() => recordKey(setPlayer2Key, Listening.Player2Key)} keyName={player2Key()} testid="player2-keybind-button" />
          <RecordKeyInput label="Correction Mode" listening={listeningFor() === Listening.ScoreCorrectionKey} onRecordKey={() => recordKey(setScoreCorrectionKey, Listening.ScoreCorrectionKey)} keyName={scoreCorrectionKey()} testid="correction-keybind-button" />
          <RecordKeyInput label="Left Correction" listening={listeningFor() === Listening.Player1CorrectionKey} onRecordKey={() => recordKey(setPlayer1CorrectionKey, Listening.Player1CorrectionKey)} keyName={player1CorrectionKey()} testid="player1-correction-keybind-button" />
          <RecordKeyInput label="Right Correction" listening={listeningFor() === Listening.Player2CorrectionKey} onRecordKey={() => recordKey(setPlayer2CorrectionKey, Listening.Player2CorrectionKey)} keyName={player2CorrectionKey()} testid="player2-correction-keybind-button" />
        </div>
      </section>

      <section class="grid sm:grid-cols-2 gap-6 mb-6">
        <div class="flex flex-col gap-2">
          <label for="winningScore" class="text-xl font-normal tracking-wider font-sports">Points to win a game</label>
          <input type="number" id="winningScore" name="winningScore" min="2" value={props.config.winningScore} data-testid="winning-score-input" class="py-2 px-4 w-full font-mono bg-white border-2 border-black focus:outline-none rounded" />
          <p class="font-mono text-xs text-gray-600">Usually 11 (win by 2). Deuce handled automatically.</p>
        </div>
        <div class="flex flex-col gap-2">
          <label for="timeoutDuration" class="text-xl font-normal tracking-wider font-sports">Timeout length (seconds)</label>
          <input type="number" id="timeoutDuration" name="timeoutDuration" min="5" value={props.config.timeoutDuration} data-testid="timeout-duration-input" class="py-2 px-4 w-full font-mono bg-white border-2 border-black focus:outline-none rounded" />
        </div>
        <div class="flex flex-col gap-2">
          <label for="warmupDuration" class="text-xl font-normal tracking-wider font-sports">Warm-up length (seconds)</label>
          <input type="number" id="warmupDuration" name="warmupDuration" min="5" value={props.config.warmupDuration} data-testid="warmup-duration-input" class="py-2 px-4 w-full font-mono bg-white border-2 border-black focus:outline-none rounded" />
          <p class="font-mono text-xs text-gray-600">Shown as a WARM UP button at the start of each match (default 120s).</p>
        </div>
      </section>

      <section class="flex flex-col gap-3 mb-8">
        <label for="switchSides" class="flex gap-4 items-center text-lg font-normal tracking-wider font-sports">
          <input type="checkbox" id="switchSides" name="switchSides" class="w-5 h-5 border-2 border-black" data-testid="switch-sides-input" checked={props.config.switchSides} />
          <span>Switch ends between games</span>
        </label>
        <label for="showServer" class="flex gap-4 items-center text-lg font-normal tracking-wider font-sports">
          <input type="checkbox" id="showServer" name="showServer" class="w-5 h-5 border-2 border-black" data-testid="show-server-input" checked={props.config.showServer} />
          <span>Show serve indicator</span>
        </label>
      </section>

      <section class="flex flex-row-reverse gap-4">
        <button type="submit" class="py-2 px-8 font-mono text-xl font-bold text-white uppercase bg-green-600 rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] active:translate-y-1 active:shadow-none transition-all" data-testid="setup-done-button">
          Done
        </button>
        <button type="button" class="py-2 px-8 font-mono text-xl font-bold text-white uppercase bg-red-600 rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] active:translate-y-1 active:shadow-none transition-all" onClick={() => props.setMode(GameMode.Game)}>
          Cancel
        </button>
      </section>
    </form>
  );
}

interface RecordKeyInputProps {
  listening: boolean;
  keyName: string;
  label: string;
  onRecordKey: () => void;
  testid: string;
}

function RecordKeyInput(props: RecordKeyInputProps) {
  return (
    <div class="flex flex-col gap-1 items-center">
      <span class="tracking-wider text-black font-sports text-sm">{props.label}</span>
      <div class="w-32 text-center bg-gray-200 py-1 font-bold border-2 border-black rounded">
        {props.listening ? "Recording..." : props.keyName}
      </div>
      <button class="py-1.5 px-4 font-mono font-bold text-white uppercase bg-slate-700 rounded shadow-[0_3px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all" data-testid={props.testid} type="button" onClick={() => props.onRecordKey()}>
        Record
      </button>
    </div>
  );
}
