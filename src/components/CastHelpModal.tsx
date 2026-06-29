interface CastHelpModalProps {
  onClose: () => void;
}

export default function CastHelpModal(props: CastHelpModalProps) {
  return (
    <div
      class="fixed inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4"
      data-testid="cast-help-modal"
      onClick={(e) => {
        if (e.target === e.currentTarget) props.onClose();
      }}
    >
      <div class="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-3xl bg-slate-900 border border-white/10 shadow-2xl p-6 sm:p-8 text-white">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-2xl sm:text-3xl font-sports tracking-wider">
            Show on a Big Screen
          </h2>
          <button
            type="button"
            class="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 text-xl flex items-center justify-center"
            onClick={() => props.onClose()}
            data-testid="cast-help-close"
            title="Close"
          >
            ✕
          </button>
        </div>

        <div class="rounded-xl bg-rose-500/15 border border-rose-400/40 p-3 mb-5 text-sm sm:text-base">
          <span class="font-bold">Important for the Galaxy A16:</span> its USB‑C
          port is USB 2.0, so a <span class="font-bold">USB‑C → HDMI cable will
          NOT work</span> for video. Use one of the wireless options below.
        </div>

        <ol class="space-y-4 text-sm sm:text-base">
          <li>
            <div class="font-bold text-sky-300 text-lg">
              1. Mirror wirelessly (easiest)
            </div>
            <p class="text-white/80 mt-1">
              Shows the whole phone screen on the big screen.
            </p>
            <ul class="list-disc ml-5 mt-1 text-white/80 space-y-1">
              <li>
                <span class="font-semibold">Smart TV:</span> swipe down ▸
                <span class="font-semibold"> Smart View</span> ▸ pick the TV.
              </li>
              <li>
                <span class="font-semibold">Plain monitor:</span> plug a wireless
                display dongle into its HDMI — a{" "}
                <span class="font-semibold">MiraScreen/AnyCast</span> (Miracast)
                or a <span class="font-semibold">Chromecast</span> — then Smart
                View / cast to it.
              </li>
            </ul>
            <p class="text-white/50 mt-1 text-xs sm:text-sm">
              Tip: turn on <span class="font-semibold">Presentation Mode</span>{" "}
              (in the menu) first to hide the buttons, then control scoring with a
              Bluetooth remote for a clean big screen.
            </p>
          </li>

          <li>
            <div class="font-bold text-emerald-300 text-lg">
              2. Two devices over Bluetooth (clean spectator screen)
            </div>
            <p class="text-white/80 mt-1">
              Big screen shows a button‑free board; you control from the phone.
            </p>
            <ul class="list-disc ml-5 mt-1 text-white/80 space-y-1">
              <li>
                Connect a 2nd device (old phone / Android TV box / Fire Stick) to
                the monitor by <span class="font-semibold">HDMI</span>; install
                this app on it and choose{" "}
                <span class="font-semibold">View 2nd Screen</span>.
              </li>
              <li>
                On this phone choose <span class="font-semibold">Broadcast</span>.
                Scores sync over Bluetooth — no Wi‑Fi or internet needed.
              </li>
            </ul>
          </li>

          <li>
            <div class="font-bold text-white/60 text-lg">
              3. USB‑C → HDMI cable
            </div>
            <p class="text-white/70 mt-1">
              ✗ Not supported on the Galaxy A16 (USB 2.0, no video out). Works
              only on phones with DisplayPort Alt Mode (e.g. Galaxy S/Tab S).
            </p>
          </li>
        </ol>

        <div class="mt-6 flex justify-end">
          <button
            type="button"
            class="py-2 px-6 font-mono font-bold uppercase bg-white text-black rounded-lg shadow-[0_4px_0_0_rgba(0,0,0,0.4)] active:translate-y-1 active:shadow-none transition-all"
            onClick={() => props.onClose()}
          >
            Got it
          </button>
        </div>
      </div>
    </div>
  );
}
