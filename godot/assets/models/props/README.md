# Prop model drop-in slots

The arena draws **no procedural prop geometry**. Speakers, the DJ booth, the microphones and
the mic stand are all `PropLoader` slots (`res://scripts/PropLoader.gd`) that name the model
they expect and show nothing until it is delivered.

Drop the five files below into **this folder**. No code change is needed; each slot loads on
the next run and logs `PropLoader: missing …` while its file is absent.

| File | Slot | Placed at (world) | Who else is there | Delivered? |
| --- | --- | --- | --- | --- |
| `jamaican_speaker.glb` | `Arena3D/SpeakerStackLeft` | x −2.55, z −1.45 | left of the fighting lane | yes |
| `rasta_speaker.glb` | `Arena3D/SpeakerStackRight` | x +2.55, z −1.45 | right of the fighting lane | no |
| `dj_booth.glb` | `DJBooth3D/PropLoader` | x 0, z −3.20 | the two 3D DJ characters stand behind it | yes |
| `wireless_mic.glb` | `…/mixamorig_RightHand/MicInHand` | right hand | Feedback and L!ckshot each | yes |
| `mic_stand.glb` | `…/mixamorig_RightHand/MicStandInHand` | right hand | L!kkle Moore only | no |

So four of the five slots are filled and `rasta_speaker.glb` is the only empty one. The
headless checks assert exactly that.

## Export requirements

- **Scale: 1 unit = 1 metre.** Godot imports `.glb` at that scale, so a 3.2 m sound-system
  tower is 3.2 units tall and a microphone is ~0.15 units.
- **Pivot at the base centre.** The slot places the model by its origin, on the ground plane
  (`y = 0`), so a speaker stack that is pivoted at its bottom centre stands on the sand with
  no offset.
- **Facing +Z.** The arena looks down −Z; a prop's front faces +Z at rest. A delivery whose
  front is painted on another axis is turned by the slot, not re-exported: set `front_axis`
  to `"-z"`, `"+x"` or `"-x"` (and `front_flip` to invert it) and `front_yaw_degrees()` turns
  that face toward the stage.
- **A hand prop is sized by its longest axis, not its height.** `TARGET_LONGEST_M` carries
  `wireless_mic: 0.24 m`; the scale is computed in world metres, dividing out the rig scale a
  Mixamo export's `fit_height` factor leaves on the hand bone. Hand props also never seat at
  Y = 0 (`auto_ground_y = false`): their floor is the grip, so the model is centred on the
  hand bone and the fist closes around the middle of the body.
- **Measured, not assumed.** Both delivered props were inspected before their slots were
  wired: `dj_booth.glb` is 2 666 triangles, `wireless_mic.glb` 2 378, both with 2 048²
  textures and both open shells (`130` and `198` boundary edges), which is why both slots keep
  two-sided culling. The booth's "Soundclash" panels and VU meters are on its local −Z face.
- Two spare hand offsets are already set per slot (`place_transform`); if a delivered model
  sits wrong in the hand, adjust the slot's own `position` / `rotation_degrees` / `scale`
  in the scene instead of re-exporting.
- Any surface with an albedo texture gets the project's cel + ink material. A surface with no
  texture is left exactly as imported and warned about — it is never given a stand-in colour.

## Not replaced by any slot

The dictionary L!kkle Moore used to swing, the crowd's flags, lighters and airhorns were also
procedural. They have **no** drop-in slot and are simply gone: nothing is drawn in their place.
