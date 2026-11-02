import Phaser from 'phaser';
import { getHitReactionPose, getKnockdownPose, type HitReaction } from './visualReactions';
import { GAME_HEIGHT, GAME_WIDTH, type MatchSnapshot, type TouchAction } from './types';
import { getStrikePose, isAttackAction } from './combatRules';
import { type GameState, type FighterState, type FighterInput, FIXED_TIMESTEP } from './simulation/types';
import { simulateTick, IMPACT_FREEZE_TICKS, KNOCKDOWN_TICKS, FLOOR, TORSO_LEFT, TORSO_RIGHT, TORSO_HEIGHT, HEAD_OFFSET, HEAD_RADIUS } from './simulation/SimulationEngine';

export class GameScene extends Phaser.Scene {
  private onSnapshot: (snapshot: MatchSnapshot) => void;
  private state!: GameState;
  private accumulator = 0;
  private reactions: Record<'player' | 'rival', HitReaction | null> = { player: null, rival: null };
  private graphics!: Phaser.GameObjects.Graphics;
  private background!: Phaser.GameObjects.Graphics;
  private playerComboLabel!: Phaser.GameObjects.Text;
  private rivalComboLabel!: Phaser.GameObjects.Text;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private touch = new Set<TouchAction>();
  private publishElapsed = 0;
  private shakeTimer = 0;
  private sparks: { x: number; y: number; vx: number; vy: number; life: number; color: number }[] = [];
  private touchHandler = (event: Event) => {
    const detail = (event as CustomEvent<{ action: TouchAction; pressed: boolean }>).detail;
    if (detail.pressed) this.touch.add(detail.action);
    else this.touch.delete(detail.action);
  };
  private restartHandler = () => this.resetMatch();

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
      Phaser.Input.Keyboard.KeyCodes.LEFT, Phaser.Input.Keyboard.KeyCodes.RIGHT,
      Phaser.Input.Keyboard.KeyCodes.UP, Phaser.Input.Keyboard.KeyCodes.DOWN,
      Phaser.Input.Keyboard.KeyCodes.SPACE,
    ]);
    window.addEventListener('sound-clash:touch', this.touchHandler);
    window.addEventListener('sound-clash:restart', this.restartHandler);
    this.resetMatch();
  }

  private makeFighter(x: number, color: number, accent: number, skin: number, name: string, facing: number): FighterState {
    return {
      x, y: 0, health: 100, facing, color, accent, skin, name, vx: 0, vy: 0,
      grounded: true, blocking: false, action: 'idle', actionTime: 0, cooldown: 0,
      stun: 0, aiWait: 0.5, anim: 0,
      attackElapsed: 0, hitRegistered: false, attackFacing: facing, attackStage: 'jab1',
      comboStep: 0, comboWindow: 0, bufferedAttack: null, comboHits: 0,
      comboFeedback: '', comboFeedbackTime: 0, walkAroundCooldown: 0,
      threePieceStep: 0, threePieceWindow: 0, knockdown: null,
    };
  }

  private resetMatch() {
    this.state = {
      player: this.makeFighter(378, 0x247c72, 0xf0c64c, 0x9d6545, 'SIDEWINDER', 1),
      rival: this.makeFighter(902, 0xd75f3e, 0xedd9b5, 0x754936, 'BASSLINE', -1),
      timeLeft: 90,
      elapsed: 0,
      status: 'pre-round',
      winner: null,
      matchWinner: null,
      roundWinner: null,
      roundEndReason: null,
      threePieceKO: false,
      ko: null,
      round: 1,
      playerWins: 0,
      rivalWins: 0,
      transitionTimer: 2,
      rngState: Date.now() >>> 0, // Unsigned 32-bit int seed
      events: []
    };
    this.accumulator = 0;
    this.reactions = { player: null, rival: null };
    this.publishElapsed = 0;
    this.sparks = [];
    this.shakeTimer = 0;
    this.touch.clear();
    this.touchFrame.clear();
    this.playerComboLabel?.setVisible(false);
    this.rivalComboLabel?.setVisible(false);
    this.publish();
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
    const dt = Math.min(delta / 1000, 0.25); // Cap to 250ms to prevent spiral of death

    this.accumulator += dt;

    while (this.accumulator >= FIXED_TIMESTEP) {
      this.tick();
      this.accumulator -= FIXED_TIMESTEP;
    }

    if (this.shakeTimer > 0) {
      this.shakeTimer -= dt;
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

  private tick() {
    const keyDown = (key: string) => this.keys[key]?.isDown ?? false;

    const playerInput: FighterInput = {
      left: keyDown('left') || keyDown('arrowLeft') || this.touch.has('left'),
      right: keyDown('right') || keyDown('arrowRight') || this.touch.has('right'),
      jump: Phaser.Input.Keyboard.JustDown(this.keys.up) || Phaser.Input.Keyboard.JustDown(this.keys.arrowUp) || this.touchJust('jump'),
      block: keyDown('down') || keyDown('arrowDown') || this.touch.has('block'),
      light: Phaser.Input.Keyboard.JustDown(this.keys.light) || this.touchJust('light'),
      head: Phaser.Input.Keyboard.JustDown(this.keys.heavy) || this.touchJust('heavy'),
      heavy: Phaser.Input.Keyboard.JustDown(this.keys.body) || this.touchJust('body'),
      upper: Phaser.Input.Keyboard.JustDown(this.keys.upper) || this.touchJust('upper'),
    };

    // In Phase 1, CPU is processed inline in the pure function, so we pass empty input for rival.
    const rivalInput: FighterInput = { left: false, right: false, jump: false, block: false, light: false, heavy: false };

    const previousStatus = this.state.status;
    // Reaction ages advance with simulation ticks and hold the impact pose during hitstop.
    if (previousStatus === 'playing') {
      for (const reaction of Object.values(this.reactions)) if (reaction) reaction.age++;
    }
    this.state = simulateTick(this.state, playerInput, rivalInput);
    if (previousStatus !== this.state.status) {
      this.publish();
      if (this.state.status === 'pre-round') this.reactions = { player: null, rival: null };
      if (this.state.status === 'ko-announcement') {
        for (const id of ['player', 'rival'] as const) {
          const fighter = this.state[id];
          if (fighter.health > 0) continue;
          const fall = getKnockdownPose(this.state.ko!.ticks, IMPACT_FREEZE_TICKS, KNOCKDOWN_TICKS, -fighter.facing, this.reactions[id]?.kind !== 'light');
          this.burst(fighter.x + fall.x - fighter.facing * 65, FLOOR, 0xc9b38c, 24);
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
        case 'hit-reaction':
          this.reactions[event.fighter] = { kind: event.kind, region: event.region, direction: event.direction, age: 0 };
          break;
        case 'sound':
          this.soundPing(event.kind);
          break;
        case 'spark':
          this.burst(event.x, event.y, event.color, event.count);
          break;
        case 'shake':
          this.shakeTimer = event.duration;
          this.cameras.main.shake(event.intensity, event.speed);
          break;
        case 'attack-stage':
          window.dispatchEvent(new CustomEvent('sound-clash:attack-stage', {
            detail: { fighter: event.fighter, kind: event.kind, stage: event.stage },
          }));
          break;
      }
    }
  }

  private touchFrame = new Set<TouchAction>();
  private touchJust(action: TouchAction) {
    const now = this.touch.has(action);
    const was = this.touchFrame.has(action);
    if (now && !was) { this.touchFrame.add(action); return true; }
    if (!now) this.touchFrame.delete(action);
    return false;
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
      const angle = (Math.PI * 2 * i) / count + Math.random() * 0.25;
      const speed = 60 + Math.random() * 250;
      this.sparks.push({ x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: .18 + Math.random() * .28, color });
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
    const pose = this.getFighterPose(f);
    label.setText(f.comboFeedback);
    label.setPosition(f.x, pose.headY - 39);
    label.setAlpha(Math.min(1, f.comboFeedbackTime * 3));
    label.setVisible(true);
  }

  private getFighterPose(f: FighterState) {
    const baseY = FLOOR + 2 + f.y;
    const moving = Math.abs(f.vx) > 8 && f.grounded;
    const bob = f.grounded ? Math.sin(f.anim) * (moving ? 5 : 2) : 0;
    const crouch = f.blocking ? 19 : 0;
    const hipY = baseY - 68 - crouch + bob;
    const shoulderY = hipY - 42;
    return { baseY, moving, bob, crouch, hipY, shoulderY, headY: shoulderY - 30 };
  }

  private drawFighter(g: Phaser.GameObjects.Graphics, f: FighterState) {
    const id = f === this.state.player ? 'player' : 'rival';
    const hit = this.reactions[id];
    const reaction = getHitReactionPose(hit);
    const knockedDown = !!f.knockdown || (f.health <= 0 && this.state.ko !== null && this.state.status !== 'impact-freeze');
    const downTicks = f.knockdown ? f.knockdown.ticks + IMPACT_FREEZE_TICKS : this.state.ko?.ticks ?? 0;
    const fall = getKnockdownPose(downTicks, IMPACT_FREEZE_TICKS, KNOCKDOWN_TICKS, f.knockdown?.direction ?? -f.facing, hit?.kind !== 'light');
    if (knockedDown) {
      g.fillStyle(0x14292c, 0.35);
      g.fillEllipse(f.x + fall.x - f.facing * 65 * fall.progress, FLOOR + 9, 89 + 90 * fall.progress, 20);
      if (fall.impact > 0) {
        g.lineStyle(4 * fall.impact, 0xe4d2a2, fall.impact * 0.65);
        g.strokeEllipse(f.x + fall.x - f.facing * 65, FLOOR + 5, 160 + (1 - fall.impact) * 110, 20 + (1 - fall.impact) * 20);
      }
    }
    g.save();
    if (knockedDown) {
      g.translateCanvas(f.x + fall.x, FLOOR + 2 + f.y + fall.y);
      g.rotateCanvas(fall.angle);
      g.translateCanvas(-f.x, -(FLOOR + 2 + f.y));
    }
    const renderFighter = knockedDown ? { ...f, vx: 0, anim: 0, blocking: false, action: 'idle' as const } : f;
    const { baseY, moving, bob, crouch, hipY, shoulderY, headY } = this.getFighterPose(renderFighter);
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
    g.fillStyle(f.color, 1); g.fillRoundedRect(centerX + TORSO_LEFT, shoulderY, TORSO_RIGHT - TORSO_LEFT, TORSO_HEIGHT + crouch, 13);
    g.fillStyle(f.accent, 1); g.fillRect(centerX + TORSO_LEFT, shoulderY + 43, TORSO_RIGHT - TORSO_LEFT, 9);
    g.fillStyle(f.skin, 1); g.fillRect(centerX - 9, shoulderY - 7, 18, 19);
    // Far arm.
    g.lineStyle(16, f.skin, 1); g.lineBetween(centerX - facing * 19, shoulderY + 10, centerX - facing * 37, shoulderY + 34);
    g.fillStyle(f.accent, 1); g.fillCircle(centerX - facing * 38, shoulderY + 36, 10);
    // Near arm with a clear extended punch.
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
    if (!knockedDown && f.action === 'hit' && hit?.region === 'body') {
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
    if (!knockedDown && f.action === 'hit' && hit?.region === 'head') {
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
    this.touch.clear();
    this.touchFrame.clear();
  }
}
