# Production audio slots

Drop owner-approved, licensed or original recordings here using these exact filenames. The
engine prefers them over its synthesised placeholders; missing files simply fall back.

| Slot | File | Bus | Notes |
| --- | --- | --- | --- |
| Round-start sting | `round_start_sting.wav` | `Stinger` | ~6.0 s. The single guitar stab must land at **1.8 s** (`SoundClashAudio.FIGHT_AT`, the round announce boundary) so it fires on FIGHT! |
| Feedback DJ tag | `feedback_tag.wav` | `DJTag` | Dry voice only. The tape-delay / low-pass / reverb chain is applied by the bus. |
| Lickshot DJ tag | `lickshot_tag.wav` | `DJTag` | Same: do not bake echo into the file. |
| Selector yell | `selector_yell.wav` | `Selector` | "TEK WEH HIM MIC!", "WHEEL UP!", "UNPLUG THAT SOUND!" and friends. |
| Crowd murmur | `crowd_murmur.wav` | `Crowd` | Loopable neutral bed; it is faded to silence when the crowd level is 0. |
| Crowd cheer | `crowd_cheer.wav` | `Crowd` | Mid layer, whistles/cheers. |
| Crowd eruption | `crowd_eruption.wav` | `Crowd` | Top layer for heavy knockbacks, tags and K.O.s. |

44.1 kHz or 22.05 kHz mono/stereo WAV is fine; Godot resamples. The engine sets loop points for
the three crowd files. Tag files should be short (≈0.8–1.4 s) so the bus echo, not the clip,
creates the cascade.

Record source, licence and owner approval next to any file before committing it. No paid
service and no unlicensed commercial dubplate may be added here.
