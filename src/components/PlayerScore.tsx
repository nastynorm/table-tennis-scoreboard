import { For, Show } from "solid-js";
import { GameMode } from "./common";

interface PlayerScoreProps {
  mode: GameMode;
  showBorder: boolean;
  name: string;
  partnerName: string;
  reverse: boolean;
  score: number;
  games: number;
  yellowCards: number;
  onScore: Function;
  onCorrection: Function;
  onAddCard: Function;
  onRemoveCard: Function;
  testid: string;
  redNumber: boolean;
  // Per-game points this player scored in each completed game of the match.
  gameScores: { points: number; won: boolean }[];
  // Timeout props
  player: number;
  timeoutsUsed: number;
  onTimeout: (player: number) => void;
  timeoutActive: boolean;
  // Serving / doubles props
  doubles: boolean;
  showServer: boolean;
  serving: boolean;
  servingPartnerIndex: number;
  onSetServer: () => void;
  onToggleDoublesServer: () => void;
  presentation: boolean;
}

// A small ball icon used as the serve indicator.
function ServeBall(props: { active: boolean; testid: string }) {
  return (
    <span
      data-testid={props.testid}
      title={props.active ? "Serving" : "Not serving"}
      classList={{
        "inline-block rounded-full transition-all duration-200 shrink-0": true,
        "w-4 h-4 sm:w-5 sm:h-5 bg-amber-300 shadow-[0_0_10px_2px_rgba(252,211,77,0.7)] ring-2 ring-amber-100":
          props.active,
        "w-3 h-3 sm:w-4 sm:h-4 bg-white/15": !props.active,
      }}
    />
  );
}

export default function PlayerScore(props: PlayerScoreProps) {
  const isGame = () => props.mode === GameMode.Game;
  const isCorrection = () => props.mode === GameMode.Correction;

  return (
    <div
      classList={{
        "flex flex-col h-full min-h-0 rounded-2xl bg-white/[0.03] px-2 py-1.5 font-sports tracking-wider": true,
        "ring-1 ring-amber-300/40": props.showServer && props.serving,
      }}
    >
      {/* Name row (serve dot + name + timeout + card controls) */}
      <div class="shrink-0 flex items-center justify-center gap-2 flex-wrap leading-none">
        <Show when={props.showServer}>
          <Show
            when={!props.presentation}
            fallback={
              <ServeBall
                active={props.serving && (!props.doubles || props.servingPartnerIndex === 0)}
                testid={`${props.testid}-serve-indicator`}
              />
            }
          >
            <button type="button" onClick={() => props.onSetServer()} title="Set first server">
              <ServeBall
                active={props.serving && (!props.doubles || props.servingPartnerIndex === 0)}
                testid={`${props.testid}-serve-indicator`}
              />
            </button>
          </Show>
        </Show>
        <span
          class="text-lg sm:text-2xl xl:text-3xl border-b-2 border-white/60 px-2"
          classList={{
            "text-amber-200": props.showServer && props.serving && (!props.doubles || props.servingPartnerIndex === 0),
          }}
          data-testid={`${props.testid}-name`}
        >
          {props.name}
        </span>
        <Show when={props.timeoutsUsed === 0 && !props.timeoutActive && !props.presentation}>
          <button
            class="w-8 h-8 sm:w-9 sm:h-9 text-sm font-bold text-black bg-emerald-400 rounded-full hover:bg-emerald-300 active:bg-emerald-500 flex items-center justify-center shadow"
            onClick={() => props.onTimeout(props.player)}
            data-testid={`${props.testid}-timeout-button`}
            title="Call Timeout (1 per match)"
          >
            T
          </button>
        </Show>
        <Show when={(isGame() || isCorrection()) && !props.presentation}>
          <button
            type="button"
            class="w-8 h-8 text-sm font-bold rounded bg-yellow-400 text-black hover:bg-yellow-300 active:bg-yellow-500 flex items-center justify-center"
            onClick={() => props.onAddCard()}
            data-testid={`${props.testid}-add-card`}
            title="Give yellow card / warning"
          >
            🟨
          </button>
          <Show when={props.yellowCards > 0}>
            <button
              type="button"
              class="w-8 h-8 text-sm font-bold rounded bg-white/10 text-white hover:bg-white/20 flex items-center justify-center"
              onClick={() => props.onRemoveCard()}
              data-testid={`${props.testid}-remove-card`}
              title="Remove a yellow card"
            >
              −
            </button>
          </Show>
        </Show>
      </div>

      {/* Per-game scoreline: this player's points in each completed game */}
      <Show when={props.gameScores.length > 0}>
        <div
          class="shrink-0 flex items-center justify-center flex-wrap gap-1 mt-1"
          data-testid={`${props.testid}-game-scores`}
        >
          <For each={props.gameScores}>
            {(g) => (
              <span
                classList={{
                  "inline-flex items-center justify-center min-w-[1.7rem] px-1.5 py-0.5 rounded-md text-base font-mono font-bold leading-none": true,
                  "bg-emerald-500 text-white": g.won,
                  "bg-white/10 text-white/70": !g.won,
                }}
              >
                {g.points}
              </span>
            )}
          </For>
        </div>
      </Show>

      {/* Doubles partner name */}
      <Show when={props.doubles}>
        <div class="shrink-0 flex items-center justify-center gap-2 mt-0.5 leading-none">
          <Show when={props.showServer}>
            <ServeBall
              active={props.serving && props.servingPartnerIndex === 1}
              testid={`${props.testid}-serve-indicator-partner`}
            />
          </Show>
          <span
            class="text-sm sm:text-lg text-white/80"
            classList={{ "text-amber-200": props.serving && props.servingPartnerIndex === 1 }}
            data-testid={`${props.testid}-partner-name`}
          >
            {props.partnerName}
          </span>
          <Show when={isGame() && !props.presentation}>
            <button
              type="button"
              class="px-2 py-0.5 text-xs font-mono rounded bg-white/10 hover:bg-white/20 text-white"
              onClick={() => props.onToggleDoublesServer()}
              data-testid={`${props.testid}-rotate-server`}
              title="Rotate doubles server"
            >
              ⇄
            </button>
          </Show>
        </div>
      </Show>

      {/* Yellow card pips */}
      <div
        class="shrink-0 flex items-center justify-center gap-1 min-h-[0.9rem]"
        data-testid={`${props.testid}-yellow-cards`}
        aria-label={`${props.yellowCards} yellow cards`}
      >
        <For each={Array.from({ length: props.yellowCards })}>
          {() => <span class="inline-block w-3 h-4 rounded-sm bg-yellow-400 border border-yellow-600" />}
        </For>
      </div>

      {/* Score + Games (fills remaining height, clipped never since digits are vh-sized) */}
      <div
        classList={{
          "flex-1 min-h-0 flex items-center justify-center gap-3 overflow-hidden": true,
          "flex-row-reverse": props.reverse,
        }}
      >
        <div class="flex flex-col items-center justify-center min-h-0">
          <div class="text-sm sm:text-xl text-white/60 leading-none">Score</div>
          <div
            class="score-digits font-seven"
            data-testid={`${props.testid}-score`}
          >
            <span class={props.redNumber ? "text-rose-400" : "text-white"}>
              {props.score}
            </span>
          </div>
        </div>
        <div class="flex flex-col items-center justify-center min-h-0">
          <div class="text-xs sm:text-lg text-white/60 leading-none">Games</div>
          <div class="games-digits font-seven text-rose-400" data-testid={`${props.testid}-games`}>
            {props.games}
          </div>
        </div>
      </div>

    </div>
  );
}
