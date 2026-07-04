import {
  createSignal,
  createMemo,
  onCleanup,
  onMount,
  Show,
  type Accessor,
  type Setter,
} from "solid-js";
import {
  GameMode,
  getServeInfo,
  gamesToWin,
  type GameConfig,
  type MatchState,
} from "./common";
import PlayerScore from "./PlayerScore";
import TimeoutTimer from "./TimeoutTimer";

// TODO: option to hide ui
interface PlayingGameProps {
  mode: GameMode;
  setMode: Setter<GameMode>;
  config: GameConfig;
  matchState: MatchState;
  setMatchState: Setter<MatchState>;
  presentation: boolean;
}

interface SidePlayer {
  name: string;
  partnerName: string;
  score: number;
  games: number;
  yellowCards: number;
  onScore: Function;
  onCorrection: Function;
  onAddCard: Function;
  onRemoveCard: Function;
  redNumber: Accessor<boolean>;
}

export default function PlayingGame(props: PlayingGameProps) {
  const [player1RedNumber, setPlayer1RedNumber] = createSignal(false);
  const [player2RedNumber, setPlayer2RedNumber] = createSignal(false);
  const [timeoutInterval, setTimeoutInterval] = createSignal<NodeJS.Timeout | null>(null);

  // Header label that adapts to the competition format.
  const centerLabel = () => {
    switch (props.config.matchType) {
      case "league":
        return `Match ${props.matchState.currentMatchNumber} / ${props.matchState.totalMatches}`;
      case "knockout":
        return `Knock-Out · Best of ${props.config.matchLength}`;
      case "summer":
        return `Summer League · Best of ${props.config.matchLength}`;
      default:
        return `Best of ${props.config.matchLength}`;
    }
  };

  // Whose serve is it right now, derived from the score.
  const serveInfo = createMemo(() =>
    getServeInfo(
      props.matchState.player1.score,
      props.matchState.player2.score,
      props.config.winningScore,
      props.matchState.firstServer,
      props.config.doubles,
      props.matchState.doublesServerStart,
    ),
  );

  // Shared win handling: a game is won, update games; if that wins the match
  // (best-of-matchLength) show MatchOver (keeping the games tally for display);
  // otherwise show GameOver. League records the team point on a match win but
  // only advances to the next fixture when the user continues (see Game.tsx).
  const player1Scored = () =>
    props.setMatchState((state) => {
      const nextScore = state.player1.score + 1;
      if (
        nextScore >= props.config.winningScore &&
        nextScore > state.player2.score + 1
      ) {
        const nextGames = state.player1.games + 1;
        const matchWon = nextGames >= gamesToWin(props.config.matchLength);
        const gameLog = [
          ...state.gameLog,
          {
            winner: state.player1,
            player1Score: nextScore,
            player2Score: state.player2.score,
          },
        ];
        props.setMode(matchWon ? GameMode.MatchOver : GameMode.GameOver);
        return {
          ...state,
          gameLog,
          player1: { ...state.player1, games: nextGames, score: nextScore },
          homeTeamScore:
            matchWon && props.config.matchType === "league"
              ? state.homeTeamScore + 1
              : state.homeTeamScore,
        };
      }
      return {
        ...state,
        player1: { ...state.player1, score: nextScore },
      };
    });

  const player2Scored = () =>
    props.setMatchState((state) => {
      const nextScore = state.player2.score + 1;
      if (
        nextScore >= props.config.winningScore &&
        nextScore > state.player1.score + 1
      ) {
        const nextGames = state.player2.games + 1;
        const matchWon = nextGames >= gamesToWin(props.config.matchLength);
        const gameLog = [
          ...state.gameLog,
          {
            winner: state.player2,
            player1Score: state.player1.score,
            player2Score: nextScore,
          },
        ];
        props.setMode(matchWon ? GameMode.MatchOver : GameMode.GameOver);
        return {
          ...state,
          gameLog,
          player2: { ...state.player2, games: nextGames, score: nextScore },
          visitorTeamScore:
            matchWon && props.config.matchType === "league"
              ? state.visitorTeamScore + 1
              : state.visitorTeamScore,
        };
      }
      return {
        ...state,
        player2: { ...state.player2, score: nextScore },
      };
    });

  const handleTimeout = (player: number) => {
    if (props.matchState.timeoutActive) return;

    props.setMatchState((state) => ({
      ...state,
      timeoutActive: true,
      timeoutPlayer: player,
      timeoutRemaining: props.config.timeoutDuration,
      [player === 1 ? 'player1' : 'player2']: {
        ...state[player === 1 ? 'player1' : 'player2'],
        timeoutsUsed: state[player === 1 ? 'player1' : 'player2'].timeoutsUsed + 1,
      },
    }));

    // Start timeout countdown
    const interval = setInterval(() => {
      props.setMatchState((state) => {
        if (state.timeoutRemaining <= 1) {
          clearInterval(interval);
          return {
            ...state,
            timeoutActive: false,
            timeoutRemaining: 0,
            timeoutPlayer: 0,
          };
        }
        return {
          ...state,
          timeoutRemaining: state.timeoutRemaining - 1,
        };
      });
    }, 1000);

    setTimeoutInterval(interval);
  };

  const cleanupTimeout = () => {
    const interval = timeoutInterval();
    if (interval) {
      clearInterval(interval);
      setTimeoutInterval(null);
    }
  };

  // Cancel an active timeout early and give the player their timeout back.
  const cancelTimeout = () => {
    cleanupTimeout();
    props.setMatchState((state) => {
      const player = state.timeoutPlayer;
      const refunded =
        player === 1 || player === 2
          ? {
              [player === 1 ? "player1" : "player2"]: {
                ...state[player === 1 ? "player1" : "player2"],
                timeoutsUsed: Math.max(
                  0,
                  state[player === 1 ? "player1" : "player2"].timeoutsUsed - 1,
                ),
              },
            }
          : {};
      return {
        ...state,
        ...refunded,
        timeoutActive: false,
        timeoutRemaining: 0,
        timeoutPlayer: 0,
      };
    });
  };

  const player1Correction = () => {
    props.setMatchState((state) => {
      let nextScore = state.player1.score - 1;
      if (nextScore < 0) {
        return state;
      }
      return {
        ...state,
        player1: {
          ...state.player1,
          score: nextScore,
        },
      };
    });
  };
  const player2Correction = () => {
    props.setMatchState((state) => {
      let nextScore = state.player2.score - 1;
      if (nextScore < 0) {
        return state;
      }
      return {
        ...state,
        player2: {
          ...state.player2,
          score: nextScore,
        },
      };
    });
  };

  // Yellow card handlers (warnings carry through the whole match).
  const addCard = (player: number) =>
    props.setMatchState((state) => ({
      ...state,
      [player === 1 ? "player1" : "player2"]: {
        ...state[player === 1 ? "player1" : "player2"],
        yellowCards: state[player === 1 ? "player1" : "player2"].yellowCards + 1,
      },
    }));
  const removeCard = (player: number) =>
    props.setMatchState((state) => ({
      ...state,
      [player === 1 ? "player1" : "player2"]: {
        ...state[player === 1 ? "player1" : "player2"],
        yellowCards: Math.max(
          0,
          state[player === 1 ? "player1" : "player2"].yellowCards - 1,
        ),
      },
    }));

  const player1AddCard = () => addCard(1);
  const player1RemoveCard = () => removeCard(1);
  const player2AddCard = () => addCard(2);
  const player2RemoveCard = () => removeCard(2);

  // Set which side serves first this game (for correcting the serve indicator).
  const setFirstServer = (side: number) =>
    props.setMatchState((state) => ({ ...state, firstServer: side }));
  // Doubles: rotate which team-mate of the serving side is serving.
  const toggleDoublesServer = () =>
    props.setMatchState((state) => ({
      ...state,
      doublesServerStart: (state.doublesServerStart + 1) % 2,
    }));

  const leftPlayer = (): SidePlayer =>
    props.matchState.swapped
      ? {
          ...props.matchState.player2,
          onScore: player2Scored,
          onCorrection: player2Correction,
          onAddCard: player2AddCard,
          onRemoveCard: player2RemoveCard,
          redNumber: player2RedNumber,
        }
      : {
          ...props.matchState.player1,
          onScore: player1Scored,
          onCorrection: player1Correction,
          onAddCard: player1AddCard,
          onRemoveCard: player1RemoveCard,
          redNumber: player1RedNumber,
        };

  const rightPlayer = (): SidePlayer =>
    props.matchState.swapped
      ? {
          ...props.matchState.player1,
          onScore: player1Scored,
          onCorrection: player1Correction,
          onAddCard: player1AddCard,
          onRemoveCard: player1RemoveCard,
          redNumber: player1RedNumber,
        }
      : {
          ...props.matchState.player2,
          onScore: player2Scored,
          onCorrection: player2Correction,
          onAddCard: player2AddCard,
          onRemoveCard: player2RemoveCard,
          redNumber: player2RedNumber,
        };

  const leftPlayerNumber = () => (props.matchState.swapped ? 2 : 1);
  const rightPlayerNumber = () => (props.matchState.swapped ? 1 : 2);

  // Per-game scoreline for a given player number (1 or 2): the points they
  // scored in each completed game of the current match, with win/loss flag.
  const gameHistory = (playerNo: number) =>
    props.matchState.gameLog.map((g) => ({
      mine: playerNo === 1 ? g.player1Score : g.player2Score,
      theirs: playerNo === 1 ? g.player2Score : g.player1Score,
    }));

  // Flash the red "corrected" number on whichever player is on a given side.
  const flashSide = (side: "left" | "right") => {
    const onLeftIsP1 = !props.matchState.swapped;
    const setRed =
      (side === "left") === onLeftIsP1 ? setPlayer1RedNumber : setPlayer2RedNumber;
    setRed(true);
    setTimeout(() => setRed(false), 300);
  };

  // Keyboard scoring is tied to the PHYSICAL SIDE, not the player: the key
  // bound to "player1Key" always scores the left side, "player2Key" the right.
  // So when players switch ends the keys stay put (the on-screen buttons, which
  // are also side-based, behave the same way).
  const handleKeyUp = (ev: KeyboardEvent) => {
    if (props.mode === GameMode.Game) {
      ev.preventDefault();
      if (ev.key === props.config.player1Key) {
        leftPlayer().onScore();
      } else if (ev.key === props.config.player2Key) {
        rightPlayer().onScore();
      } else if (ev.key === props.config.scoreCorrectionKey) {
        props.setMode(GameMode.Correction);
      } else if (ev.key === props.config.player1CorrectionKey) {
        flashSide("left");
        leftPlayer().onCorrection();
      } else if (ev.key === props.config.player2CorrectionKey) {
        flashSide("right");
        rightPlayer().onCorrection();
      }
    } else if (props.mode === GameMode.Correction) {
      ev.preventDefault();
      if (
        ev.key === props.config.player1Key ||
        ev.key === props.config.player1CorrectionKey
      ) {
        leftPlayer().onCorrection();
      } else if (
        ev.key === props.config.player2Key ||
        ev.key === props.config.player2CorrectionKey
      ) {
        rightPlayer().onCorrection();
      } else if (ev.key === props.config.scoreCorrectionKey) {
        props.setMode(GameMode.Game);
      }
    }
  };
  onMount(() => {
    if (globalThis.addEventListener) {
      globalThis.addEventListener("keyup", handleKeyUp);
    }
  });
  onCleanup(() => {
    if (globalThis.removeEventListener) {
      globalThis.removeEventListener("keyup", handleKeyUp);
    }
    cleanupTimeout();
  });

  return (
    <div class="flex flex-col h-full py-2 gap-2">
      {/* Team Names and Match Score Header — pinned to the top */}
      <header class="shrink-0 grid grid-cols-3 items-center gap-2 py-2 px-4 sm:px-8 bg-white/5 backdrop-blur rounded-xl border border-white/10">
        <div class="text-center">
          <h2 class="text-base sm:text-xl lg:text-2xl font-bold font-sports text-sky-300 truncate">
            {props.matchState.swapped
              ? (props.matchState.visitorTeamName || "Visitor Team")
              : (props.matchState.homeTeamName || "Home Team")
            }
          </h2>
          {props.config.matchType === "league" && (
            <div class="text-2xl sm:text-3xl lg:text-4xl font-bold font-mono text-sky-200">
              {props.matchState.swapped
                ? props.matchState.visitorTeamScore
                : props.matchState.homeTeamScore
              }
            </div>
          )}
        </div>

        <div class="text-center">
          <div
            class="text-xs sm:text-base lg:text-lg font-sports text-gray-300 uppercase tracking-widest"
            data-testid="match-center-label"
          >
            {centerLabel()}
          </div>
          {props.config.doubles && (
            <div class="text-[0.6rem] sm:text-xs font-mono text-amber-300 uppercase tracking-widest mt-0.5">
              Doubles
            </div>
          )}
        </div>

        <div class="text-center">
          <h2 class="text-base sm:text-xl lg:text-2xl font-bold font-sports text-rose-300 truncate">
            {props.matchState.swapped
              ? (props.matchState.homeTeamName || "Home Team")
              : (props.matchState.visitorTeamName || "Visitor Team")
            }
          </h2>
          {props.config.matchType === "league" && (
            <div class="text-2xl sm:text-3xl lg:text-4xl font-bold font-mono text-rose-200">
              {props.matchState.swapped
                ? props.matchState.homeTeamScore
                : props.matchState.visitorTeamScore
              }
            </div>
          )}
        </div>
      </header>

      <main class="flex-1 min-h-0 grid grid-cols-2 gap-2">
        <PlayerScore
          mode={props.mode}
          showBorder={true}
          name={leftPlayer().name}
          partnerName={leftPlayer().partnerName}
          reverse={false}
          score={leftPlayer().score}
          games={leftPlayer().games}
          yellowCards={leftPlayer().yellowCards}
          onScore={leftPlayer().onScore}
          onCorrection={leftPlayer().onCorrection}
          onAddCard={leftPlayer().onAddCard}
          onRemoveCard={leftPlayer().onRemoveCard}
          redNumber={leftPlayer().redNumber()}
          testid="left"
          player={leftPlayerNumber()}
          timeoutsUsed={props.matchState.swapped ? props.matchState.player2.timeoutsUsed : props.matchState.player1.timeoutsUsed}
          onTimeout={handleTimeout}
          timeoutActive={props.matchState.timeoutActive}
          doubles={props.config.doubles}
          showServer={props.config.showServer}
          serving={serveInfo().side === leftPlayerNumber()}
          servingPartnerIndex={serveInfo().doublesIndex}
          onSetServer={() => setFirstServer(leftPlayerNumber())}
          onToggleDoublesServer={toggleDoublesServer}
          presentation={props.presentation}
          gameScores={gameHistory(leftPlayerNumber())}
        />
        <PlayerScore
          mode={props.mode}
          showBorder={false}
          name={rightPlayer().name}
          partnerName={rightPlayer().partnerName}
          reverse={true}
          score={rightPlayer().score}
          games={rightPlayer().games}
          yellowCards={rightPlayer().yellowCards}
          onScore={rightPlayer().onScore}
          onCorrection={rightPlayer().onCorrection}
          onAddCard={rightPlayer().onAddCard}
          onRemoveCard={rightPlayer().onRemoveCard}
          redNumber={rightPlayer().redNumber()}
          testid="right"
          player={rightPlayerNumber()}
          timeoutsUsed={props.matchState.swapped ? props.matchState.player1.timeoutsUsed : props.matchState.player2.timeoutsUsed}
          onTimeout={handleTimeout}
          timeoutActive={props.matchState.timeoutActive}
          doubles={props.config.doubles}
          showServer={props.config.showServer}
          serving={serveInfo().side === rightPlayerNumber()}
          servingPartnerIndex={serveInfo().doublesIndex}
          onSetServer={() => setFirstServer(rightPlayerNumber())}
          onToggleDoublesServer={toggleDoublesServer}
          presentation={props.presentation}
          gameScores={gameHistory(rightPlayerNumber())}
        />
      </main>

      {/* Bottom action row: left score button | Fix | right score button.
          Side padding leaves room for the fixed Menu button (bottom-right). */}
      <Show when={!props.presentation}>
        {/* Single bottom bar: + | Fix Score | + , with a right slot reserved
            for the fixed Menu button so all four sit on the same level. */}
        <div class="shrink-0 flex items-stretch justify-center gap-2 h-[18px]">
          <Show when={props.mode === GameMode.Game}>
            <button
              class="w-32 h-full text-base leading-none font-bold text-black bg-white rounded-md shadow-[0_2px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all flex items-center justify-center"
              data-testid="left-button"
              aria-label={`${leftPlayer().name} scored`}
              title={`${leftPlayer().name} scored`}
              onClick={() => leftPlayer().onScore()}
            >
              +
            </button>
            <button
              class="h-full px-2 text-[10px] leading-none font-mono font-bold text-black uppercase bg-white/80 rounded-md shadow-[0_1px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all selectable whitespace-nowrap flex items-center"
              data-testid="correction-button"
              title="Correct a scoring mistake"
              onClick={() => props.setMode(GameMode.Correction)}
            >
              Fix Score
            </button>
            <button
              class="w-32 h-full text-base leading-none font-bold text-black bg-white rounded-md shadow-[0_2px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all flex items-center justify-center"
              data-testid="right-button"
              aria-label={`${rightPlayer().name} scored`}
              title={`${rightPlayer().name} scored`}
              onClick={() => rightPlayer().onScore()}
            >
              +
            </button>
          </Show>
          <Show when={props.mode === GameMode.Correction}>
            <button
              class="w-32 h-full text-base leading-none font-bold text-white bg-rose-600 rounded-md shadow-[0_2px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all flex items-center justify-center"
              data-testid="left-correction-button"
              aria-label={`subtract a point from ${leftPlayer().name}`}
              title={`subtract a point from ${leftPlayer().name}`}
              onClick={() => leftPlayer().onCorrection()}
            >
              −
            </button>
            <button
              class="h-full px-2 text-[10px] leading-none font-mono font-bold text-white uppercase bg-emerald-500 rounded-md shadow-[0_1px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all selectable whitespace-nowrap flex items-center"
              data-testid="end-correction-button"
              title="Finish correcting"
              onClick={() => props.setMode(GameMode.Game)}
            >
              Done Fixing
            </button>
            <button
              class="w-32 h-full text-base leading-none font-bold text-white bg-rose-600 rounded-md shadow-[0_2px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all flex items-center justify-center"
              data-testid="right-correction-button"
              aria-label={`subtract a point from ${rightPlayer().name}`}
              title={`subtract a point from ${rightPlayer().name}`}
              onClick={() => rightPlayer().onCorrection()}
            >
              −
            </button>
          </Show>
        </div>
      </Show>

      <TimeoutTimer
        timeoutRemaining={props.matchState.timeoutRemaining}
        timeoutPlayer={props.matchState.timeoutPlayer}
        player1Name={props.matchState.player1.name}
        player2Name={props.matchState.player2.name}
        onCancel={cancelTimeout}
      />
    </div>
  );
}
