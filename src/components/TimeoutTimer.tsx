import { Show } from 'solid-js';

interface TimeoutTimerProps {
  timeoutRemaining: number;
  timeoutPlayer: number;
  player1Name: string;
  player2Name: string;
  onCancel: () => void;
}

export default function TimeoutTimer(props: TimeoutTimerProps) {
  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getPlayerName = () => {
    return props.timeoutPlayer === 1 ? props.player1Name : props.player2Name;
  };

  return (
    <Show when={props.timeoutRemaining > 0}>
      <div class="fixed inset-0 bg-black/85 backdrop-blur-sm flex items-center justify-center z-50 p-3">
        <div class="bg-gradient-to-b from-rose-600 to-rose-700 text-white px-6 py-4 rounded-2xl text-center shadow-2xl max-w-[92vw] max-h-[94vh] flex flex-col items-center justify-center gap-1">
          <div class="text-2xl sm:text-4xl font-bold font-sports tracking-wider leading-none">
            TIMEOUT
          </div>
          <div class="text-lg sm:text-2xl leading-none truncate max-w-[88vw]">
            {getPlayerName()}
          </div>
          <div
            class="font-mono font-bold leading-none"
            style="font-size: clamp(3rem, 34vh, 11rem);"
          >
            {formatTime(props.timeoutRemaining)}
          </div>
          <div class="text-sm sm:text-lg opacity-80 leading-none">
            Game will resume automatically
          </div>
          <button
            type="button"
            class="mt-2 py-2 px-6 text-sm sm:text-lg font-mono font-bold uppercase bg-white text-rose-700 rounded-lg shadow-[0_3px_0_0_rgba(0,0,0,0.3)] active:translate-y-1 active:shadow-none transition-all"
            onClick={() => props.onCancel()}
            data-testid="cancel-timeout-button"
          >
            Cancel Timeout
          </button>
        </div>
      </div>
    </Show>
  );
}
