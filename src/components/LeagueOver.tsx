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
      class="max-w-5xl mx-auto px-4 mb-96 text-white"
      data-testid="league-end-screen"
    >
      <header class="w-full flex justify-center text-center pt-20 flex-col">
        <h1
          class="text-6xl font-normal font-sports tracking-wider"
          data-testid="winner-text"
        >
          {winnerTeam()}
        </h1>
        <h2
          class="pt-2 text-6xl font-normal font-sports tracking-wider"
          data-testid="wins-the-league"
        >
          Wins
        </h2>
      </header>
      <div class="flex justify-center w-full text-center mt-6">
        <h4 class="text-4xl font-normal font-sports px-4 border-b-4 border-black pb-2 tracking-wider">
          Final Match Score
        </h4>
      </div>
      <section class="flex px-4 max-w-2xl -mt-12 mx-auto justify-center space-x-8">
        <div class="text-center">
          <div class="text-xl font-sports mb-4 text-blue-800">
            {props.matchState.homeTeamName || "Home Team"}
          </div>
          <div
            class="text-[15rem] tracking-wider font-seven md:text-[21rem]"
            data-testid="home-team-score"
          >
            {props.matchState.homeTeamScore}
          </div>
        </div>
        <div class="text-[15rem] md:text-[21rem] font-seven">-</div>
        <div class="text-center">
          <div class="text-xl font-sports mb-4 text-red-800">
            {props.matchState.visitorTeamName || "Visitor Team"}
          </div>
          <div
            class="text-[15rem] font-seven tracking-wider md:text-[21rem]"
            data-testid="visitor-team-score"
          >
            {props.matchState.visitorTeamScore}
          </div>
        </div>
      </section>
      <section class="mt-2 flex w-full justify-center">
        <h6 class="font-mono font-bold uppercase text-2xl text-center">
          Press any key to start a new match
        </h6>
      </section>
      <section class="mx-auto mt-2 px-8 flex justify-center">
        <button
          class="font-mono text-2xl uppercase bg-white text-black border-t-0 border-l-0 border-b-4 border-r-4 border-black px-8 py-2 font-bold active:border-b-0 active:border-r-0 active:border-t-4 active:border-l-4 selectable"
          onClick={() => props.newMatch()}
          data-testid="new-league-button"
        >
          New Match
        </button>
      </section>
    </div>
  );
}