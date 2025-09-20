export enum GameMode {
  GameOver = 0,
  MatchOver = 1,
  Game = 2,
  Correction = 3,
  Setup = 4,
  SwitchingSides = 5,
  Timeout = 6,
}

// TODO: add config for showing swap ends reminder
// TODO: add config for auto-starting the next game

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
};

export type Player = {
  name: string;
  score: number;
  games: number;
  timeoutsUsed: number;
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
};
