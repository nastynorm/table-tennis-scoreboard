import { Show } from "solid-js";

interface WarmupTimerProps {
  remaining: number;
  onSkip: () => void;
}

export default function WarmupTimer(props: WarmupTimerProps) {
  const fmt = (s: number) =>
    `${Math.floor(s / 60)}:${(s % 60).toString().padStart(2, "0")}`;

  return (
    <Show when={props.remaining > 0}>
      <div class="fixed inset-0 bg-black/85 backdrop-blur-sm flex items-center justify-center z-50 p-3">
        <div class="bg-gradient-to-b from-sky-600 to-sky-700 text-white px-6 py-4 rounded-2xl text-center shadow-2xl max-w-[92vw] max-h-[94vh] flex flex-col items-center justify-center gap-1">
          <div class="text-2xl sm:text-4xl font-bold font-sports tracking-wider leading-none">
            WARM UP
          </div>
          <div
            class="font-mono font-bold leading-none"
            style="font-size: clamp(3rem, 34vh, 11rem);"
          >
            {fmt(props.remaining)}
          </div>
          <div class="text-sm sm:text-lg opacity-80 leading-none">
            Match starts when the timer ends
          </div>
          <button
            type="button"
            class="mt-2 py-2 px-6 text-sm sm:text-lg font-mono font-bold uppercase bg-white text-sky-700 rounded-lg shadow-[0_3px_0_0_rgba(0,0,0,0.3)] active:translate-y-1 active:shadow-none transition-all"
            onClick={() => props.onSkip()}
            data-testid="skip-warmup-button"
          >
            Skip Warm Up
          </button>
        </div>
      </div>
    </Show>
  );
}
