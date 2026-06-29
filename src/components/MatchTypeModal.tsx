import { For } from "solid-js";
import type { MatchType } from "./common";

interface MatchTypeModalProps {
  current: MatchType;
  onSelect: (type: MatchType) => void;
  onClose: () => void;
}

type Option = {
  type: MatchType;
  title: string;
  blurb: string;
  badge?: string;
  accent: string;
};

const OPTIONS: Option[] = [
  {
    type: "normal",
    title: "Normal Match",
    blurb: "A single best-of-N match between two players or pairs.",
    accent: "from-sky-500 to-sky-700",
  },
  {
    type: "league",
    title: "League Match",
    blurb: "Home vs Visitor league night across multiple fixtures.",
    accent: "from-emerald-500 to-emerald-700",
  },
  {
    type: "knockout",
    title: "Knock-Out Match",
    blurb: "Single-elimination bracket play.",
    badge: "Format coming soon — plays as a normal match for now",
    accent: "from-violet-500 to-violet-700",
  },
  {
    type: "summer",
    title: "Summer League",
    blurb: "Relaxed summer-season format.",
    badge: "Format coming soon — plays as a normal match for now",
    accent: "from-amber-500 to-orange-600",
  },
];

export default function MatchTypeModal(props: MatchTypeModalProps) {
  return (
    <div
      class="fixed inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4"
      data-testid="match-type-modal"
      onClick={(e) => {
        if (e.target === e.currentTarget) props.onClose();
      }}
    >
      <div class="w-full max-w-2xl rounded-3xl bg-slate-900 border border-white/10 shadow-2xl p-6 sm:p-8">
        <div class="flex items-center justify-between mb-5">
          <h2 class="text-2xl sm:text-3xl font-sports tracking-wider text-white">
            Start New Match
          </h2>
          <button
            type="button"
            class="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 text-white text-xl flex items-center justify-center"
            onClick={() => props.onClose()}
            data-testid="match-type-close"
            title="Close"
          >
            ✕
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
          <For each={OPTIONS}>
            {(opt) => (
              <button
                type="button"
                data-testid={`match-type-${opt.type}`}
                onClick={() => props.onSelect(opt.type)}
                classList={{
                  "text-left rounded-2xl p-4 sm:p-5 bg-gradient-to-br text-white shadow-lg transition-transform active:scale-[0.98] hover:-translate-y-0.5": true,
                  [opt.accent]: true,
                  "ring-4 ring-white/70": props.current === opt.type,
                }}
              >
                <div class="text-xl sm:text-2xl font-sports tracking-wider">
                  {opt.title}
                </div>
                <div class="text-sm sm:text-base text-white/90 mt-1">
                  {opt.blurb}
                </div>
                {opt.badge && (
                  <div class="mt-2 inline-block text-[0.65rem] sm:text-xs font-mono uppercase tracking-wider bg-black/30 rounded px-2 py-1">
                    {opt.badge}
                  </div>
                )}
              </button>
            )}
          </For>
        </div>

        <p class="text-center text-white/50 text-xs sm:text-sm font-mono mt-5">
          Player names, scoring keys and other options live in Menu ▸ Setup.
        </p>
      </div>
    </div>
  );
}
