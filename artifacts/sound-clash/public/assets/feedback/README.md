# Feedback — transparent pose integration pack

17 RGBA cutouts in raw/, plus 17 uniformly scaled/padded versions in aligned/.
All aligned canvases are 1536 × 1024. Standing/support-foot poses share a foot baseline at y=900. Airborne images use a visually estimated pelvis anchor at (768,610); floor poses use ground contact at (768,900). Per-pose normalized origins, raw anchors, alpha bounds, native facing and state suggestions are in feedback.poses.json. These are render anchors, not physics bodies or hitboxes.

## Start the self-match

1. Copy aligned/ and feedback.poses.json into the game's public asset directory.
2. Load each image as a separate texture using its pose name.
3. Use manifest origin when positioning at the corresponding foot/body/contact point. Keep the deterministic simulation and collision body independent of the picture.
4. First wire idle, lowAttack, poke, BOX windup/contact/recovery, guard, hurt and KO. Use the same set for opponent, with a tint/marker.
5. Test transitions and refine estimated scales/air anchors during gameplay. Do not derive timing, damage or collision geometry from the art.

Grounded and airborne coordinates represent different anatomical points. When changing from feet to pelvis origin, position the sprite at the simulation's pelvis, not at its feet. Land/KO anchors return to floor contact. Preview shows this distinction.

## Effects

Concrete, cast shadows, birds/stars, motion marks, dust, breath puffs and flames are removed from fighter PNGs. No separate effect sprites are supplied: draw a ground ellipse and particles independently in game; use originals as visual reference for more complex effects. Fire poses retain the lighter and original warm lighting, and need a separately rendered flame. The cable stays baked into each pose for this first integration; later separate/animate it if transitions snap.

## Limits

These are key poses, not complete smooth animations or a rig. Transparent extraction used a generative image editor, so minor detail/edge changes can occur. Hair, hat details and rendering still have small differences between poses; this is suitable for a first playable art pass, not a promise of frame-perfect continuity. Pose scaling and nonstanding anchors are visually estimated and need an in-game transition pass. Mirroring is acceptable for the initial self-match but mirrors microphone handedness too. Gut-punch artwork natively faces LEFT; other front/side poses face RIGHT, rear salute faces away.

No code repository has been modified. Use these assets with the existing combat simulation; more concept art is not required to begin integration.
