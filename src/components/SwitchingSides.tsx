import { type Setter } from "solid-js";
import { GameMode } from "./common";

interface SwitchingSidesProps {
  setMode: Setter<GameMode>;
}
export default function SwitchingSides(props: SwitchingSidesProps) {
  return (
    <div
      class="h-full flex flex-col items-center justify-center gap-3 px-4 text-white cursor-pointer overflow-hidden"
      data-testid="switch-sides-screen"
      onClick={() => props.setMode(GameMode.Game)}
      title="Tap anywhere to continue"
    >
      <h1
        class="text-5xl md:text-7xl font-normal font-sports tracking-wider text-center"
        data-testid="winner-text"
      >
        Switch Ends
      </h1>
      <h4 class="text-xl md:text-2xl font-normal font-sports px-4 tracking-wider text-center">
        It’s time to switch ends
      </h4>
      <button
        class="font-mono text-lg md:text-2xl uppercase bg-white text-black rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] px-8 py-2 font-bold active:translate-y-1 active:shadow-none transition-all"
        onClick={(e) => {
          e.stopPropagation();
          props.setMode(GameMode.Game);
        }}
        data-testid="start-game-button"
      >
        Start Game ▸
      </button>
      <h6 class="font-mono font-bold uppercase text-sm md:text-base text-center text-white/60">
        Tap anywhere to continue
      </h6>
    </div>
  );
}
