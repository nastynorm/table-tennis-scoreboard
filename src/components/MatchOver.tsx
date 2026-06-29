import { onCleanup, onMount } from "solid-js";
import type { MatchState } from "./common";

interface MatchOverProps {
  matchState: MatchState;
  newMatch: Function;
}
export default function MatchOver(props: MatchOverProps) {
  const winnerName = () =>
    props.matchState.player1.games > props.matchState.player2.games
      ? props.matchState.player1.name
      : props.matchState.player2.name;

  const handleKeyUp = (ev: KeyboardEvent) => {
    ev.preventDefault();
    props.newMatch();
  };

  onMount(() => {
    if (globalThis.addEventListener) {
      globalThis.addEventListener("keyup", handleKeyUp);
    }
  });
  onCleanup(() => {
    if (globalThis.removeEventListener) {
      globalThis.removeEventListener("keyup", handleKeyUp);
    }
  });

  return (
    <div
      class="h-full flex flex-col items-center justify-center gap-1 px-4 text-white cursor-pointer overflow-hidden"
      data-testid="match-end-screen"
      onClick={() => props.newMatch()}
      title="Tap anywhere to continue"
    >
      <h1
        class="text-3xl md:text-5xl font-normal font-sports tracking-wider text-center"
        data-testid="winner-text"
      >
        {winnerName()}
      </h1>
      <h2
        class="text-2xl md:text-4xl font-normal font-sports tracking-wider"
        data-testid="wins-the-match"
      >
        Wins the Match
      </h2>
      <h4 class="text-lg md:text-2xl font-normal font-sports px-4 border-b-4 border-white/40 pb-1 tracking-wider">
        Final Standing
      </h4>
      <section class="flex justify-center items-center gap-6">
        <div class="result-digits tracking-wider font-seven" data-testid="player1-games">
          {props.matchState.player1.games}
        </div>
        <div class="result-digits font-seven opacity-60">-</div>
        <div class="result-digits font-seven tracking-wider" data-testid="player2-games">
          {props.matchState.player2.games}
        </div>
      </section>
      <button
        class="font-mono text-lg md:text-2xl uppercase bg-white text-black rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] px-8 py-2 font-bold active:translate-y-1 active:shadow-none transition-all"
        onClick={(e) => {
          e.stopPropagation();
          props.newMatch();
        }}
        data-testid="new-match-button"
      >
        Continue ▸
      </button>
      <h6 class="font-mono font-bold uppercase text-sm md:text-base text-center text-white/60">
        Tap anywhere to continue
      </h6>
    </div>
  );
}
