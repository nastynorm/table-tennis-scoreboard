import { onCleanup, onMount } from "solid-js";
import type { MatchState } from "./common";

interface LeagueOverProps {
  matchState: MatchState;
  newMatch: Function;
}

export default function LeagueOver(props: LeagueOverProps) {
  const winnerTeam = () =>
    props.matchState.homeTeamScore > props.matchState.visitorTeamScore
      ? props.matchState.homeTeamName || "Home Team"
      : props.matchState.visitorTeamName || "Visitor Team";

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
      data-testid="league-end-screen"
      onClick={() => props.newMatch()}
      title="Tap anywhere to continue"
    >
      <h1
        class="text-3xl md:text-5xl font-normal font-sports tracking-wider text-center"
        data-testid="winner-text"
      >
        {winnerTeam()}
      </h1>
      <h2
        class="text-2xl md:text-4xl font-normal font-sports tracking-wider"
        data-testid="wins-the-league"
      >
        Wins
      </h2>
      <h4 class="text-lg md:text-2xl font-normal font-sports px-4 border-b-4 border-white/40 pb-1 tracking-wider">
        Final Match Score
      </h4>
      <section class="flex justify-center items-center gap-6">
        <div class="text-center">
          <div class="result-digits tracking-wider font-seven" data-testid="home-team-score">
            {props.matchState.homeTeamScore}
          </div>
          <div class="text-sm md:text-lg font-sports text-sky-300">
            {props.matchState.homeTeamName || "Home Team"}
          </div>
        </div>
        <div class="result-digits font-seven opacity-60">-</div>
        <div class="text-center">
          <div class="result-digits font-seven tracking-wider" data-testid="visitor-team-score">
            {props.matchState.visitorTeamScore}
          </div>
          <div class="text-sm md:text-lg font-sports text-rose-300">
            {props.matchState.visitorTeamName || "Visitor Team"}
          </div>
        </div>
      </section>
      <button
        class="font-mono text-lg md:text-2xl uppercase bg-white text-black rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] px-8 py-2 font-bold active:translate-y-1 active:shadow-none transition-all"
        onClick={(e) => {
          e.stopPropagation();
          props.newMatch();
        }}
        data-testid="new-league-button"
      >
        New League ▸
      </button>
      <h6 class="font-mono font-bold uppercase text-sm md:text-base text-center text-white/60">
        Tap anywhere to continue
      </h6>
    </div>
  );
}