import Phaser from 'phaser';
import { GAME_HEIGHT, GAME_WIDTH, type MatchSnapshot, type TouchAction } from './types';

type Fighter = {
  x: number;
  y: number;
  health: number;
  facing: number;
  color: number;
  accent: number;
  skin: number;
  name: string;
  vx: number;
  vy: number;
  grounded: boolean;
  blocking: boolean;
  action: 'idle' | 'light' | 'heavy' | 'hit' | 'block';
  actionTime: number;
  cooldown: number;
  stun: number;
  aiWait: number;
  anim: number;
  attackElapsed: number;
  hitRegistered: boolean;
  walkAroundCooldown: number;
};

const FLOOR = 574;
const LEFT_BOUND = 92;
const RIGHT_BOUND = 1188;
const MIN_FIGHTER_GAP = 76;
const RIVAL_ENGAGE_RANGE = 108;
const AIR_PASS_CLEARANCE = 52;
const WALK_AROUND_RANGE = MIN_FIGHTER_GAP + 8;
const WALK_AROUND_JUMP = -570;

export class GameScene extends Phaser.Scene {
  private onSnapshot: (snapshot: MatchSnapshot) => void;
  private player!: Fighter;
  private rival!: Fighter;
  private graphics!: Phaser.GameObjects.Graphics;
  private background!: Phaser.GameObjects.Graphics;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private touch = new Set<TouchAction>();
  private elapsed = 0;
  private status: MatchSnapshot['status'] = 'playing';
  private winner: MatchSnapshot['winner'] = null;
  private publishElapsed = 0;
  private timeLeft = 90;
  private shakeTimer = 0;
  private rivalInRange = false;
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

  private makeFighter(x: number, color: number, accent: number, skin: number, name: string, facing: number): Fighter {
    return {
      x, y: 0, health: 100, facing, color, accent, skin, name, vx: 0, vy: 0,
      grounded: true, blocking: false, action: 'idle', actionTime: 0, cooldown: 0,
      stun: 0, aiWait: 0.5, anim: Math.random() * 3,
      attackElapsed: 0, hitRegistered: false, walkAroundCooldown: 0,
    };
  }

  private resetMatch() {
    this.player = this.makeFighter(378, 0x247c72, 0xf0c64c, 0x9d6545, 'SIDEWINDER', 1);
    this.rival = this.makeFighter(902, 0xd75f3e, 0xedd9b5, 0x754936, 'BASSLINE', -1);
    this.elapsed = 0;
    this.publishElapsed = 0;
    this.timeLeft = 90;
    this.status = 'playing';
    this.winner = null;
    this.rivalInRange = false;
    this.sparks = [];
    this.shakeTimer = 0;
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
    if (!this.graphics || !this.player || !this.rival) return;
    const dt = Math.min(delta / 1000, 0.04);
    if (this.status === 'playing') {
      this.elapsed += dt;
      this.timeLeft = Math.max(0, 90 - Math.floor(this.elapsed));
      this.updatePlayer(dt);
      this.updateRival(dt);
      this.separateFighters();
      this.faceOpponents();
      this.updateFighter(this.player, dt);
      this.updateFighter(this.rival, dt);
      this.resolveCombat(this.player, this.rival);
      if (this.player.health <= 0 || this.rival.health <= 0 || this.timeLeft <= 0) this.finishMatch();
      this.publishElapsed += dt;
      if (this.publishElapsed > 0.12) { this.publishElapsed = 0; this.publish(); }
    } else {
      this.player.anim += dt;
      this.rival.anim += dt;
    }
    this.drawFighters();
    this.updateSparks(dt);
  }

  private updatePlayer(dt: number) {
    const p = this.player;
    const keyDown = (key: string) => this.keys[key]?.isDown ?? false;
    const left = keyDown('left') || keyDown('arrowLeft') || this.touch.has('left');
    const right = keyDown('right') || keyDown('arrowRight') || this.touch.has('right');
    const up = keyDown('up') || keyDown('arrowUp') || this.touch.has('jump');
    const canAct = p.stun <= 0 && this.status === 'playing';
    p.blocking = canAct && (keyDown('down') || keyDown('arrowDown') || this.touch.has('block')) && p.grounded;
    if (canAct) {
      p.vx = ((right ? 1 : 0) - (left ? 1 : 0)) * 270;
      if (p.blocking) p.vx *= 0.38;
      if (Phaser.Input.Keyboard.JustDown(this.keys.up) || Phaser.Input.Keyboard.JustDown(this.keys.arrowUp) || this.touchJust('jump')) {
        if (p.grounded) { p.vy = -665; p.grounded = false; this.soundPing('jump'); }
      }
      if (Phaser.Input.Keyboard.JustDown(this.keys.light) || this.touchJust('light')) this.attack(p, 'light');
      if (Phaser.Input.Keyboard.JustDown(this.keys.heavy) || this.touchJust('heavy')) this.attack(p, 'heavy');
      this.tryWalkAround(p);
    } else if (this.status !== 'playing') p.vx = 0;
    this.moveFighter(p, dt);
  }

  private touchFrame = new Set<TouchAction>();
  private touchJust(action: TouchAction) {
    const now = this.touch.has(action);
    const was = this.touchFrame.has(action);
    if (now && !was) { this.touchFrame.add(action); return true; }
    if (!now) this.touchFrame.delete(action);
    return false;
  }

  private updateRival(dt: number) {
    const e = this.rival;
    const distance = this.player.x - e.x;
    const distanceToPlayer = Math.abs(distance);
    const inAttackRange = distanceToPlayer <= RIVAL_ENGAGE_RANGE;
    e.aiWait = Math.max(0, e.aiWait - dt);
    e.blocking = e.action === 'block' && e.actionTime > 0 && e.stun <= 0 && e.grounded;
    if (inAttackRange && !this.rivalInRange) {
      this.rivalInRange = true;
      e.aiWait = Math.max(e.aiWait, 0.25);
    } else if (!inAttackRange) {
      this.rivalInRange = false;
    }

    if (e.stun <= 0 && this.status === 'playing') {
      if (!inAttackRange) {
        e.blocking = false;
        e.vx = Math.sign(distance) * 145;
      } else {
        e.vx = 0;
        if (!e.blocking && e.aiWait <= 0 && e.cooldown <= 0) {
          const roll = Math.random();
          if (roll < 0.22 && this.player.action === 'heavy') {
            e.blocking = true; e.action = 'block'; e.actionTime = .48;
          } else this.attack(e, roll > 0.72 ? 'heavy' : 'light');
          e.aiWait = 0.55 + Math.random() * 0.45;
        }
      }
      if (distanceToPlayer > 310 && e.grounded && Math.random() < 0.008) e.vy = -590;
    } else if (this.status !== 'playing') e.vx = 0;
    this.moveFighter(e, dt);
  }

  private updateFighter(f: Fighter, dt: number) {
    f.anim += dt * (Math.abs(f.vx) > 0 ? 8 : 2.2);
    f.cooldown = Math.max(0, f.cooldown - dt);
    f.stun = Math.max(0, f.stun - dt);
    f.walkAroundCooldown = Math.max(0, f.walkAroundCooldown - dt);
    f.actionTime = Math.max(0, f.actionTime - dt);
    if (f.action === 'light' || f.action === 'heavy') f.attackElapsed += dt;
    if (f.actionTime === 0 && f.action !== 'idle') f.action = f.blocking ? 'block' : 'idle';
    if (f.stun <= 0 && f.action === 'hit') f.action = 'idle';
  }

  private moveFighter(f: Fighter, dt: number) {
    if (f.stun > 0) f.vx *= Math.exp(-6 * dt);
    f.x = Phaser.Math.Clamp(f.x + f.vx * dt, LEFT_BOUND, RIGHT_BOUND);
    if (!f.grounded) {
      f.vy += 1580 * dt;
      f.y += f.vy * dt;
      if (f.y >= 0) { f.y = 0; f.vy = 0; f.grounded = true; }
    }
  }

  private separateFighters() {
    // A jump or walk-around hop can pass over the other fighter. Once they
    // land, restore the gap on their current sides instead of their old ones.
    if (Math.abs(this.player.y - this.rival.y) > AIR_PASS_CLEARANCE) return;

    const gap = Math.abs(this.rival.x - this.player.x);
    if (gap < MIN_FIGHTER_GAP) {
      const midpoint = Phaser.Math.Clamp(
        (this.player.x + this.rival.x) / 2,
        LEFT_BOUND + MIN_FIGHTER_GAP / 2,
        RIGHT_BOUND - MIN_FIGHTER_GAP / 2,
      );
      const relativeDirection =
        Math.sign(this.rival.x - this.player.x) ||
        -Math.sign(this.player.vx - this.rival.vx) ||
        this.player.facing ||
        1;
      this.player.x = midpoint - relativeDirection * MIN_FIGHTER_GAP / 2;
      this.rival.x = midpoint + relativeDirection * MIN_FIGHTER_GAP / 2;
    }
  }

  private faceOpponents() {
    const direction =
      Math.sign(this.rival.x - this.player.x) ||
      -Math.sign(this.player.vx - this.rival.vx) ||
      this.player.facing ||
      1;
    this.player.facing = direction;
    this.rival.facing = -direction;
  }

  private tryWalkAround(player: Fighter) {
    const directionToRival = Math.sign(this.rival.x - player.x);
    const movingTowardRival = directionToRival !== 0 && Math.sign(player.vx) === directionToRival;
    const isAttacking = player.action === 'light' || player.action === 'heavy';
    if (
      !movingTowardRival ||
      Math.abs(this.rival.x - player.x) > WALK_AROUND_RANGE ||
      !player.grounded ||
      player.blocking ||
      player.stun > 0 ||
      player.walkAroundCooldown > 0 ||
      isAttacking
    ) return;

    // A small automatic vault lets horizontal movement pass the CPU without
    // disabling body collision or changing the existing jump controls.
    player.vy = WALK_AROUND_JUMP;
    player.grounded = false;
    player.walkAroundCooldown = 0.9;
    this.soundPing('jump');
  }

  private attack(attacker: Fighter, kind: 'light' | 'heavy') {
    if (attacker.cooldown > 0 || attacker.stun > 0 || attacker.blocking || this.status !== 'playing') return;
    attacker.action = kind;
    attacker.actionTime = kind === 'light' ? 0.29 : 0.48;
    attacker.cooldown = kind === 'light' ? 0.38 : 0.72;
    attacker.attackElapsed = 0;
    attacker.hitRegistered = false;
  }

  private resolveCombat(a: Fighter, b: Fighter) {
    const fighters = [a, b];
    for (const attacker of fighters) {
      const defender = attacker === a ? b : a;
      if (attacker.action !== 'light' && attacker.action !== 'heavy') continue;
      if (attacker.hitRegistered) continue;
      const isHeavy = attacker.action === 'heavy';
      const activeStart = isHeavy ? 0.16 : 0.08;
      const activeEnd = isHeavy ? 0.34 : 0.21;
      if (attacker.attackElapsed < activeStart || attacker.attackElapsed > activeEnd) continue;
      const directionToOpponent = Math.sign(defender.x - attacker.x);
      if (directionToOpponent !== attacker.facing) continue;
      const reach = isHeavy ? 147 : 112;
      const gap = Math.abs(defender.x - attacker.x);
      if (gap > reach || Math.abs(defender.y - attacker.y) > 106) continue;
      attacker.hitRegistered = true;
      const blocked = defender.blocking && defender.facing === Math.sign(attacker.x - defender.x) && defender.grounded;
      const damage = isHeavy ? (blocked ? 4 : 15) : (blocked ? 2 : 8);
      defender.health = Math.max(0, defender.health - damage);
      defender.stun = blocked ? 0.12 : 0.28;
      defender.action = blocked ? 'block' : 'hit';
      defender.actionTime = blocked ? 0.16 : 0.29;
      defender.vx = Math.sign(defender.x - attacker.x) * (blocked ? 145 : 420);
      this.shakeTimer = blocked ? 0.07 : 0.16;
      this.cameras.main.shake(blocked ? 65 : 110, blocked ? 0.002 : 0.004);
      this.burst((attacker.x + defender.x) / 2, FLOOR - 125 + defender.y, blocked ? 0xf3cf67 : 0xffe7ad, blocked ? 8 : 15);
      this.soundPing(blocked ? 'block' : 'hit');
    }
  }

  private finishMatch() {
    this.status = 'finished';
    if (this.player.health === this.rival.health || (this.timeLeft === 0 && this.player.health === this.rival.health)) this.winner = 'draw';
    else this.winner = this.player.health > this.rival.health ? 'player' : 'rival';
    this.publish();
  }

  private publish() {
    this.onSnapshot({
      playerHealth: Math.ceil(this.player?.health ?? 100),
      rivalHealth: Math.ceil(this.rival?.health ?? 100),
      timeLeft: this.timeLeft,
      status: this.status,
      winner: this.winner,
      round: 1,
    });
  }

  private soundPing(kind: 'hit' | 'block' | 'jump' | 'round') {
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
    this.drawFighter(g, this.player);
    this.drawFighter(g, this.rival);
  }

  private drawFighter(g: Phaser.GameObjects.Graphics, f: Fighter) {
    const baseY = FLOOR + 2 + f.y;
    const moving = Math.abs(f.vx) > 8 && f.grounded;
    const bob = f.grounded ? Math.sin(f.anim) * (moving ? 5 : 2) : 0;
    const crouch = f.blocking ? 19 : 0;
    const centerX = f.x;
    const action = f.action;
    const swing = action === 'light' || action === 'heavy';
    const facing = f.facing;
    const reach = action === 'heavy' ? 83 : 62;
    const swingAmount = swing ? (action === 'heavy' ? 1 : .72) : 0;
    // Ground shadow and planted shoes.
    g.fillStyle(0x14292c, 0.35); g.fillEllipse(centerX, FLOOR + 9, f.grounded ? 89 : 60, 20);
    const hipY = baseY - 68 - crouch + bob;
    const shoulderY = hipY - 42;
    const headY = shoulderY - 30;
    const legKick = moving ? Math.sin(f.anim) * 13 : 0;
    // Back leg and sneaker.
    g.lineStyle(17, f.color, 1); g.lineBetween(centerX - 7, hipY, centerX - 19 + legKick, baseY - 14);
    g.lineStyle(13, f.skin, 1); g.lineBetween(centerX - 19 + legKick, baseY - 19, centerX - 32 + legKick, baseY - 8);
    g.fillStyle(0xe7dfc9, 1); g.fillRoundedRect(centerX - 48 + legKick, baseY - 13, 34, 13, 5);
    // Forward leg.
    g.lineStyle(19, f.color, 1); g.lineBetween(centerX + 7, hipY, centerX + 18 - legKick, baseY - 16);
    g.lineStyle(14, f.skin, 1); g.lineBetween(centerX + 18 - legKick, baseY - 20, centerX + 28 - legKick, baseY - 9);
    g.fillStyle(f.accent, 1); g.fillRoundedRect(centerX + 14 - legKick, baseY - 14, 36, 14, 5);
    // Torso silhouette, bandana sash, jacket.
    g.fillStyle(f.color, 1); g.fillRoundedRect(centerX - 27, shoulderY, 55, 65 + crouch, 13);
    g.fillStyle(f.accent, 1); g.fillRect(centerX - 27, shoulderY + 43, 55, 9);
    g.fillStyle(f.skin, 1); g.fillRect(centerX - 9, shoulderY - 7, 18, 19);
    // Far arm.
    g.lineStyle(16, f.skin, 1); g.lineBetween(centerX - facing * 19, shoulderY + 10, centerX - facing * 37, shoulderY + 34);
    g.fillStyle(f.accent, 1); g.fillCircle(centerX - facing * 38, shoulderY + 36, 10);
    // Near arm with a clear extended punch.
    const armX = swing ? centerX + facing * (reach * swingAmount) : centerX + facing * 28;
    const armY = swing ? shoulderY + (action === 'heavy' ? 8 : 2) : shoulderY + 29 + (f.blocking ? -9 : 0);
    g.lineStyle(action === 'heavy' && swing ? 21 : 17, f.skin, 1);
    g.lineBetween(centerX + facing * 18, shoulderY + 9, armX, armY);
    g.fillStyle(f.accent, 1); g.fillCircle(armX, armY, swing ? 13 : 11);
    if (f.blocking) {
      g.lineStyle(8, f.accent, .88); g.lineBetween(centerX + facing * 26, shoulderY + 3, centerX + facing * 52, shoulderY - 22);
      g.lineBetween(centerX + facing * 52, shoulderY - 22, centerX + facing * 53, shoulderY + 10);
    }
    // Head, original cap silhouette, face and hair.
    g.fillStyle(f.skin, 1); g.fillCircle(centerX + facing * 3, headY, 22);
    g.fillStyle(0x182d32, 1); g.fillRoundedRect(centerX - 22, headY - 20, 49, 12, 5);
    g.fillStyle(f.accent, 1); g.fillRoundedRect(centerX + facing * 7 - 12, headY - 25, 36, 9, 4);
    g.fillStyle(0x1b2729, 1); g.fillCircle(centerX + facing * 11, headY - 1, 2.4);
    g.lineStyle(2, 0x553a30, 1); g.lineBetween(centerX + facing * 7, headY + 10, centerX + facing * 15, headY + 10);
    // Character-specific jacket marks, making the procedural silhouettes legible.
    g.fillStyle(f.accent, .9); g.fillCircle(centerX - facing * 8, shoulderY + 24, 4);
    if (swing) {
      g.lineStyle(3, f.accent, .32); g.strokeCircle(armX, armY, action === 'heavy' ? 22 : 17);
    }
    if (f.action === 'hit') {
      g.fillStyle(0xffe4a8, 0.7); g.fillCircle(centerX - facing * 4, headY - 2, 25);
    }
    // Tiny artist-painted identifier above the cap.
    g.fillStyle(f.accent, 1); g.fillTriangle(centerX - 7, headY - 37, centerX + 7, headY - 37, centerX, headY - 47);
  }

  shutdown() {
    window.removeEventListener('sound-clash:touch', this.touchHandler);
    window.removeEventListener('sound-clash:restart', this.restartHandler);
    this.touch.clear();
  }
}
