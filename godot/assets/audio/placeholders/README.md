# Placeholder audio — synthesised at run time, no files

This folder is intentionally empty. Every Sound Clash audio slot currently falls back to a
deterministic placeholder generated in memory by `scripts/audio/SoundClashAudio.gd` at 22.05 kHz
mono 16-bit: the 6.0 s round-start sting, the two DJ tag calls, the selector yell, the airhorn,
the guitar stab and the three crowd layers. No research clip, no downloaded sample and no
copyrighted recording is loaded from `artifacts/`, the web or anywhere else.

Placeholders exist to prove **timing, routing, echo, priority and mixing**, not to be shipped as
final voices. They are clearly labelled in code and in AGENTS.md §9 item 45. Do not present them
as approved sound design.

Rules:
- Never copy raw research audio into this folder or into `production/`.
- Keep the generated placeholders code-only unless the owner approves a recording.
- When a real file lands in `production/` with the exact slot name, the engine loads it instead
  of the placeholder automatically.
