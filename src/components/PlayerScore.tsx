import { GameMode } from "./common";

interface PlayerScoreProps {
  mode: GameMode;
  showBorder: boolean;
  name: string;
  reverse: boolean;
  score: number;
  games: number;
  onScore: Function;
  onCorrection: Function;
  testid: string;
  redNumber: boolean;
  // Timeout props
  player: number;
  timeoutsUsed: number;
  onTimeout: (player: number) => void;
  timeoutActive: boolean;
}

export default function PlayerScore(props: PlayerScoreProps) {
  return (
    <div
      classList={{
        "ltr flex flex-col font-sports tracking-wider mt-20": true,
        "border-r-2 border-white": props.showBorder,
      }}
    >
      <div class="mb-8 w-full text-3xl font-medium tracking-wider text-center md:text-5xl xl:text-7xl">
        <div class="flex items-center justify-center gap-4">
          <span
            class="px-8 pb-2 w-auto border-b-4 border-white"
            data-testid={`${props.testid}-name`}
          >
            {props.name}
          </span>
          {props.timeoutsUsed === 0 && !props.timeoutActive && (
            <button
              class="w-12 h-12 text-xl font-bold text-black bg-green-500 border-2 border-black rounded-full hover:bg-green-400 active:bg-green-600 transition-colors duration-150 flex items-center justify-center"
              onClick={() => props.onTimeout(props.player)}
              data-testid={`${props.testid}-timeout-button`}
              title="Call Timeout (1 per match)"
            >
              T
            </button>
          )}
        </div>
      </div>
      <div classList={{ "flex mx-4": true, "flex-row-reverse": props.reverse }}>
        <div class="flex-col items-center w-3/5 font-medium text-center">
          <div class="text-2xl md:text-5xl">Score</div>
          <div
            class="leading-none text-[15rem] font-seven md:text-[21rem] transition-all duration-50 ease-out"
            data-testid={`${props.testid}-score`}
          >
            <span
              class={
                props.redNumber
                  ? "transition-all duration-50 ease-out text-rose-400"
                  : "transition-all duration-50 ease-in text-white"
              }
            >
              {props.score}
            </span>
          </div>
        </div>
        <div class="flex-col items-center w-2/5 text-center">
          <div class="text-xl font-medium tracking-wider md:text-3xl">
            Games
          </div>
          <div
            class="text-5xl leading-none md:text-9xl font-seven text-red-500"
            data-testid={`${props.testid}-games`}
          >
            {props.games}
          </div>
        </div>
      </div>
      {props.mode === GameMode.Game && (
        <div class="flex col-span-full col-start-1 justify-center mt-8 text-lg font-medium tracking-wider md:text-2xl">
          <button
            class="py-2 px-4 mx-4 text-black uppercase bg-white border-r-4 border-b-4 border-black active:border-r-0 active:border-b-0 active:border-t-4 active:border-l-4 font-sports border-t border-l selectable"
            onClick={() => props.onScore()}
            data-testid={`${props.testid}-button`}
          >
            {props.name} Scored
          </button>
        </div>
      )}
      {props.mode === GameMode.Correction && (
        <div class="flex col-span-full col-start-1 justify-center mt-8 text-2xl font-medium tracking-wider">
          <button
            class="py-2 px-4 mx-4 text-black uppercase bg-white border-r-4 border-b-4 border-black active:border-r-0 active:border-b-0 active:border-t-4 active:border-l-4 border-t border-l font-sports selectable"
            data-testid={`${props.testid}-correction-button`}
            onClick={() => props.onCorrection()}
          >
            Subtract point from {props.name}
          </button>
        </div>
      )}
    </div>
  );
}
