import type { FighterInput } from '../simulation/types.ts';

/**
 * Device action vocabulary. `heavy` is the TUMP body shot and `head` is the
 * backhand BOX, matching FighterInput; the touch layer's historical
 * `heavy`/`body` labels are translated once, in GameScene.
 */
export type DeviceAction = 'left' | 'right' | 'jump' | 'block' | 'light' | 'heavy' | 'head' | 'upper';

const EDGE_ACTIONS: ReadonlySet<DeviceAction> = new Set<DeviceAction>([
  'jump',
  'light',
  'heavy',
  'head',
  'upper',
]);

const MAX_QUEUED_EDGES = 8;

export const NEUTRAL_DEVICE_INPUT: FighterInput = Object.freeze({
  left: false,
  right: false,
  jump: false,
  block: false,
  light: false,
  heavy: false,
  head: false,
  upper: false,
});

/**
 * The single input boundary between devices and the fixed-step simulation.
 *
 * - Presses are queued, never sampled from live device state, so a tap that
 *   starts and ends between two ticks (the classic touch-input bug) is still
 *   delivered exactly once.
 * - One press produces exactly one simulated press, so holding or mashing a
 *   key through several sub-steps cannot repeat an attack.
 * - Held movement/block state is carried across ticks, which fixes the
 *   "multiple simulation ticks per render frame" case.
 */
export class InputBuffer {
  private held = new Set<DeviceAction>();
  private edges: DeviceAction[] = [];

  press(action: DeviceAction): void {
    this.held.add(action);
    if (EDGE_ACTIONS.has(action)) this.queueEdge(action);
  }

  release(action: DeviceAction): void {
    this.held.delete(action);
  }

  /** Set continuous state without producing an edge (keyboard held keys). */
  setHeld(action: DeviceAction, pressed: boolean): void {
    if (pressed) this.held.add(action);
    else this.held.delete(action);
  }

  clear(): void {
    this.held.clear();
    this.edges.length = 0;
  }

  get queuedEdges(): number {
    return this.edges.length;
  }

  isHeld(action: DeviceAction): boolean {
    return this.held.has(action);
  }

  /** Consume exactly one queued press for the next simulation tick. */
  sample(): FighterInput {
    const edge = this.edges.shift();
    return {
      left: this.held.has('left'),
      right: this.held.has('right'),
      jump: edge === 'jump',
      block: this.held.has('block'),
      light: edge === 'light',
      heavy: edge === 'heavy',
      head: edge === 'head',
      upper: edge === 'upper',
    };
  }

  private queueEdge(action: DeviceAction): void {
    this.edges.push(action);
    if (this.edges.length > MAX_QUEUED_EDGES) this.edges.shift();
  }
}
