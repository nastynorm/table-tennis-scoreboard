import {
  createSignal,
  onCleanup,
  onMount,
  type Accessor,
  type Setter,
} from "solid-js";
import { GameMode, type GameConfig, type MatchState } from "./common";
import PlayerScore from "./PlayerScore";
import TimeoutTimer from "./TimeoutTimer";

// TODO: option to hide ui
interface PlayingGameProps {
  mode: GameMode;
  setMode: Setter<GameMode>;
  config: GameConfig;
  matchState: MatchState;
  setMatchState: Setter<MatchState>;
}

interface SidePlayer {
  name: string;
  score: number;
  games: number;
  onScore: Function;
  onCorrection: Function;
  redNumber: Accessor<boolean>;
}

export default function PlayingGame(props: PlayingGameProps) {
  const [showAdvancedConfig, setShowAdvancedConfig] = createSignal(false);
  const [player1RedNumber, setPlayer1RedNumber] = createSignal(false);
  const [player2RedNumber, setPlayer2RedNumber] = createSignal(false);
  const [timeoutInterval, setTimeoutInterval] = createSignal<NodeJS.Timeout | null>(null);

  const player1Scored = () =>
    props.setMatchState((state) => {
      const nextScore = state.player1.score + 1;
      // check for win
      if (
        nextScore >= props.config.winningScore &&
        nextScore > state.player2.score + 1
      ) {
        // update games
        let nextGames = state.player1.games + 1;
        // check for game over or match over
        if (nextGames > props.config.matchLength / 2) {
          props.setMode(GameMode.MatchOver);
        } else {
          props.setMode(GameMode.GameOver);
        }
        return {
          ...state,
          gameLog: [
            ...state.gameLog,
            {
              winner: state.player1,
              player1Score: nextScore,
              player2Score: state.player2.score,
            },
          ],
          player1: {
            ...state.player1,
            games: nextGames,
            score: nextScore,
          },
        };
      }
      return {
        ...state,
        player1: {
          ...state.player1,
          score: nextScore,
        },
      };
    });

  const player2Scored = () =>
    props.setMatchState((state) => {
      const nextScore = state.player2.score + 1;
      // check for win
      if (
        nextScore >= props.config.winningScore &&
        nextScore > state.player1.score + 1
      ) {
        // update games
        let nextGames = state.player2.games + 1;
        // check for game over or match over
        if (nextGames > props.config.matchLength / 2) {
          props.setMode(GameMode.MatchOver);
        } else {
          props.setMode(GameMode.GameOver);
        }
        return {
          ...state,
          gameLog: [
            ...state.gameLog,
            {
              winner: state.player2,
              player1Score: state.player1.score,
              player2Score: nextScore,
            },
          ],
          player2: {
            ...state.player2,
            games: nextGames,
            score: nextScore,
          },
        };
      }
      return {
        ...state,
        player2: {
          ...state.player2,
          score: nextScore,
        },
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
  const leftPlayer = (): SidePlayer =>
    props.matchState.swapped
      ? {
          ...props.matchState.player2,
          onScore: player2Scored,
          onCorrection: player2Correction,
          redNumber: player2RedNumber,
        }
      : {
          ...props.matchState.player1,
          onScore: player1Scored,
          onCorrection: player1Correction,
          redNumber: player1RedNumber,
        };

  const rightPlayer = (): SidePlayer =>
    props.matchState.swapped
      ? {
          ...props.matchState.player1,
          onScore: player1Scored,
          onCorrection: player1Correction,
          redNumber: player1RedNumber,
        }
      : {
          ...props.matchState.player2,
          onScore: player2Scored,
          onCorrection: player2Correction,
          redNumber: player2RedNumber,
        };

  const handleKeyUp = (ev: KeyboardEvent) => {
    console.log("keyboard event");
    if (props.mode === GameMode.Game) {
      ev.preventDefault();
      if (ev.key === props.config.player1Key) {
        player1Scored();
      } else if (ev.key === props.config.player2Key) {
        player2Scored();
      } else if (ev.key === props.config.scoreCorrectionKey) {
        props.setMode(GameMode.Correction);
      } else if (ev.key === props.config.player1CorrectionKey) {
        setPlayer1RedNumber(true);
        player1Correction();
        setTimeout(() => setPlayer1RedNumber(false), 300);
      } else if (ev.key === props.config.player2CorrectionKey) {
        setPlayer2RedNumber(true);
        player2Correction();
        setTimeout(() => setPlayer2RedNumber(false), 300);
      }
    } else if (props.mode === GameMode.Correction) {
      ev.preventDefault();
      if (
        ev.key === props.config.player1Key ||
        ev.key === props.config.player1CorrectionKey
      ) {
        player1Correction();
      } else if (
        ev.key === props.config.player2Key ||
        ev.key === props.config.player2CorrectionKey
      ) {
        player2Correction();
      } else if (ev.key === props.config.scoreCorrectionKey) {
        props.setMode(GameMode.Game);
      }
    }
  };
  onMount(() => {
    if (globalThis.addEventListener) {
      console.log("added event listener");
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
    <>
      <main class="grid grid-cols-2">
        <PlayerScore
          mode={props.mode}
          showBorder={true}
          name={leftPlayer().name}
          reverse={false}
          score={leftPlayer().score}
          games={leftPlayer().games}
          onScore={leftPlayer().onScore}
          onCorrection={leftPlayer().onCorrection}
          redNumber={leftPlayer().redNumber()}
          testid="left"
          player={props.matchState.swapped ? 2 : 1}
          timeoutsUsed={props.matchState.swapped ? props.matchState.player2.timeoutsUsed : props.matchState.player1.timeoutsUsed}
          onTimeout={handleTimeout}
          timeoutActive={props.matchState.timeoutActive}
        />
        <PlayerScore
          mode={props.mode}
          showBorder={false}
          name={rightPlayer().name}
          reverse={true}
          score={rightPlayer().score}
          games={rightPlayer().games}
          onScore={rightPlayer().onScore}
          onCorrection={rightPlayer().onCorrection}
          redNumber={rightPlayer().redNumber()}
          testid="right"
          player={props.matchState.swapped ? 1 : 2}
          timeoutsUsed={props.matchState.swapped ? props.matchState.player1.timeoutsUsed : props.matchState.player2.timeoutsUsed}
          onTimeout={handleTimeout}
          timeoutActive={props.matchState.timeoutActive}
        />
      </main>
      <TimeoutTimer
        timeoutRemaining={props.matchState.timeoutRemaining}
        timeoutPlayer={props.matchState.timeoutPlayer}
        player1Name={props.matchState.player1.name}
        player2Name={props.matchState.player2.name}
      />
    </>
  );
}
