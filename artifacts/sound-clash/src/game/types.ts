export type MatchStatus = 'playing' | 'finished';

export type MatchSnapshot = {
  playerHealth: number;
  rivalHealth: number;
  timeLeft: number;
  status: MatchStatus;
  winner: 'player' | 'rival' | 'draw' | null;
  round: number;
};

export type TouchAction = 'left' | 'right' | 'jump' | 'block' | 'light' | 'heavy';

export const GAME_WIDTH = 1280;
export const GAME_HEIGHT = 720;
