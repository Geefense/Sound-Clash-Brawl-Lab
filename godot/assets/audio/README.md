# Audio assets

The build ships **no recorded audio**: no music, no Patois voice lines, no hit/block/KO
samples. The only file in this tree is `default_bus_layout.tres`, the native bus/effect layout
for the Sound Clash engine.

- `placeholders/` — empty by design. The engine synthesises its placeholder sting, tags,
  selector, horn and crowd layers at run time (see the README there).
- `production/` — the exact slot filenames owner-approved recordings should use; each entry
  names the bus and the timing contract.
- `production/beats/` — the three creator-owned beats used **only** on Title/Character Select
  and after a match victory, on the `MusicBed` bus. They never play during an active round.
- `default_bus_layout.tres` — Master, Music, SFX, Crowd, `DJTag` (AudioEffectDelay →
  AudioEffectLowPassFilter → AudioEffectReverb), Selector, Stinger and `MusicBed`.

The web prototype's sound is generated at runtime by `SoundEffects.ts` (oscillator tones),
which is reference behaviour, not an asset. The web prototype's sound is generated at runtime by `SoundEffects.ts` (oscillator tones),
which is reference behaviour, not an asset.

When approved audio arrives, keep it here by role, e.g. `music/`, `voice/`, `sfx/`, and record the
source, licence and approval status for each file. Do not add placeholder audio and present it as
finished.
