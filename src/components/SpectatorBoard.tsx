import { For, Show } from "solid-js";
import { getServeInfo } from "./common";
import { type Snapshot } from "./sync";

interface SpectatorBoardProps {
  snapshot: Snapshot | null;
}

function ServeDot(props: { active: boolean }) {
  return (
    <span
      classList={{
        "inline-block rounded-full shrink-0": true,
        "w-5 h-5 bg-amber-300 shadow-[0_0_12px_3px_rgba(252,211,77,0.7)] ring-2 ring-amber-100":
          props.active,
        "w-4 h-4 bg-white/15": !props.active,
      }}
    />
  );
}

function Side(props: {
  name: string;
  partner: string;
  score: number;
  games: number;
  yellow: number;
  doubles: boolean;
  showServer: boolean;
  serving: boolean;
  partnerServing: boolean;
  reverse: boolean;
  testid: string;
  gameScores: { mine: number; theirs: number }[];
}) {
  return (
    <div
      classList={{
        "flex flex-col items-center rounded-2xl bg-white/[0.03] px-2 py-4": true,
        "ring-1 ring-amber-300/40": props.showServer && props.serving,
      }}
    >
      <div class="flex items-center justify-center gap-3 flex-wrap">
        <Show when={props.showServer}>
          <ServeDot active={props.serving && (!props.doubles || !props.partnerServing)} />
        </Show>
        <span
          class="px-4 pb-1 text-2xl md:text-4xl xl:text-5xl font-sports border-b-4 border-white/70"
          classList={{ "text-amber-200": props.serving && (!props.doubles || !props.partnerServing) }}
        >
          {props.name}
        </span>
      </div>
      <Show when={props.doubles}>
        <div class="flex items-center justify-center gap-2 mt-1">
          <Show when={props.showServer}>
            <ServeDot active={props.serving && props.partnerServing} />
          </Show>
          <span
            class="text-lg md:text-2xl font-sports text-white/80"
            classList={{ "text-amber-200": props.serving && props.partnerServing }}
          >
            {props.partner}
          </span>
        </div>
      </Show>
      <Show when={props.gameScores.length > 0}>
        <div class="mt-1 font-mono font-semibold text-white text-base sm:text-lg tracking-wide leading-none text-center">
          {props.gameScores.map((g) => `${g.mine}:${g.theirs}`).join(" - ")}
        </div>
      </Show>
      <div class="flex items-center justify-center gap-1 mt-2 min-h-[1.75rem]">
        <For each={Array.from({ length: props.yellow })}>
          {() => (
            <span class="inline-block w-4 h-6 rounded-sm bg-yellow-400 border border-yellow-600 shadow" />
          )}
        </For>
      </div>
      <div classList={{ "flex items-end mt-1": true, "flex-row-reverse": props.reverse }}>
        <div class="flex flex-col items-center w-3/5">
          <div class="text-xl md:text-3xl text-white/70 font-sports">Score</div>
          <div
            class="score-digits font-seven leading-none text-white"
            data-testid={`${props.testid}-score`}
          >
            {props.score}
          </div>
        </div>
        <div class="flex flex-col items-center w-2/5">
          <div class="text-lg md:text-2xl text-white/70 font-sports">Games</div>
          <div class="games-digits font-seven leading-none text-rose-400">{props.games}</div>
        </div>
      </div>
    </div>
  );
}

export default function SpectatorBoard(props: SpectatorBoardProps) {
  const s = () => props.snapshot;

  const serve = () => {
    const snap = s();
    if (!snap) return { side: 1, doublesIndex: 0 };
    return getServeInfo(snap.p1s, snap.p2s, snap.ws, snap.fs, snap.db, snap.dss);
  };

  // Map players to left/right honouring the controller's swap state.
  const leftIsP1 = () => !(s()?.sw ?? false);

  // Per-game scoreline for the player on a given side.
  const scoresFor = (forP1: boolean) =>
    (s()?.gl ?? []).map((g) => ({
      mine: forP1 ? g.a : g.b,
      theirs: forP1 ? g.b : g.a,
    }));

  return (
    <div class="h-[100dvh] overflow-hidden flex flex-col justify-center bg-gradient-to-br from-slate-900 via-slate-950 to-black text-white px-3 sm:px-6">
      <Show
        when={s()}
        fallback={
          <div class="text-center">
            <div class="text-3xl md:text-5xl font-sports tracking-wider animate-pulse">
              Waiting for scoreboard…
            </div>
            <div class="mt-3 text-white/60 font-mono">
              Make sure the controller device is broadcasting.
            </div>
          </div>
        }
      >
        <header class="grid grid-cols-3 items-center gap-2 py-3 px-4 sm:px-8 bg-white/5 backdrop-blur rounded-xl border border-white/10 max-w-[1700px] mx-auto w-full">
          <div class="text-center">
            <h2 class="text-base sm:text-xl lg:text-2xl font-bold font-sports text-sky-300 truncate">
              {leftIsP1() ? s()!.htn : s()!.vtn}
            </h2>
            <Show when={s()!.mt === "league"}>
              <div class="text-2xl sm:text-3xl lg:text-4xl font-bold font-mono text-sky-200">
                {leftIsP1() ? s()!.hts : s()!.vts}
              </div>
            </Show>
          </div>
          <div class="text-center text-xs sm:text-base lg:text-lg font-sports text-gray-300 uppercase tracking-widest">
            {s()!.mt === "league"
              ? `Match ${s()!.cmn} / ${s()!.tm}`
              : `Best of ${s()!.ml}`}
            <Show when={s()!.db}>
              <div class="text-[0.6rem] sm:text-xs font-mono text-amber-300 mt-0.5">Doubles</div>
            </Show>
          </div>
          <div class="text-center">
            <h2 class="text-base sm:text-xl lg:text-2xl font-bold font-sports text-rose-300 truncate">
              {leftIsP1() ? s()!.vtn : s()!.htn}
            </h2>
            <Show when={s()!.mt === "league"}>
              <div class="text-2xl sm:text-3xl lg:text-4xl font-bold font-mono text-rose-200">
                {leftIsP1() ? s()!.vts : s()!.hts}
              </div>
            </Show>
          </div>
        </header>

        <main class="grid grid-cols-2 gap-3 mt-3 max-w-[1700px] mx-auto w-full">
          {/* Left side */}
          <Side
            name={leftIsP1() ? s()!.p1n : s()!.p2n}
            partner={leftIsP1() ? s()!.p1p : s()!.p2p}
            score={leftIsP1() ? s()!.p1s : s()!.p2s}
            games={leftIsP1() ? s()!.p1g : s()!.p2g}
            yellow={leftIsP1() ? s()!.p1y : s()!.p2y}
            doubles={s()!.db}
            showServer={s()!.ss}
            serving={serve().side === (leftIsP1() ? 1 : 2)}
            partnerServing={serve().doublesIndex === 1}
            reverse={false}
            testid="spectator-left"
            gameScores={scoresFor(leftIsP1())}
          />
          {/* Right side */}
          <Side
            name={leftIsP1() ? s()!.p2n : s()!.p1n}
            partner={leftIsP1() ? s()!.p2p : s()!.p1p}
            score={leftIsP1() ? s()!.p2s : s()!.p1s}
            games={leftIsP1() ? s()!.p2g : s()!.p1g}
            yellow={leftIsP1() ? s()!.p2y : s()!.p1y}
            doubles={s()!.db}
            showServer={s()!.ss}
            serving={serve().side === (leftIsP1() ? 2 : 1)}
            partnerServing={serve().doublesIndex === 1}
            reverse={true}
            testid="spectator-right"
            gameScores={scoresFor(!leftIsP1())}
          />
        </main>

        <Show when={s()!.ta && s()!.tr > 0}>
          <div class="fixed inset-0 bg-black/85 backdrop-blur-sm flex items-center justify-center z-50 p-3">
            <div class="bg-gradient-to-b from-rose-600 to-rose-700 text-white px-6 py-4 rounded-2xl text-center shadow-2xl max-h-[94vh] flex flex-col items-center justify-center gap-1">
              <div class="text-2xl sm:text-4xl font-bold font-sports tracking-wider leading-none">TIMEOUT</div>
              <div
                class="font-mono font-bold leading-none"
                style="font-size: clamp(3rem, 40vh, 13rem);"
              >
                {Math.floor(s()!.tr / 60)}:{(s()!.tr % 60).toString().padStart(2, "0")}
              </div>
            </div>
          </div>
        </Show>

        <Show when={s()!.wa && s()!.wr > 0}>
          <div class="fixed inset-0 bg-black/85 backdrop-blur-sm flex items-center justify-center z-50 p-3">
            <div class="bg-gradient-to-b from-sky-600 to-sky-700 text-white px-6 py-4 rounded-2xl text-center shadow-2xl max-h-[94vh] flex flex-col items-center justify-center gap-1">
              <div class="text-2xl sm:text-4xl font-bold font-sports tracking-wider leading-none">WARM UP</div>
              <div
                class="font-mono font-bold leading-none"
                style="font-size: clamp(3rem, 40vh, 13rem);"
              >
                {Math.floor(s()!.wr / 60)}:{(s()!.wr % 60).toString().padStart(2, "0")}
              </div>
            </div>
          </div>
        </Show>
      </Show>
    </div>
  );
}
