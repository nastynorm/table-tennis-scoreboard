import { onCleanup, onMount } from "solid-js";
import type { SetStoreFunction } from "solid-js/store";
import type { GameConfig, MatchState } from "./common";
import WaterBreakTimer from "./WaterBreakTimer";
import { buzzer, countdownTick, unlockAudio } from "./sounds";

interface GameOverProps {
  matchState: MatchState;
  setMatchState: SetStoreFunction<MatchState>;
  config: GameConfig;
  newGame: Function;
}
export default function GameOver(props: GameOverProps) {
  const winnerName = () => {
    // Get the winner from the last game in the log
    const lastGame = props.matchState.gameLog[props.matchState.gameLog.length - 1];
    return lastGame ? lastGame.winner.name : props.matchState.player1.name;
  };

  let ticker: ReturnType<typeof setInterval> | null = null;

  const clearTicker = () => {
    if (ticker) {
      clearInterval(ticker);
      ticker = null;
    }
  };

  // Start the between-games water break countdown. Ticks for the final 10
  // seconds, sounds a buzzer at zero, then moves on to the next game.
  const startBreak = () => {
    if (props.matchState.waterBreakActive) return;
    unlockAudio(); // this runs inside a user gesture, so audio is allowed
    props.setMatchState((state) => ({
      ...state,
      waterBreakActive: true,
      waterBreakRemaining: props.config.breakDuration,
    }));
    ticker = setInterval(() => {
      const next = props.matchState.waterBreakRemaining - 1;
      if (next <= 0) {
        clearTicker();
        props.setMatchState((state) => ({
          ...state,
          waterBreakActive: false,
          waterBreakRemaining: 0,
        }));
        buzzer();
        props.newGame();
        return;
      }
      props.setMatchState((state) => ({ ...state, waterBreakRemaining: next }));
      if (next <= 10) countdownTick(next);
    }, 1000);
  };

  // Skip the break and go straight to the next game.
  const skipBreak = () => {
    clearTicker();
    props.setMatchState((state) => ({
      ...state,
      waterBreakActive: false,
      waterBreakRemaining: 0,
    }));
    props.newGame();
  };

  // A key/remote press advances straight to the next game (skipping any break),
  // so an umpire with a Bluetooth remote isn't forced to sit through it.
  const handleKeyUp = (ev: KeyboardEvent) => {
    ev.preventDefault();
    skipBreak();
  };

  onMount(() => {
    document.addEventListener("keyup", handleKeyUp);
  });
  onCleanup(() => {
    document.removeEventListener("keyup", handleKeyUp);
    clearTicker();
  });

  return (
    <div
      class="h-full flex flex-col items-center justify-center gap-2 px-4 text-white cursor-pointer overflow-hidden"
      data-testid="game-end-screen"
      onClick={() => startBreak()}
      title="Tap anywhere for a water break"
    >
      <h1
        class="text-4xl md:text-6xl font-normal font-sports tracking-wider text-center"
        data-testid="winner-text"
      >
        {winnerName()} Wins!
      </h1>
      <h4 class="text-xl md:text-3xl font-normal font-sports px-4 border-b-4 border-white/40 pb-1 tracking-wider">
        Final Score
      </h4>
      <section class="flex justify-center items-center gap-6 font-bold">
        <div class="result-digits font-seven" data-testid="player1-score">
          {props.matchState.player1.score}
        </div>
        <div class="result-digits font-seven opacity-60">-</div>
        <div class="result-digits font-seven" data-testid="player2-score">
          {props.matchState.player2.score}
        </div>
      </section>
      <div class="flex items-center gap-3">
        <button
          class="font-mono text-sm md:text-lg uppercase bg-cyan-500 text-white rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] px-5 py-2 font-bold active:translate-y-1 active:shadow-none transition-all flex items-center gap-1"
          onClick={(e) => {
            e.stopPropagation();
            startBreak();
          }}
          data-testid="water-break-button"
        >
          💧 Water Break
        </button>
        <button
          class="font-mono text-lg md:text-2xl uppercase bg-white text-black rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] px-8 py-2 font-bold active:translate-y-1 active:shadow-none transition-all"
          onClick={(e) => {
            e.stopPropagation();
            skipBreak();
          }}
          data-testid="new-game-button"
        >
          Next Game ▸
        </button>
      </div>
      <h6 class="font-mono font-bold uppercase text-sm md:text-base text-center text-white/60">
        Tap anywhere for a water break · Next Game to continue
      </h6>

      <WaterBreakTimer
        remaining={props.matchState.waterBreakRemaining}
        onSkip={skipBreak}
      />
    </div>
  );
}
