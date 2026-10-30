export type MatchStatus = 'impact-freeze' | 'knockdown' | 'ko-announcement' | 'pre-round' | 'playing' | 'round-transition' | 'finished';

export type MatchSnapshot = {
  playerHealth: number;
  rivalHealth: number;
  timeLeft: number;
  status: MatchStatus;
  winner: 'player' | 'rival' | 'draw' | null;
  matchWinner: 'player' | 'rival' | 'draw' | null;
  roundEndReason: 'ko' | 'timeout' | null;
  roundWinner: 'player' | 'rival' | 'draw' | null;
  round: number;
  playerWins: number;
  rivalWins: number;
};

export type TouchAction = 'left' | 'right' | 'jump' | 'block' | 'light' | 'heavy';

export const GAME_WIDTH = 1280;
export const GAME_HEIGHT = 720;
