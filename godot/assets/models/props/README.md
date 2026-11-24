# Prop model drop-in slots

The arena draws **no procedural prop geometry**. Speakers, the DJ booth, the microphones and
the mic stand are all `PropLoader` slots (`res://scripts/PropLoader.gd`) that name the model
they expect and show nothing until it is delivered.

Drop the five files below into **this folder**. No code change is needed; each slot loads on
the next run and logs `PropLoader: missing …` while its file is absent.

| File | Slot | Placed at (world) | Who else is there |
| --- | --- | --- | --- |
| `jamaican_speaker.glb` | `Arena3D/SpeakerStackLeft` | x −2.55, z −1.45 | left of the fighting lane |
| `rasta_speaker.glb` | `Arena3D/SpeakerStackRight` | x +2.55, z −1.45 | right of the fighting lane |
| `dj_booth.glb` | `DJBooth3D/PropLoader` | x 0, z −3.20 | the two 3D DJ characters stand at it |
| `wireless_mic.glb` | `…/mixamorig_RightHand/MicInHand` | right hand | Feedback and L!ckshot each |
| `mic_stand.glb` | `…/mixamorig_RightHand/MicStandInHand` | right hand | L!kkle Moore only |

## Export requirements

- **Scale: 1 unit = 1 metre.** Godot imports `.glb` at that scale, so a 3.2 m sound-system
  tower is 3.2 units tall and a microphone is ~0.15 units.
- **Pivot at the base centre.** The slot places the model by its origin, on the ground plane
  (`y = 0`), so a speaker stack that is pivoted at its bottom centre stands on the sand with
  no offset.
- **Facing +Z.** The arena looks down −Z; a prop's front faces +Z at rest.
- Two spare hand offsets are already set per slot (`place_transform`); if a delivered model
  sits wrong in the hand, adjust the slot's own `position` / `rotation_degrees` / `scale`
  in the scene instead of re-exporting.
- Any surface with an albedo texture gets the project's cel + ink material. A surface with no
  texture is left exactly as imported and warned about — it is never given a stand-in colour.

## Not replaced by any slot

The dictionary L!kkle Moore used to swing, the crowd's flags, lighters and airhorns were also
procedural. They have **no** drop-in slot and are simply gone: nothing is drawn in their place.
