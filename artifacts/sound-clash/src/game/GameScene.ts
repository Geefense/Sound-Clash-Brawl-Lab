import Phaser from 'phaser';
import { getHitReactionPose } from './visualReactions.ts';
import { getKnockdownPose } from './fighterGeometry.ts';
import { GAME_HEIGHT, GAME_WIDTH, type MatchSnapshot, type TouchAction } from './types.ts';
import { getStrikePose, isAttackAction } from './combatRules.ts';
import {
  FIXED_TIMESTEP,
  type FighterInput,
  type FighterState,
  type GameState,
} from './simulation/types.ts';
import { IMPACT_FREEZE_TICKS, KNOCKDOWN_TICKS, simulateTick } from './simulation/SimulationEngine.ts';
import { createMatchState } from './simulation/initialState.ts';
import {
  FLOOR,
  HEAD_OFFSET,
  HEAD_RADIUS,
  TORSO_HEIGHT,
  TORSO_LEFT,
  TORSO_RIGHT,
  getFighterPose,
} from './fighterGeometry.ts';
import { InputBuffer, NEUTRAL_DEVICE_INPUT, type DeviceAction } from './input/InputBuffer.ts';
import type { InputFrame } from './simulation/replay.ts';

/** Maximum catch-up ticks per rendered frame; prevents input bursts on stalls. */
const MAX_STEPS_PER_FRAME = 5;

/** Keyboard keys that are held rather than tapped. */
const HELD_KEYS: ReadonlyArray<readonly [string, DeviceAction]> = [
  ['left', 'left'],
  ['arrowLeft', 'left'],
  ['right', 'right'],
  ['arrowRight', 'right'],
  ['down', 'block'],
  ['arrowDown', 'block'],
];

/** Keyboard keys that produce exactly one press. */
const PRESS_KEYS: ReadonlyArray<readonly [string, DeviceAction]> = [
  ['up', 'jump'],
  ['arrowUp', 'jump'],
  ['light', 'light'],
  // K is the backhand BOX to the head.
  ['heavy', 'head'],
  // L is the TUMP body shot.
  ['body', 'heavy'],
  ['upper', 'upper'],
];

/**
 * The touch layer's historical labels are translated once, here:
 * touch "heavy" is the head BOX and touch "body" is the TUMP body shot.
 */
const TOUCH_ACTIONS: Record<TouchAction, DeviceAction> = {
  left: 'left',
  right: 'right',
  jump: 'jump',
  block: 'block',
  light: 'light',
  heavy: 'head',
  body: 'heavy',
  upper: 'upper',
};

const NEUTRAL_INPUT: FighterInput = NEUTRAL_DEVICE_INPUT;

/** Deterministic spark RNG, deliberately separate from the combat RNG. */
let sparkSeed = 0x9e3779b9;
function nextSparkRandom(): number {
  sparkSeed = (sparkSeed + 0x6d2b79f5) >>> 0;
  let t = sparkSeed;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

export class GameScene extends Phaser.Scene {
  private onSnapshot: (snapshot: MatchSnapshot) => void;
  private state!: GameState;
  private accumulator = 0;
  private graphics!: Phaser.GameObjects.Graphics;
  private background!: Phaser.GameObjects.Graphics;
  private playerComboLabel!: Phaser.GameObjects.Text;
  private rivalComboLabel!: Phaser.GameObjects.Text;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private inputBuffer = new InputBuffer();
  private publishElapsed = 0;
  private sparks: { x: number; y: number; vx: number; vy: number; life: number; color: number }[] = [];
  private seed = 0;
  private inputLog: InputFrame[] = [];

  private touchHandler = (event: Event) => {
    const detail = (event as CustomEvent<{ action: TouchAction; pressed: boolean }>).detail;
    const device = TOUCH_ACTIONS[detail.action];
    if (!device) return;
    if (detail.pressed) this.inputBuffer.press(device);
    else this.inputBuffer.release(device);
  };
  private restartHandler = () => this.resetMatch();
  private visibilityHandler = () => {
    // Never fast-forward through a hidden tab.
    this.accumulator = 0;
  };

  constructor(onSnapshot: (snapshot: MatchSnapshot) => void) {
    super('SoundClashArena');
    this.onSnapshot = onSnapshot;
  }

  create() {
    this.background = this.add.graphics();
    this.drawArena();
    this.graphics = this.add.graphics();
    this.playerComboLabel = this.add.text(0, 0, '', {
      fontFamily: 'Arial, sans-serif',
      fontSize: '19px',
      fontStyle: 'bold',
      color: '#f0c64c',
      stroke: '#172d32',
      strokeThickness: 5,
      shadow: { color: '#000000', blur: 4, offsetX: 1, offsetY: 2, fill: true },
    }).setOrigin(0.5, 1).setDepth(5).setVisible(false);
    this.rivalComboLabel = this.add.text(0, 0, '', {
      fontFamily: 'Arial, sans-serif',
      fontSize: '19px',
      fontStyle: 'bold',
      color: '#ff916c',
      stroke: '#172d32',
      strokeThickness: 5,
      shadow: { color: '#000000', blur: 4, offsetX: 1, offsetY: 2, fill: true },
    }).setOrigin(0.5, 1).setDepth(5).setVisible(false);
    this.keys = this.input.keyboard!.addKeys({
      left: Phaser.Input.Keyboard.KeyCodes.A,
      right: Phaser.Input.Keyboard.KeyCodes.D,
      up: Phaser.Input.Keyboard.KeyCodes.W,
      down: Phaser.Input.Keyboard.KeyCodes.S,
      arrowLeft: Phaser.Input.Keyboard.KeyCodes.LEFT,
      arrowRight: Phaser.Input.Keyboard.KeyCodes.RIGHT,
      arrowUp: Phaser.Input.Keyboard.KeyCodes.UP,
      arrowDown: Phaser.Input.Keyboard.KeyCodes.DOWN,
      light: Phaser.Input.Keyboard.KeyCodes.J,
      heavy: Phaser.Input.Keyboard.KeyCodes.K,
      body: Phaser.Input.Keyboard.KeyCodes.L,
      upper: Phaser.Input.Keyboard.KeyCodes.I,
    }) as Record<string, Phaser.Input.Keyboard.Key>;
    this.input.keyboard!.addCapture([
      Phaser.Input.Keyboard.KeyCodes.LEFT,
      Phaser.Input.Keyboard.KeyCodes.RIGHT,
      Phaser.Input.Keyboard.KeyCodes.UP,
      Phaser.Input.Keyboard.KeyCodes.DOWN,
      Phaser.Input.Keyboard.KeyCodes.SPACE,
    ]);
    window.addEventListener('sound-clash:touch', this.touchHandler);
    window.addEventListener('sound-clash:restart', this.restartHandler);
    document.addEventListener('visibilitychange', this.visibilityHandler);
    this.resetMatch();
  }

  private resetMatch() {
    this.seed = Date.now() >>> 0;
    this.state = createMatchState(this.seed);
    this.accumulator = 0;
    this.publishElapsed = 0;
    this.sparks = [];
    sparkSeed = 0x9e3779b9;
    this.inputBuffer.clear();
    this.inputLog = [];
    this.playerComboLabel?.setVisible(false);
    this.rivalComboLabel?.setVisible(false);
    this.publish();
  }

  /** Deterministic input log for a future replay/network layer. */
  getReplay(): { seed: number; frames: InputFrame[] } {
    return { seed: this.seed, frames: this.inputLog.map(frame => ({ ...frame })) };
  }

  private drawArena() {
    const g = this.background;
    g.clear();
    g.fillGradientStyle(0x243d3d, 0x243d3d, 0x49665a, 0x49665a, 1);
    g.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    // Evening sky and far-off city rooftops.
    g.fillStyle(0xdda969, 0.92); g.fillCircle(1010, 160, 82);
    g.fillStyle(0xf0c578, 0.25); g.fillCircle(1010, 160, 112);
    g.fillStyle(0x253b3c, 1);
    const skyline = [[0, 298, 142, 278], [120, 337, 170, 231], [265, 281, 175, 289], [422, 332, 156, 238], [570, 293, 160, 277], [729, 342, 148, 228], [870, 288, 176, 282], [1044, 332, 140, 238], [1170, 300, 110, 270]];
    skyline.forEach(([x, y, w, h], i) => {
      g.fillStyle(i % 2 ? 0x2b4542 : 0x314943, 1);
      g.fillRect(x, y, w, h);
      g.fillStyle(0xeab969, 0.47);
      for (let wx = x + 17; wx < x + w - 10; wx += 31) {
        for (let wy = y + 25; wy < y + h - 18; wy += 38) {
          if ((wx + wy + i) % 3 !== 0) g.fillRect(wx, wy, 8, 12);
        }
      }
    });
    // Sound-system tower, hand-painted geometric speaker stacks.
    this.drawSpeaker(g, 82, 268, 122, 306, 0x1a3036, 0xd95f3b);
    this.drawSpeaker(g, 1075, 260, 126, 314, 0x1a3036, 0xe1b747);
    // String lights across the block party.
    g.lineStyle(3, 0x152b31, 0.65); g.beginPath(); g.moveTo(0, 166); g.lineTo(1280, 205); g.strokePath();
    for (let i = 0; i < 14; i++) {
      const x = 25 + i * 95;
      const y = 167 + (x / 1280) * 39;
      g.lineStyle(1, 0x192f35, 0.9); g.lineBetween(x, y, x, y + 13);
      g.fillStyle(i % 3 === 0 ? 0xedcb74 : 0xf0e2b0, 0.9); g.fillCircle(x, y + 20, 5);
    }
    // Audience silhouettes and stage platform.
    g.fillStyle(0x172d32, 0.95);
    for (let i = 0; i < 28; i++) {
      const x = (i * 53 + 13) % 1280;
      const y = 478 + (i % 3) * 14;
      g.fillCircle(x, y, 17 + (i % 3) * 2);
      g.fillRoundedRect(x - 22, y + 8, 44, 73, 13);
      if (i % 4 === 0) { g.lineStyle(6, 0x172d32); g.lineBetween(x - 7, y + 17, x - 19, y - 25); }
    }
    g.fillStyle(0x304b46); g.fillRect(0, 538, GAME_WIDTH, 182);
    g.fillStyle(0x506153); g.fillRect(0, 565, GAME_WIDTH, 155);
    g.fillStyle(0x213b3c); g.fillRect(0, FLOOR, GAME_WIDTH, GAME_HEIGHT - FLOOR);
    g.lineStyle(3, 0xf1ca67, 0.6); g.lineBetween(0, FLOOR, GAME_WIDTH, FLOOR);
    // Scuffed dance-floor boards.
    g.lineStyle(2, 0x56705d, 0.4);
    for (let x = 0; x <= GAME_WIDTH; x += 128) g.lineBetween(x, FLOOR + 5, x - 20, GAME_HEIGHT);
    g.fillStyle(0x183035, 0.54); g.fillRect(0, 665, GAME_WIDTH, 55);
  }

  private drawSpeaker(g: Phaser.GameObjects.Graphics, x: number, y: number, w: number, h: number, body: number, trim: number) {
    g.fillStyle(0x152b30, 0.6); g.fillRoundedRect(x - 9, y + 8, w + 18, h, 8);
    g.fillStyle(body, 1); g.fillRoundedRect(x, y, w, h, 6);
    g.lineStyle(5, trim, 0.9); g.strokeRoundedRect(x + 7, y + 7, w - 14, h - 14, 4);
    for (let i = 0; i < 3; i++) {
      const cy = y + 58 + i * 78;
      g.fillStyle(0x101f25, 1); g.fillCircle(x + w / 2, cy, 28);
      g.lineStyle(4, trim, 0.65); g.strokeCircle(x + w / 2, cy, 21);
      g.fillStyle(0x52645a, 1); g.fillCircle(x + w / 2, cy, 7);
    }
  }

  update(_time: number, delta: number) {
    if (!this.graphics || !this.state) return;
    const dt = Math.min(delta / 1000, 0.25);

    this.sampleDevices();
    this.accumulator += dt;

    let steps = 0;
    while (this.accumulator >= FIXED_TIMESTEP) {
      if (steps >= MAX_STEPS_PER_FRAME) {
        this.accumulator = 0;
        break;
      }
      this.tick();
      this.accumulator -= FIXED_TIMESTEP;
      steps += 1;
    }

    // Publish state to UI occasionally
    this.publishElapsed += dt;
    if (this.publishElapsed > 0.12) {
      this.publishElapsed = 0;
      this.publish();
    }

    this.drawFighters();
    this.updateSparks(dt);
  }

  /** Read devices once per rendered frame, never once per simulation tick. */
  private sampleDevices() {
    // Two keys can map to one action (A/Left): any key still down keeps it held.
    const held = new Map<DeviceAction, boolean>();
    for (const [key, action] of HELD_KEYS) {
      const phaserKey = this.keys[key];
      if (!phaserKey) continue;
      if (phaserKey.isDown) held.set(action, true);
      else if (!held.has(action)) held.set(action, false);
    }
    for (const [action, pressed] of held) this.inputBuffer.setHeld(action, pressed);
    for (const [key, action] of PRESS_KEYS) {
      const phaserKey = this.keys[key];
      if (phaserKey && Phaser.Input.Keyboard.JustDown(phaserKey)) this.inputBuffer.press(action);
    }
  }

  private tick() {
    const playerInput = this.inputBuffer.sample();
    this.inputLog.push({ player: { ...playerInput }, rival: { ...NEUTRAL_INPUT } });
    if (this.inputLog.length > 60 * 60 * 3) this.inputLog.shift();

    const previousStatus = this.state.status;
    this.state = simulateTick(this.state, playerInput, NEUTRAL_INPUT);

    if (previousStatus !== this.state.status) {
      this.publish();
      if (this.state.status === 'ko-announcement' && this.state.ko) {
        for (const id of ['player', 'rival'] as const) {
          const fighter = this.state[id];
          if (fighter.health > 0) continue;
          const start = this.state.ko[id];
          const fall = getKnockdownPose(
            this.state.ko.ticks,
            IMPACT_FREEZE_TICKS,
            KNOCKDOWN_TICKS,
            start.direction,
            start.heavy,
          );
          this.burst(start.x + fall.x, FLOOR, 0xc9b38c, 24);
        }
        this.cameras.main.shake(130, 0.007);
        this.soundPing('hit');
      }
    }
    this.handleSimulationEvents();
  }

  private handleSimulationEvents() {
    for (const event of this.state.events) {
      switch (event.type) {
        case 'sound':
          this.soundPing(event.kind);
          break;
        case 'spark':
          this.burst(event.x, event.y, event.color, event.count);
          break;
        case 'shake':
          this.cameras.main.shake(event.intensity, event.speed);
          break;
        default:
          break;
      }
    }
  }

  private publish() {
    this.onSnapshot({
      playerHealth: Math.ceil(this.state?.player?.health ?? 100),
      rivalHealth: Math.ceil(this.state?.rival?.health ?? 100),
      timeLeft: this.state?.timeLeft ?? 90,
      status: this.state?.status ?? 'pre-round',
      winner: this.state?.winner ?? null,
      matchWinner: this.state?.matchWinner ?? null,
      roundWinner: this.state?.roundWinner ?? null,
      roundEndReason: this.state?.roundEndReason ?? null,
      threePieceKO: this.state?.threePieceKO ?? false,
      round: this.state?.round ?? 1,
      playerWins: this.state?.playerWins ?? 0,
      rivalWins: this.state?.rivalWins ?? 0,
    });
  }

  private soundPing(kind: 'hit' | 'block' | 'jump' | 'round' | 'ko') {
    window.dispatchEvent(new CustomEvent('sound-clash:sound', { detail: kind }));
  }

  private burst(x: number, y: number, color: number, count: number) {
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + nextSparkRandom() * 0.25;
      const speed = 60 + nextSparkRandom() * 250;
      this.sparks.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 0.18 + nextSparkRandom() * 0.28,
        color,
      });
    }
  }

  private updateSparks(dt: number) {
    const g = this.graphics;
    for (let i = this.sparks.length - 1; i >= 0; i--) {
      const s = this.sparks[i];
      s.x += s.vx * dt; s.y += s.vy * dt; s.vy += 430 * dt; s.life -= dt;
      if (s.life <= 0) this.sparks.splice(i, 1);
      else { g.fillStyle(s.color, Math.min(1, s.life * 4)); g.fillCircle(s.x, s.y, 3 + s.life * 10); }
    }
  }

  private drawFighters() {
    const g = this.graphics;
    g.clear();
    this.drawFighter(g, this.state.player);
    this.drawFighter(g, this.state.rival);
    this.updateComboLabel(this.state.player, this.playerComboLabel);
    this.updateComboLabel(this.state.rival, this.rivalComboLabel);
  }

  private updateComboLabel(f: FighterState, label: Phaser.GameObjects.Text) {
    if (this.state.ko || !f.comboFeedback || f.comboFeedbackTime <= 0) {
      label.setVisible(false);
      return;
    }
    const pose = getFighterPose(f);
    label.setText(f.comboFeedback);
    label.setPosition(f.x, pose.headY - 39);
    label.setAlpha(Math.min(1, f.comboFeedbackTime * 3));
    label.setVisible(true);
  }

  private drawFighter(g: Phaser.GameObjects.Graphics, f: FighterState) {
    const id = f === this.state.player ? 'player' : 'rival';
    const reaction = getHitReactionPose(f.hitReaction);
    const knockedDown =
      !!f.knockdown ||
      (f.health <= 0 && this.state.ko !== null && this.state.status !== 'impact-freeze');
    // The simulation owns the trajectory; the renderer only asks it for the
    // rotation and the ground-impact ring so both stay in lockstep.
    const isKnockdown = !!f.knockdown;
    const downTicks = isKnockdown ? f.knockdown!.ticks : (this.state.ko?.ticks ?? 0);
    const freezeTicks = isKnockdown ? 0 : IMPACT_FREEZE_TICKS;
    const direction = f.knockdown?.direction ?? this.state.ko?.[id]?.direction ?? -f.facing;
    const heavy =
      f.knockdown?.heavy ?? this.state.ko?.[id]?.heavy ?? f.hitReaction?.kind !== 'light';
    const fall = getKnockdownPose(downTicks, freezeTicks, KNOCKDOWN_TICKS, direction, heavy);

    if (knockedDown) {
      g.fillStyle(0x14292c, 0.35);
      g.fillEllipse(f.x, FLOOR + 9, 89 + 90 * fall.progress, 20);
      if (fall.impact > 0) {
        g.lineStyle(4 * fall.impact, 0xe4d2a2, fall.impact * 0.65);
        g.strokeEllipse(f.x, FLOOR + 5, 160 + (1 - fall.impact) * 110, 20 + (1 - fall.impact) * 20);
      }
    }
    g.save();
    if (knockedDown) {
      // Position already includes the launch: rotate in place, never re-add it.
      g.translateCanvas(f.x, FLOOR + 2 + f.y);
      g.rotateCanvas(fall.angle);
      g.translateCanvas(-f.x, -(FLOOR + 2 + f.y));
    }
    const renderFighter = knockedDown
      ? { ...f, vx: 0, anim: 0, blocking: false, action: 'idle' as const }
      : f;
    const { baseY, moving, hipY, shoulderY, headY } = getFighterPose(renderFighter);
    const centerX = f.x;
    const action = renderFighter.action;
    const swing = isAttackAction(action);
    const facing = f.facing;
    const strikeFacing = swing ? f.attackFacing : facing;
    // Ground shadow and planted shoes.
    if (!knockedDown) { g.fillStyle(0x14292c, 0.35); g.fillEllipse(centerX, FLOOR + 9, f.grounded ? 89 : 60, 20); }
    const legKick = moving ? Math.sin(f.anim) * 13 : f.action === 'hit' && !knockedDown ? reaction.stumble : 0;
    // Back leg and sneaker.
    g.lineStyle(17, f.color, 1); g.lineBetween(centerX - 7, hipY, centerX - 19 + legKick, baseY - 14);
    g.lineStyle(13, f.skin, 1); g.lineBetween(centerX - 19 + legKick, baseY - 19, centerX - 32 + legKick, baseY - 8);
    g.fillStyle(0xe7dfc9, 1); g.fillRoundedRect(centerX - 48 + legKick, baseY - 13, 34, 13, 5);
    // Forward leg.
    g.lineStyle(19, f.color, 1); g.lineBetween(centerX + 7, hipY, centerX + 18 - legKick, baseY - 16);
    g.lineStyle(14, f.skin, 1); g.lineBetween(centerX + 18 - legKick, baseY - 20, centerX + 28 - legKick, baseY - 9);
    g.fillStyle(f.accent, 1); g.fillRoundedRect(centerX + 14 - legKick, baseY - 14, 36, 14, 5);
    // Deform only the drawn upper body; the simulation keeps its original hurtboxes.
    g.save();
    if (!knockedDown && f.action === 'hit') {
      g.translateCanvas(centerX + reaction.shoulderX + reaction.shakeX, hipY);
      g.scaleCanvas(1 + reaction.compression * 0.25, 1 - reaction.compression);
      g.translateCanvas(-centerX, -hipY);
    }
    // Torso silhouette, bandana sash, jacket.
    g.fillStyle(f.color, 1); g.fillRoundedRect(centerX + TORSO_LEFT, shoulderY, TORSO_RIGHT - TORSO_LEFT, TORSO_HEIGHT + (renderFighter.blocking ? 19 : 0), 13);
    g.fillStyle(f.accent, 1); g.fillRect(centerX + TORSO_LEFT, shoulderY + 43, TORSO_RIGHT - TORSO_LEFT, 9);
    g.fillStyle(f.skin, 1); g.fillRect(centerX - 9, shoulderY - 7, 18, 19);
    // Far arm.
    g.lineStyle(16, f.skin, 1); g.lineBetween(centerX - facing * 19, shoulderY + 10, centerX - facing * 37, shoulderY + 34);
    g.fillStyle(f.accent, 1); g.fillCircle(centerX - facing * 38, shoulderY + 36, 10);
    // Near arm with a clear extended punch, using the exact collision pose.
    const strike = swing ? getStrikePose(action, centerX, shoulderY, strikeFacing, f.attackStage, f.attackElapsed) : null;
    const armX = strike?.x ?? centerX + facing * 28;
    const armY = strike?.y ?? shoulderY + 29 + (renderFighter.blocking ? -9 : 0);
    g.lineStyle(swing && action !== 'light' ? 21 : 17, f.skin, 1);
    if (action === 'light') {
      // A bent guard opens into a straight arm; the fist uses the collision pose above.
      const shoulderX = centerX + strikeFacing * 18;
      const shoulderArmY = shoulderY + 9;
      const peak = getStrikePose('light', centerX, shoulderY, strikeFacing, f.attackStage);
      const extension = Math.max(0, Math.min(1, (armY - (shoulderY + 29)) / (peak.y - (shoulderY + 29))));
      const elbowX = (shoulderX + armX) / 2 - strikeFacing * 8 * (1 - extension);
      const elbowY = (shoulderArmY + armY) / 2 + 17 * (1 - extension);
      g.lineBetween(shoulderX, shoulderArmY, elbowX, elbowY);
      g.fillStyle(f.skin, 1); g.fillCircle(elbowX, elbowY, 8.5);
      g.lineBetween(elbowX, elbowY, armX, armY);
    } else {
      g.lineBetween(centerX + strikeFacing * 18, shoulderY + 9, armX, armY);
    }
    g.fillStyle(f.accent, 1);
    if (action === 'upper') {
      // An open palm and four extended fingers sweep upward, rather than a fist uppercut.
      const elapsed = Math.min(1, f.attackElapsed / 0.24);
      g.save();
      g.translateCanvas(armX, armY);
      g.rotateCanvas(strikeFacing * (-0.8 + elapsed * 1.3));
      g.fillStyle(f.skin, 1); g.fillRoundedRect(-10, -7, 20, 16, 5);
      g.lineStyle(4, f.skin, 1);
      for (let finger = 0; finger < 4; finger++) g.lineBetween(-7 + finger * 5, -5, -8 + finger * 5, -19 - (finger === 1 || finger === 2 ? 3 : 0));
      g.lineBetween(8, 3, 16, -3);
      g.fillStyle(f.accent, 1); g.fillRect(-9, 7, 18, 5);
      g.restore();
    } else g.fillCircle(armX, armY, strike?.radius ?? 11);
    if (renderFighter.blocking) {
      g.lineStyle(8, f.accent, .88); g.lineBetween(centerX + facing * 26, shoulderY + 3, centerX + facing * 52, shoulderY - 22);
      g.lineBetween(centerX + facing * 52, shoulderY - 22, centerX + facing * 53, shoulderY + 10);
    }
    g.fillStyle(f.accent, .9); g.fillCircle(centerX - facing * 8, shoulderY + 24, 4);
    // Keep the body flash inside the torso's compression transform, outside head recoil.
    if (!knockedDown && f.action === 'hit' && f.hitReaction?.region === 'body') {
      g.fillStyle(0xffe4a8, 0.65);
      g.fillEllipse(centerX, shoulderY + 32, 44, 38);
    }
    g.save();
    if (!knockedDown && f.action === 'hit') {
      g.translateCanvas(centerX + reaction.headX, headY);
      g.rotateCanvas(reaction.headTilt);
      g.translateCanvas(-centerX, -headY);
    }
    // Head, original cap silhouette, face and hair.
    g.fillStyle(f.skin, 1); g.fillCircle(centerX + facing * HEAD_OFFSET, headY, HEAD_RADIUS);
    g.fillStyle(0x182d32, 1); g.fillRoundedRect(centerX - 22, headY - 20, 49, 12, 5);
    g.fillStyle(f.accent, 1); g.fillRoundedRect(centerX + facing * 7 - 12, headY - 25, 36, 9, 4);
    g.fillStyle(0x1b2729, 1); g.fillCircle(centerX + facing * 11, headY - 1, 2.4);
    g.lineStyle(2, 0x553a30, 1); g.lineBetween(centerX + facing * 7, headY + 10, centerX + facing * 15, headY + 10);

    if (swing) {
      g.lineStyle(3, f.accent, .32); g.strokeCircle(armX, armY, action !== 'light' ? 22 : 17);
    }
    if (!knockedDown && f.action === 'hit' && f.hitReaction?.region === 'head') {
      g.fillStyle(0xffe4a8, 0.7); g.fillCircle(centerX - facing * 4, headY - 2, 25);
    }
    // Tiny artist-painted identifier above the cap.
    g.fillStyle(f.accent, 1); g.fillTriangle(centerX - 7, headY - 37, centerX + 7, headY - 37, centerX, headY - 47);
    g.restore(); // Head recoil.
    g.restore(); // Upper-body compression.
    g.restore(); // Knockdown transform.
  }

  shutdown() {
    window.removeEventListener('sound-clash:touch', this.touchHandler);
    window.removeEventListener('sound-clash:restart', this.restartHandler);
    document.removeEventListener('visibilitychange', this.visibilityHandler);
    this.inputBuffer.clear();
  }
}
