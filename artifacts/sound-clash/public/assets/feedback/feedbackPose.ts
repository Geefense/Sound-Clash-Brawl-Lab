// Structural adapter: compatible with a Phaser Image/Sprite; no physics or timings are changed.
export type Pose = { origin: number[]; facing: string; placement: string };
export type SpriteLike = { setTexture(key: string): unknown; setOrigin(x: number,y: number): unknown; setFlipX(flip: boolean): unknown; setPosition(x:number,y:number): unknown };
export function applyFeedbackPose(sprite: SpriteLike, key: string, pose: Pose, anchorX: number, anchorY: number, facing: 'left'|'right') {
  sprite.setTexture(key);
  sprite.setOrigin(pose.origin[0], pose.origin[1]);
  sprite.setFlipX(pose.facing !== 'away' && pose.facing !== facing);
  sprite.setPosition(anchorX, anchorY);
}
// Supply feet coordinates for grounded poses, pelvis coordinates for airborne poses,
// and floor-contact coordinates for land/KO. Keep simulation body/hitboxes separate.
