import { onCleanup, onMount } from "solid-js";
import type { MatchState } from "./common";


interface GameOverProps {
  matchState: MatchState;
  newGame: Function;
}
export default function GameOver(props: GameOverProps) {
  const winnerName = () => {
    // Get the winner from the last game in the log
    const lastGame = props.matchState.gameLog[props.matchState.gameLog.length - 1];
    return lastGame ? lastGame.winner.name : props.matchState.player1.name;
  };

  const handleKeyUp = (ev: KeyboardEvent) => {
    ev.preventDefault();
    props.newGame();
  };

  onMount(() => {
    document.addEventListener("keyup", handleKeyUp);
  });
  onCleanup(() => {
    document.removeEventListener("keyup", handleKeyUp);
  });

  return (
    <div
      class="h-full flex flex-col items-center justify-center gap-2 px-4 text-white cursor-pointer overflow-hidden"
      data-testid="game-end-screen"
      onClick={() => props.newGame()}
      title="Tap anywhere to continue"
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
      <button
        class="font-mono text-lg md:text-2xl uppercase bg-white text-black rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] px-8 py-2 font-bold active:translate-y-1 active:shadow-none transition-all"
        onClick={(e) => {
          e.stopPropagation();
          props.newGame();
        }}
        data-testid="new-game-button"
      >
        Next Game ▸
      </button>
      <h6 class="font-mono font-bold uppercase text-sm md:text-base text-center text-white/60">
        Tap anywhere to continue
      </h6>
    </div>
  );
}
