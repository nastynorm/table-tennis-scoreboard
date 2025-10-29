interface TimeoutButtonProps {
  player: number;
  timeoutsUsed: number;
  onTimeout: (player: number) => void;
  disabled?: boolean;
}

export default function TimeoutButton(props: TimeoutButtonProps) {
  return (
    <button
      class="w-8 h-8 bg-green-500 text-white font-bold rounded-full flex items-center justify-center text-xs transition-colors"
      classList={{
        'bg-green-700': props.timeoutsUsed > 0,
        'opacity-50 cursor-not-allowed': props.disabled,
        'hover:bg-green-600': !props.disabled,
      }}
      onClick={() => props.onTimeout(props.player)}
      disabled={props.disabled}
      title={`Timeout ${props.timeoutsUsed > 0 ? `(${props.timeoutsUsed} used)` : ''}`}
    >
      T
    </button>
  );
}