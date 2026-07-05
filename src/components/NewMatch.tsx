import { createSignal, createMemo, For, Show } from "solid-js";
import {
  type MatchType,
  type NewMatchSetup,
  isTeamFormat,
  teamFixtures,
} from "./common";

interface NewMatchProps {
  onStart: (setup: NewMatchSetup) => void;
  onCancel: () => void;
}

type FormatCard = {
  type: MatchType;
  title: string;
  blurb: string;
  accent: string;
};

const FORMATS: FormatCard[] = [
  {
    type: "singles",
    title: "Singles",
    blurb: "One match, two players. Best of 3 / 5 / 7.",
    accent: "from-sky-500 to-sky-700",
  },
  {
    type: "league",
    title: "League",
    blurb: "Team tie · 7 fixtures · first team to 4 wins.",
    accent: "from-emerald-500 to-emerald-700",
  },
  {
    type: "summer",
    title: "Summer League",
    blurb: "Team tie · best of 3 · first team to 4 wins.",
    accent: "from-amber-500 to-orange-600",
  },
  {
    type: "knockout",
    title: "Knock-Out",
    blurb: "Team tie · best of 5 · first team to 4 wins.",
    accent: "from-violet-500 to-violet-700",
  },
];

export default function NewMatch(props: NewMatchProps) {
  const [step, setStep] = createSignal(1);
  const [type, setType] = createSignal<MatchType>("singles");

  // Best-of: league lets you pick 5/7; summer/knockout fixed 5; singles 3/5/7.
  const [bestOf, setBestOf] = createSignal(5);
  const [doubles, setDoubles] = createSignal(false);

  // Singles names
  const [p1, setP1] = createSignal("Player 1");
  const [p2, setP2] = createSignal("Player 2");
  const [p1Partner, setP1Partner] = createSignal("Partner 1");
  const [p2Partner, setP2Partner] = createSignal("Partner 2");

  // Team line-ups
  const [homeTeam, setHomeTeam] = createSignal("Home");
  const [visitorTeam, setVisitorTeam] = createSignal("Visitor");
  const [home, setHome] = createSignal(["H1", "H2", "H3"]);
  const [visitor, setVisitor] = createSignal(["V1", "V2", "V3"]);
  // Editable doubles pairing (fixture 4).
  const [homeDoubles, setHomeDoubles] = createSignal(["H1", "H2"]);
  const [visitorDoubles, setVisitorDoubles] = createSignal(["V1", "V2"]);

  const team = () => isTeamFormat(type());

  // Per-format best-of choices: singles 3/5/7, league 5/7, summer fixed 3,
  // knock-out fixed 5.
  const bestOfOptions = () => {
    switch (type()) {
      case "singles":
        return [3, 5, 7];
      case "league":
        return [5, 7];
      case "summer":
        return [3];
      default:
        return [5]; // knockout
    }
  };

  const defaultBestOf = (t: MatchType) =>
    t === "summer" ? 3 : 5; // singles/league/knockout default 5

  const pick = (t: MatchType) => {
    setType(t);
    setBestOf(defaultBestOf(t));
    setStep(2);
  };

  const setHomeAt = (i: number, v: string) =>
    setHome((a) => a.map((x, j) => (j === i ? v : x)));
  const setVisitorAt = (i: number, v: string) =>
    setVisitor((a) => a.map((x, j) => (j === i ? v : x)));
  const setHomeDbl = (i: number, v: string) =>
    setHomeDoubles((a) => a.map((x, j) => (j === i ? v : x)));
  const setVisitorDbl = (i: number, v: string) =>
    setVisitorDoubles((a) => a.map((x, j) => (j === i ? v : x)));

  const rosters = () => ({
    home: home(),
    visitor: visitor(),
    homeDoubles: homeDoubles(),
    visitorDoubles: visitorDoubles(),
  });

  // Live scoresheet preview for team formats.
  const fixtures = createMemo(() =>
    team() ? teamFixtures(type(), rosters()) : [],
  );

  const start = () => {
    props.onStart({
      type: type(),
      bestOf: bestOf(),
      doubles: doubles(),
      p1: p1() || "Player 1",
      p2: p2() || "Player 2",
      p1Partner: p1Partner() || "Partner 1",
      p2Partner: p2Partner() || "Partner 2",
      homeTeam: homeTeam() || "Home",
      visitorTeam: visitorTeam() || "Visitor",
      home: home(),
      visitor: visitor(),
      homeDoubles: homeDoubles(),
      visitorDoubles: visitorDoubles(),
    });
  };

  const inputClass =
    "py-2 px-3 w-full font-mono bg-white text-black border-2 border-black focus:outline-none rounded";

  return (
    <div class="min-h-screen text-white overflow-y-auto py-6" data-testid="new-match">
      <header class="text-center mb-5">
        <h1 class="text-3xl sm:text-4xl font-sports tracking-wider">New Match</h1>
      </header>

      {/* Step 1 — choose format */}
      <Show when={step() === 1}>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 max-w-3xl mx-auto px-2">
          <For each={FORMATS}>
            {(f) => (
              <button
                type="button"
                data-testid={`format-${f.type}`}
                onClick={() => pick(f.type)}
                class={`text-left rounded-2xl p-5 bg-gradient-to-br ${f.accent} text-white shadow-lg transition-transform active:scale-[0.98] hover:-translate-y-0.5`}
              >
                <div class="text-2xl font-sports tracking-wider">{f.title}</div>
                <div class="text-sm text-white/90 mt-1">{f.blurb}</div>
              </button>
            )}
          </For>
        </div>
        <div class="flex justify-center mt-6">
          <button
            type="button"
            class="py-2 px-6 font-mono font-bold uppercase bg-white/10 rounded-lg"
            onClick={() => props.onCancel()}
            data-testid="new-match-cancel"
          >
            Cancel
          </button>
        </div>
      </Show>

      {/* Step 2 — configure */}
      <Show when={step() === 2}>
        <div class="max-w-3xl mx-auto px-3 space-y-5">
          {/* Best of */}
          <div class="flex items-center justify-center gap-3 flex-wrap">
            <span class="font-sports text-xl tracking-wider">Best of</span>
            <div class="flex gap-2">
              <For each={bestOfOptions()}>
                {(n) => (
                  <button
                    type="button"
                    data-testid={`bestof-${n}`}
                    onClick={() => setBestOf(n)}
                    classList={{
                      "w-12 h-10 rounded-lg font-bold border-2": true,
                      "bg-white text-black border-white": bestOf() === n,
                      "bg-white/5 text-white border-white/30": bestOf() !== n,
                    }}
                  >
                    {n}
                  </button>
                )}
              </For>
            </div>
            <Show when={team()}>
              <span class="text-white/60 font-mono text-sm">· first team to 4 fixtures</span>
            </Show>
          </div>

          {/* Singles: two names + optional doubles */}
          <Show when={!team()}>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <label class="flex flex-col gap-1">
                <span class="font-sports tracking-wider">Player 1</span>
                <input class={inputClass} data-testid="singles-p1" value={p1()} onInput={(e) => setP1(e.currentTarget.value)} />
                <Show when={doubles()}>
                  <input class={inputClass} data-testid="singles-p1-partner" value={p1Partner()} onInput={(e) => setP1Partner(e.currentTarget.value)} placeholder="Partner 1" />
                </Show>
              </label>
              <label class="flex flex-col gap-1">
                <span class="font-sports tracking-wider">Player 2</span>
                <input class={inputClass} data-testid="singles-p2" value={p2()} onInput={(e) => setP2(e.currentTarget.value)} />
                <Show when={doubles()}>
                  <input class={inputClass} data-testid="singles-p2-partner" value={p2Partner()} onInput={(e) => setP2Partner(e.currentTarget.value)} placeholder="Partner 2" />
                </Show>
              </label>
            </div>
            <label class="flex items-center gap-3 justify-center">
              <input type="checkbox" class="w-5 h-5" data-testid="singles-doubles" checked={doubles()} onChange={(e) => setDoubles(e.currentTarget.checked)} />
              <span class="font-sports tracking-wider">Doubles (add partners)</span>
            </label>
          </Show>

          {/* Team: team names + line-ups + scoresheet preview */}
          <Show when={team()}>
            <div class="grid grid-cols-2 gap-4">
              <label class="flex flex-col gap-1">
                <span class="font-sports tracking-wider text-sky-300">Home team</span>
                <input class={inputClass} data-testid="home-team" value={homeTeam()} onInput={(e) => setHomeTeam(e.currentTarget.value)} />
              </label>
              <label class="flex flex-col gap-1">
                <span class="font-sports tracking-wider text-rose-300">Visitor team</span>
                <input class={inputClass} data-testid="visitor-team" value={visitorTeam()} onInput={(e) => setVisitorTeam(e.currentTarget.value)} />
              </label>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-2">
                <For each={[0, 1, 2]}>
                  {(i) => (
                    <input class={inputClass} data-testid={`home-${i + 1}`} value={home()[i]} onInput={(e) => setHomeAt(i, e.currentTarget.value)} placeholder={`H${i + 1}`} />
                  )}
                </For>
              </div>
              <div class="space-y-2">
                <For each={[0, 1, 2]}>
                  {(i) => (
                    <input class={inputClass} data-testid={`visitor-${i + 1}`} value={visitor()[i]} onInput={(e) => setVisitorAt(i, e.currentTarget.value)} placeholder={`V${i + 1}`} />
                  )}
                </For>
              </div>
            </div>

            {/* Doubles pairing (fixture 4) — editable combination */}
            <div class="rounded-xl bg-white/5 border border-white/10 p-3">
              <div class="text-center font-sports tracking-wider text-white/70 mb-2">
                Doubles pairing (fixture 4)
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div class="flex items-center gap-2">
                  <input class={inputClass} data-testid="home-double-1" value={homeDoubles()[0]} onInput={(e) => setHomeDbl(0, e.currentTarget.value)} placeholder="Home A" />
                  <span class="text-white/40">/</span>
                  <input class={inputClass} data-testid="home-double-2" value={homeDoubles()[1]} onInput={(e) => setHomeDbl(1, e.currentTarget.value)} placeholder="Home B" />
                </div>
                <div class="flex items-center gap-2">
                  <input class={inputClass} data-testid="visitor-double-1" value={visitorDoubles()[0]} onInput={(e) => setVisitorDbl(0, e.currentTarget.value)} placeholder="Visitor A" />
                  <span class="text-white/40">/</span>
                  <input class={inputClass} data-testid="visitor-double-2" value={visitorDoubles()[1]} onInput={(e) => setVisitorDbl(1, e.currentTarget.value)} placeholder="Visitor B" />
                </div>
              </div>
            </div>

            {/* Scoresheet preview */}
            <div class="rounded-xl bg-white/5 border border-white/10 overflow-hidden" data-testid="scoresheet">
              <div class="px-3 py-1.5 text-center font-sports tracking-wider text-white/70 border-b border-white/10">
                Order of Play
              </div>
              <For each={fixtures()}>
                {(fx, i) => (
                  <div class="grid grid-cols-[2rem_1fr_2rem_1fr] items-center gap-2 px-3 py-1.5 odd:bg-white/[0.03]">
                    <span class="text-white/50 font-mono">{i() + 1}</span>
                    <span class="text-sky-200 text-right truncate">
                      {fx.doubles ? `${fx.p1} / ${fx.p1Partner}` : fx.p1}
                    </span>
                    <span class="text-white/40 text-center text-sm">v</span>
                    <span class="text-rose-200 truncate">
                      {fx.doubles ? `${fx.p2} / ${fx.p2Partner}` : fx.p2}
                    </span>
                  </div>
                )}
              </For>
            </div>
          </Show>

          {/* Actions */}
          <div class="flex justify-center gap-3 pb-4">
            <button type="button" class="py-2 px-5 font-mono font-bold uppercase bg-white/10 rounded-lg" onClick={() => setStep(1)} data-testid="new-match-back">
              ◂ Back
            </button>
            <button type="button" class="py-2 px-8 font-mono font-bold uppercase bg-emerald-500 text-white rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] active:translate-y-1 active:shadow-none transition-all" onClick={start} data-testid="start-match">
              Start Game ▸
            </button>
          </div>
        </div>
      </Show>
    </div>
  );
}
