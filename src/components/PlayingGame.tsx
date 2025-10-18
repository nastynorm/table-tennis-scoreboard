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

// Helper function to generate player names based on match number
const generatePlayerNames = (matchNumber: number): { player1Name: string; player2Name: string } => {
  switch (matchNumber) {
    case 1:
      return { player1Name: "H1", player2Name: "V1" };
    case 2:
      return { player1Name: "H2", player2Name: "V2" };
    case 3:
      return { player1Name: "H3", player2Name: "V3" };
    case 4:
      return { player1Name: "Doubles-H", player2Name: "Doubles-V" };
    case 5:
      return { player1Name: "H1", player2Name: "V2" };
    case 6:
      return { player1Name: "H3", player2Name: "V1" };
    case 7:
      return { player1Name: "H2", player2Name: "V3" };
    default:
      // Fallback for additional matches
      return { player1Name: `H${matchNumber}`, player2Name: `V${matchNumber}` };
  }
};

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
        let nextHomeTeamScore = state.homeTeamScore;
        let nextCurrentMatchNumber = state.currentMatchNumber;
        
        // Check if match is completed (player reaches 3 games)
        if (nextGames >= 3) {
          nextHomeTeamScore = state.homeTeamScore + 1;
          nextCurrentMatchNumber = state.currentMatchNumber + 1;
          
          // Check if all matches in the league are completed
          if (nextCurrentMatchNumber > (state.totalMatches || 7)) {
            // All matches completed - go to LeagueOver
            props.setMode(GameMode.LeagueOver);
          } else {
            // Reset for next match in the league
            props.setMode(GameMode.GameOver);
          }
          
          // Generate player names for the next match
          const { player1Name: nextPlayer1Name, player2Name: nextPlayer2Name } = generatePlayerNames(nextCurrentMatchNumber);
          
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
            // Reset players for next match with updated names
            player1: {
              ...state.player1,
              name: nextPlayer1Name,
              games: 0,
              score: 0,
            },
            player2: {
              ...state.player2,
              name: nextPlayer2Name,
              games: 0,
              score: 0,
            },
            homeTeamScore: nextHomeTeamScore,
            currentMatchNumber: nextCurrentMatchNumber,
          };
        }
        
        // Regular game win (not match completion)
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
          homeTeamScore: nextHomeTeamScore,
          currentMatchNumber: nextCurrentMatchNumber,
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
        let nextVisitorTeamScore = state.visitorTeamScore;
        let nextCurrentMatchNumber = state.currentMatchNumber;
        
        // Check if match is completed (player reaches 3 games)
        if (nextGames >= 3) {
          nextVisitorTeamScore = state.visitorTeamScore + 1;
          nextCurrentMatchNumber = state.currentMatchNumber + 1;
          
          // Check if all matches in the league are completed
          if (nextCurrentMatchNumber > (state.totalMatches || 7)) {
            // All matches completed - go to LeagueOver
            props.setMode(GameMode.LeagueOver);
          } else {
            // Reset for next match in the league
            props.setMode(GameMode.GameOver);
          }
          
          // Generate player names for the next match
          const { player1Name: nextPlayer1Name, player2Name: nextPlayer2Name } = generatePlayerNames(nextCurrentMatchNumber);
          
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
            // Reset players for next match with updated names
            player1: {
              ...state.player1,
              name: nextPlayer1Name,
              games: 0,
              score: 0,
            },
            player2: {
              ...state.player2,
              name: nextPlayer2Name,
              games: 0,
              score: 0,
            },
            visitorTeamScore: nextVisitorTeamScore,
            currentMatchNumber: nextCurrentMatchNumber,
          };
        }
        
        // Regular game win (not match completion)
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
          visitorTeamScore: nextVisitorTeamScore,
          currentMatchNumber: nextCurrentMatchNumber,
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
      {/* Team Names and Match Score Header */}
      <header class="grid grid-cols-3 items-center py-4 px-8 bg-gray-100 border-b-4 border-black">
        <div class="text-center">
          <h2 class="text-2xl font-bold font-sports text-blue-800">
            {props.matchState.swapped 
              ? (props.matchState.visitorTeamName || "Visitor Team")
              : (props.matchState.homeTeamName || "Home Team")
            }
          </h2>
          <div class="text-4xl font-bold font-mono text-blue-800">
            {props.matchState.swapped 
              ? props.matchState.visitorTeamScore
              : props.matchState.homeTeamScore
            }
          </div>
        </div>
        
        <div class="text-center">
          <div class="text-lg font-sports text-gray-600">
            Match {props.matchState.currentMatchNumber} of {props.matchState.totalMatches}
          </div>
        </div>
        
        <div class="text-center">
          <h2 class="text-2xl font-bold font-sports text-red-800">
            {props.matchState.swapped 
              ? (props.matchState.homeTeamName || "Home Team")
              : (props.matchState.visitorTeamName || "Visitor Team")
            }
          </h2>
          <div class="text-4xl font-bold font-mono text-red-800">
            {props.matchState.swapped 
              ? props.matchState.homeTeamScore
              : props.matchState.visitorTeamScore
            }
          </div>
        </div>
      </header>

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
