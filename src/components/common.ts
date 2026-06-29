export enum GameMode {
  GameOver = 0,
  MatchOver = 1,
  Game = 2,
  Correction = 3,
  Setup = 4,
  SwitchingSides = 5,
  Timeout = 6,
  LeagueOver = 7,
}

// TODO: add config for showing swap ends reminder
// TODO: add config for auto-starting the next game

// The kind of competition being scored. "normal" is a single best-of-N match.
// "league" is the multi-match league night (Home vs Visitor, 7 fixtures).
// "knockout" and "summer" are placeholders that currently play like a normal
// match until their formats are fleshed out.
export type MatchType = "normal" | "league" | "knockout" | "summer";

export type GameConfig = {
  matchLength: number;
  player1Key: string;
  player2Key: string;
  scoreCorrectionKey: string;
  winningScore: number;
  switchSides: boolean;
  player1CorrectionKey: string;
  player2CorrectionKey: string;
  timeoutDuration: number;
  breakDuration: number;
  // Doubles: when enabled each side has two players and the serve indicator
  // tracks which of the two team-mates is serving.
  doubles: boolean;
  // Show the serving indicator (ball) and rotate it automatically.
  showServer: boolean;
  // Which competition format is being scored.
  matchType: MatchType;
};

export type Player = {
  name: string;
  score: number;
  games: number;
  timeoutsUsed: number;
  // Yellow card / warnings issued to this player (0 = none).
  yellowCards: number;
  // Partner name, only used in doubles mode.
  partnerName: string;
};

export type GameResult = {
  winner: Player;
  player1Score: number;
  player2Score: number;
};

export type MatchState = {
  player1: Player;
  player2: Player;
  gameLog: GameResult[];
  swapped: boolean;
  timeoutActive: boolean;
  timeoutPlayer: number;
  timeoutRemaining: number;
  // Serving: which side served the FIRST point of the current game (1 or 2).
  // The current server is derived from this plus the score.
  firstServer: number;
  // Doubles only: offset (0|1) selecting which team-mate of the serving side
  // begins serving for the current game.
  doublesServerStart: number;
  // Team functionality
  homeTeamName: string;
  visitorTeamName: string;
  homeTeamScore: number;
  visitorTeamScore: number;
  totalMatches: number;
  currentMatchNumber: number;
};

export const defaultGameConfig: GameConfig = {
  matchLength: 5,
  winningScore: 11,
  switchSides: true,
  player1Key: "ArrowLeft",
  player2Key: "ArrowRight",
  scoreCorrectionKey: "Tab",
  player1CorrectionKey: "1",
  player2CorrectionKey: "2",
  timeoutDuration: 60, // 1 minute timeout
  breakDuration: 60, // 1 minute break between games
  doubles: false,
  showServer: true,
  matchType: "league",
};

// Number of games a player must win to take the match (best-of-matchLength).
export function gamesToWin(matchLength: number): number {
  return Math.floor(matchLength / 2) + 1;
}

// League fixture player names by match number (Home vs Visitor rotation).
export function generatePlayerNames(matchNumber: number): {
  player1Name: string;
  player2Name: string;
} {
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
      return { player1Name: `H${matchNumber}`, player2Name: `V${matchNumber}` };
  }
}

export type ServeInfo = {
  // Which side currently holds serve (1 = player1, 2 = player2).
  side: number;
  // Doubles only: which team-mate of the serving side is serving
  // (0 = primary name, 1 = partner name).
  doublesIndex: number;
};

/**
 * Derive the current server from the score, following ITTF rules:
 *  - service alternates every 2 points,
 *  - once both players reach (winningScore - 1) ("deuce") it alternates every point.
 * In doubles the four players rotate in a fixed cycle, so the serving team-mate
 * changes every time a side regains the serve.
 */
export function getServeInfo(
  p1Score: number,
  p2Score: number,
  winningScore: number,
  firstServer: number,
  doubles: boolean,
  doublesServerStart: number,
): ServeInfo {
  const total = p1Score + p2Score;
  const deuceThreshold = 2 * (winningScore - 1);
  let changes: number;
  if (total <= deuceThreshold) {
    changes = Math.floor(total / 2);
  } else {
    changes = winningScore - 1 + (total - deuceThreshold);
  }
  const side = changes % 2 === 0 ? firstServer : firstServer === 1 ? 2 : 1;

  let doublesIndex = 0;
  if (doubles) {
    // Every full A/B cycle (2 service changes) the serving team-mate flips.
    doublesIndex = (Math.floor(changes / 2) + doublesServerStart) % 2;
  }
  return { side, doublesIndex };
}
