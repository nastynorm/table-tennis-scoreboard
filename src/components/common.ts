export enum GameMode {
  GameOver = 0,
  MatchOver = 1,
  Game = 2,
  Correction = 3,
  Setup = 4,
  SwitchingSides = 5,
  Timeout = 6,
  LeagueOver = 7,
  NewMatch = 8,
}

// TODO: add config for showing swap ends reminder
// TODO: add config for auto-starting the next game

// The kind of competition being scored.
//  - "singles": a single best-of-N match between two players (or a pair).
//  - "league" / "summer" / "knockout": team ties of 7 fixtures (incl. doubles),
//    each fixture best-of-N, first team to win TIE_CLINCH fixtures takes the tie.
//    They differ only in the fixture order (and default best-of).
export type MatchType = "singles" | "league" | "summer" | "knockout";

export function isTeamFormat(t: MatchType): boolean {
  return t === "league" || t === "summer" || t === "knockout";
}

// A team tie is 7 fixtures; the first team to win 4 fixtures wins the tie.
export const TIE_FIXTURES = 7;
export const TIE_CLINCH = 4;

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
  // Games one player/pair must win to take the current match/fixture.
  gamesNeeded: number;
  // Team functionality
  homeTeamName: string;
  visitorTeamName: string;
  homeTeamScore: number;
  visitorTeamScore: number;
  totalMatches: number;
  currentMatchNumber: number;
  // Team line-ups (3 players each) used to generate the fixture scoresheet.
  rosters: Rosters;
};

// Team line-ups for the scoresheet. Doubles uses players 1 & 2 of each team.
export type Rosters = {
  home: string[]; // [H1, H2, H3]
  visitor: string[]; // [V1, V2, V3]
  homeDoubles: string[]; // the two home players for the doubles fixture
  visitorDoubles: string[]; // the two visitor players for the doubles fixture
};

// Payload emitted by the New Match wizard, consumed by Game.startMatch().
export type NewMatchSetup = {
  type: MatchType;
  bestOf: number;
  // singles
  doubles: boolean;
  p1: string;
  p2: string;
  p1Partner: string;
  p2Partner: string;
  // team
  homeTeam: string;
  visitorTeam: string;
  home: string[];
  visitor: string[];
  homeDoubles: string[];
  visitorDoubles: string[];
};

export type Fixture = {
  p1: string;
  p2: string;
  p1Partner: string;
  p2Partner: string;
  doubles: boolean;
};

// Fixture slot order per format ([homeSlot, visitorSlot]; "D" = doubles).
const LEAGUE_ORDER: (number | "D")[][] = [
  [1, 1], [2, 2], [3, 3], ["D", "D"], [1, 2], [3, 1], [2, 3],
];
const CUP_ORDER: (number | "D")[][] = [
  [1, 2], [2, 1], [3, 3], ["D", "D"], [1, 1], [2, 3], [3, 2],
];

// Build the 7-fixture scoresheet for a team tie from the line-ups.
export function teamFixtures(type: MatchType, r: Rosters): Fixture[] {
  const order = type === "league" ? LEAGUE_ORDER : CUP_ORDER;
  return order.map(([hs, vs]) => {
    if (hs === "D") {
      return {
        p1: r.homeDoubles?.[0] || r.home[0] || "H1",
        p1Partner: r.homeDoubles?.[1] || r.home[1] || "H2",
        p2: r.visitorDoubles?.[0] || r.visitor[0] || "V1",
        p2Partner: r.visitorDoubles?.[1] || r.visitor[1] || "V2",
        doubles: true,
      };
    }
    const h = r.home[(hs as number) - 1] || `H${hs}`;
    const v = r.visitor[(vs as number) - 1] || `V${vs}`;
    return { p1: h, p2: v, p1Partner: "", p2Partner: "", doubles: false };
  });
}

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
  matchType: "singles",
};

// Number of games a player must win to take a best-of-N match/fixture.
export function gamesToWin(matchLength: number): number {
  return Math.floor(matchLength / 2) + 1;
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
