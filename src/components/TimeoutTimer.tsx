import { Show } from 'solid-js';

interface TimeoutTimerProps {
  timeoutRemaining: number;
  timeoutPlayer: number;
  player1Name: string;
  player2Name: string;
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
      <div class="absolute inset-0 bg-black bg-opacity-80 flex items-center justify-center z-50">
        <div class="bg-red-600 text-white p-12 rounded-lg text-center">
          <div class="text-6xl font-bold mb-6">TIMEOUT</div>
          <div class="text-5xl mb-4">{getPlayerName()}</div>
          <div class="text-[18rem] font-mono font-bold leading-none">
            {formatTime(props.timeoutRemaining)}
          </div>
          <div class="text-2xl mt-6 opacity-80">
            Game will resume automatically
          </div>
        </div>
      </div>
    </Show>
  );
}