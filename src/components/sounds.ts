// Small, offline, royalty-free sound helper built on the Web Audio API.
// No audio files are bundled — every sound is synthesized on the fly, so it
// works on the packaged Android app with no assets and no network.

let audioCtx: AudioContext | null = null;

// Global on/off switch, driven by the Settings "Sounds" toggle. When off, every
// sound-emitting function below is a no-op.
let soundEnabled = true;
export function setSoundEnabled(on: boolean) {
  soundEnabled = on;
}

function ctx(): AudioContext | null {
  if (typeof window === "undefined") return null;
  const AC =
    (window as any).AudioContext || (window as any).webkitAudioContext;
  if (!AC) return null;
  if (!audioCtx) audioCtx = new AC();
  return audioCtx;
}

// Browsers start the audio context "suspended" until a user gesture. Call this
// from inside a click/keyup handler (e.g. when a timer starts) to unlock it.
// It also kicks off loading the "time's up" clip so it's ready at expiry.
export function unlockAudio() {
  const ac = ctx();
  if (ac && ac.state === "suspended") ac.resume().catch(() => {});
  preloadTimeUp();
}

// "Time's up" clip (time.mp3, bundled in /public). Decoded once into the
// unlocked audio context so it plays reliably at the end of a timer — long
// after the user gesture that started it — with no autoplay issues.
const TIME_UP_URL = `${import.meta.env.BASE_URL}time.mp3`;
let timeBuffer: AudioBuffer | null = null;
let timeLoading: Promise<void> | null = null;

export function preloadTimeUp() {
  const ac = ctx();
  if (!ac || timeBuffer || timeLoading) return;
  timeLoading = fetch(TIME_UP_URL)
    .then((r) => r.arrayBuffer())
    .then((buf) => ac.decodeAudioData(buf))
    .then((decoded) => {
      timeBuffer = decoded;
    })
    .catch(() => {
      /* leave timeBuffer null — playTimeUp() falls back to the buzzer */
    });
}

// Play the "time's up" clip. Uses the decoded buffer when ready; otherwise
// tries a plain HTML5 Audio element, and finally the synthesized buzzer, so
// something always sounds even offline or before the clip has decoded.
export function playTimeUp() {
  if (!soundEnabled) return;
  const ac = ctx();
  if (ac && timeBuffer) {
    const src = ac.createBufferSource();
    src.buffer = timeBuffer;
    src.connect(ac.destination);
    src.start();
    return;
  }
  try {
    const el = new Audio(TIME_UP_URL);
    const p = el.play();
    if (p && typeof p.catch === "function") p.catch(() => buzzer());
  } catch {
    buzzer();
  }
}

type BeepOpts = {
  type?: OscillatorType;
  vol?: number;
  slideTo?: number; // ramp the frequency to this value over the note
  delay?: number; // start this many seconds from now
};

function beep(freq: number, dur: number, opts: BeepOpts = {}) {
  const ac = ctx();
  if (!ac) return;
  const { type = "sine", vol = 0.3, slideTo, delay = 0 } = opts;
  const start = ac.currentTime + delay;
  const osc = ac.createOscillator();
  const gain = ac.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, start);
  if (slideTo) osc.frequency.linearRampToValueAtTime(slideTo, start + dur);
  // Quick attack, smooth decay so it doesn't click.
  gain.gain.setValueAtTime(0.0001, start);
  gain.gain.exponentialRampToValueAtTime(vol, start + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.0001, start + dur);
  osc.connect(gain).connect(ac.destination);
  osc.start(start);
  osc.stop(start + dur + 0.02);
}

// One countdown "pip" for the final seconds. The last three seconds get a
// higher, more urgent pitch.
export function countdownTick(secondsLeft: number) {
  if (!soundEnabled) return;
  const urgent = secondsLeft <= 3;
  beep(urgent ? 1046.5 : 784, urgent ? 0.16 : 0.12, {
    type: "triangle",
    vol: 0.35,
  });
}

// Loud "time's up" buzzer — a harsh, low two-tone blast.
export function buzzer() {
  if (!soundEnabled) return;
  beep(196, 0.6, { type: "sawtooth", vol: 0.5 });
  beep(146.83, 0.7, { type: "sawtooth", vol: 0.5, delay: 0.05 });
}
