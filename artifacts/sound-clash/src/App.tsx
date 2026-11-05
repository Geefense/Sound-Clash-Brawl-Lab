import { useCallback, useEffect, useRef, useState } from 'react';
import Phaser from 'phaser';
import { GameScene } from './game/GameScene';
import { SoundEffects } from './game/SoundEffects';
import type { MatchSnapshot, TouchAction } from './game/types';

const initialSnapshot: MatchSnapshot = {
  playerHealth: 100,
  rivalHealth: 100,
  timeLeft: 90,
  status: 'pre-round',
  winner: null,
  matchWinner: null,
  roundWinner: null,
  roundEndReason: null,
  threePieceKO: false,
  round: 1,
  playerWins: 0,
  rivalWins: 0,
};

function Home() {
  const mountRef = useRef<HTMLDivElement>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const soundRef = useRef<SoundEffects | null>(null);
  const [snapshot, setSnapshot] = useState(initialSnapshot);
  const [soundOn, setSoundOn] = useState(false);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return;
    const sound = new SoundEffects();
    soundRef.current = sound;
    const scene = new GameScene(setSnapshot);
    const game = new Phaser.Game({
      type: Phaser.AUTO,
      parent: mount,
      width: 1280,
      height: 720,
      backgroundColor: '#243d3d',
      transparent: false,
      antialias: true,
      render: { pixelArt: false, roundPixels: true },
      scale: {
        mode: Phaser.Scale.FIT,
        autoCenter: Phaser.Scale.CENTER_BOTH,
        width: 1280,
        height: 720,
      },
      scene: [scene],
      input: { keyboard: true, touch: true },
      audio: { noAudio: true },
    });
    gameRef.current = game;
    const onSound = (event: Event) => sound.play((event as CustomEvent<'hit' | 'block' | 'jump' | 'round' | 'ko'>).detail);
    window.addEventListener('sound-clash:sound', onSound);
    return () => {
      window.removeEventListener('sound-clash:sound', onSound);
      game.destroy(true);
      gameRef.current = null;
      sound.dispose();
      soundRef.current = null;
    };
  }, []);

  const toggleSound = useCallback(() => {
    setSoundOn(current => {
      soundRef.current?.setEnabled(!current);
      return !current;
    });
  }, []);

  const rematch = useCallback(() => {
    setSnapshot(initialSnapshot);
    window.dispatchEvent(new CustomEvent('sound-clash:restart'));
  }, []);

  const touchAction = (action: TouchAction, pressed: boolean) => {
    window.dispatchEvent(new CustomEvent('sound-clash:touch', { detail: { action, pressed } }));
  };

  const time = `0:${String(snapshot.timeLeft).padStart(2, '0')}`;
  const resultTitle = snapshot.matchWinner === 'draw'
    ? 'SPLIT THE SOUND'
    : snapshot.matchWinner === 'player' ? 'SIDEWINDER TAKES IT' : 'BASSLINE TAKES IT';
  const resultDetail = snapshot.matchWinner === 'draw'
    ? 'Even stevens. Run it back?'
    : snapshot.matchWinner === 'player' ? 'Your set, your victory.' : 'The rival took the set.';

  return (
    <main className="game-page">
      <div className="page-shell">
        <header className="topbar">
          <div className="brand" aria-label="Sound Clash">
            <span className="brand-mark" aria-hidden="true">S</span>
            <span className="brand-name">SOUND<span>CLASH</span></span>
          </div>
          <div className="edition">Kingston meets the 6ix · Arcade prototype</div>
        </header>

        <section className="intro-row" aria-labelledby="page-title">
          <div className="intro-copy">
            <span className="eyebrow">One round. All rhythm.</span>
            <h1 id="page-title" className="page-title">Bring the noise.</h1>
          </div>
          <p className="intro-note">A friendly street-corner showdown. Find your range and take the set.</p>
        </section>

        <section className="match-shell" aria-label="Sound Clash fight">
          <div className="scorebar">
            <div className="fighter-info">
              <div className="fighter-heading">
                <span className="fighter-name">SIDEWINDER</span>
                <span className="fighter-chip">YOU</span>
              </div>
              <span className="fighter-origin">Kingston · Selector</span>
              <div className="health-track" aria-label={`Sidewinder health ${snapshot.playerHealth}%`}>
                <div className="win-indicators">
                  {[0, 1].map(i => <div key={i} className={`win-dot ${snapshot.playerWins > i ? 'won' : ''}`} />)}
                </div>
                <div className="health-fill" style={{ width: `${snapshot.playerHealth}%` }} />
              </div>
            </div>
            <div className="round-clock" aria-live="polite">
              <span className="clock-label">ROUND {String(snapshot.round).padStart(2, '0')}</span>
              <span className="clock-time" data-testid="text-round-timer">{time}</span>
            </div>
            <div className="fighter-info right">
              <div className="fighter-heading">
                <span className="fighter-chip cpu">CPU</span>
                <span className="fighter-name">BASSLINE</span>
              </div>
              <span className="fighter-origin">Toronto · Soundboy</span>
              <div className="health-track" aria-label={`Bassline health ${snapshot.rivalHealth}%`}>
                <div className="win-indicators rival">
                  {[0, 1].map(i => <div key={i} className={`win-dot ${snapshot.rivalWins > i ? 'won' : ''}`} />)}
                </div>
                <div className="health-fill" style={{ width: `${snapshot.rivalHealth}%` }} />
              </div>
            </div>
          </div>

          <div className="arena-frame" aria-label="Live fighting arena">
            <div className="game-mount" ref={mountRef} data-testid="game-canvas" />
            <div className="arena-vignette" />

            {snapshot.status === 'pre-round' && (
              <div className="overlay-screen">
                <h2 className="overlay-title">ROUND {snapshot.round}</h2>
              </div>
            )}
            {(snapshot.status === 'round-transition' || snapshot.status === 'ko-announcement') && (
              <div className="overlay-screen">
                <h2 className="overlay-title ko-text">{snapshot.status === 'ko-announcement' ? (snapshot.threePieceKO ? 'HIM DUN!' : 'KO!') : snapshot.roundEndReason === 'timeout' ? 'TIME!' : 'ROUND OVER'}</h2>
                <div className="overlay-subtitle">
                  {snapshot.roundWinner === 'player' ? 'SIDEWINDER WINS' : snapshot.roundWinner === 'rival' ? 'BASSLINE WINS' : 'DRAW'}
                </div>
              </div>
            )}
            {snapshot.status === 'finished' && (
              <div className="result-screen" role="dialog" aria-modal="true" aria-labelledby="result-title">
                <div className="result-card">
                  {snapshot.matchWinner !== 'draw' && (
                    <div className="champion-banner" data-testid="text-champion-sound">CHAMPION SOUND!</div>
                  )}
                  <span className="result-kicker">The block party verdict</span>
                  <h2 id="result-title" className="result-title">{resultTitle}</h2>
                  <p className="result-detail">{resultDetail}</p>
                  <button className="rematch-button" onClick={rematch} data-testid="button-rematch">
                    Run it back
                  </button>
                </div>
              </div>
            )}
          </div>
          <div className="game-footer">
            <span className="footer-status"><span className="live-dot" />{snapshot.status === 'playing' ? 'LIVE FROM THE CORNER' : 'SET COMPLETE'}</span>
            <button
              className="sound-toggle"
              type="button"
              aria-pressed={soundOn}
              aria-label={soundOn ? 'Turn sound effects off' : 'Turn sound effects on'}
              onClick={toggleSound}
              data-testid="button-sound-toggle"
            >
              Sound {soundOn ? 'on' : 'off'}
            </button>
          </div>
        </section>

        <section className="below-stage" aria-label="How to play">
          <div className="controls-panel">
            <div className="controls-title">Your controls<small>Keyboard · Player one</small></div>
            <div className="control-groups">
              <div className="control-group"><span className="keycap">A</span><span className="keycap">D</span><span className="control-text">Move</span></div>
              <div className="control-group"><span className="keycap">W</span><span className="control-text">Jump</span></div>
              <div className="control-group"><span className="keycap">S</span><span className="control-text">Block</span></div>
              <div className="control-group"><span className="keycap">J</span><span className="control-text">Jab</span></div>
              <div className="control-group"><span className="keycap">K</span><span className="control-text">Heavy head</span></div>
              <div className="control-group"><span className="keycap">L</span><span className="control-text">Body shot</span></div>
              <div className="control-group"><span className="keycap">I</span><span className="control-text">Upper Box</span></div>
            </div>
          </div>
          <div className="match-note">
            <strong>Catch the beat, then close the gap.</strong>
            Land J → L → I unblocked for the Three Piece. Hold S to block.
          </div>
        </section>

        <div className="touch-controls" aria-label="Touch fighting controls">
          <div className="touch-cluster">
            <TouchButton label="Left" action="left" onAction={touchAction} />
            <TouchButton label="Right" action="right" onAction={touchAction} />
            <TouchButton label="Jump" action="jump" onAction={touchAction} />
            <TouchButton label="Block" action="block" onAction={touchAction} />
          </div>
          <div className="touch-cluster">
            <TouchButton label="Jab" action="light" onAction={touchAction} actionButton />
            <TouchButton label="Head" action="heavy" onAction={touchAction} actionButton />
            <TouchButton label="Body" action="body" onAction={touchAction} actionButton />
            <TouchButton label="Upper Box" action="upper" onAction={touchAction} actionButton />
          </div>
        </div>
      </div>
    </main>
  );
}

function TouchButton({
  label,
  action,
  onAction,
  actionButton = false,
}: {
  label: string;
  action: TouchAction;
  onAction: (action: TouchAction, pressed: boolean) => void;
  actionButton?: boolean;
}) {
  return (
    <button
      type="button"
      className={`touch-button${actionButton ? ' action' : ''}`}
      aria-label={label}
      data-testid={`touch-${action}`}
      onPointerDown={event => { event.preventDefault(); event.currentTarget.setPointerCapture(event.pointerId); onAction(action, true); }}
      onPointerUp={() => onAction(action, false)}
      onPointerCancel={() => onAction(action, false)}
      onLostPointerCapture={() => onAction(action, false)}
      onContextMenu={event => event.preventDefault()}
    >
      {label}
    </button>
  );
}

function App() {
  return <Home />;
}

export default App;
