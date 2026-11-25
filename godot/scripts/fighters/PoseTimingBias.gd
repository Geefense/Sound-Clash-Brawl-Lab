class_name PoseTimingBias
extends Resource
## Per-fighter pose-timing bias (PART 1 commit 2, 2026-11-25).
##
## The Zweifuss 3rd Strike archive and the Stefan Iverson Makoto breakdown describe three
## different kinds of weight in the same fight: a crisp boxer whose silhouette is clean at
## the contact, an explosive lunge character who holds the hit, and a bouncy young stylist
## whose recovery keeps dancing. Every fighter in this game shares one FSM, so that
## difference is authored here and read only by the 3D presentation layer.
##
## This is a **Resource** on purpose: it is exported on `FighterModel3D`, so a designer can
## duplicate one body's bias, retune it in the inspector and see the change without a code
## edit. Nothing in this file — and nothing that reads it — touches `BaseFighter`, the frame
## data, the hitboxes, the 132 BPM window or the 31 Patois entries.

## Display label, for the inspector and the headless audit readout.
@export var label: String = "neutral"
## Archetype family this bias was authored from, for the ledger. Not read by the runtime.
@export var reference: String = ""
## How far the startup coils INTO the forward step, metres. Clamped by
## `AnimationFeel.ANTICIPATION_MAX` when it is spent, so an over-tuned resource can never
## slide a body far enough to read as a teleport.
@export_range(0.0, 0.06, 0.001) var anticipation_depth: float = 0.035
## Pose steps the striking limb chain is locked at peak reach after a contact (2–3).
@export_range(2, 3, 1) var impact_hold: int = 2
## Pose steps the striking hand trails the hips in the C → S → reverse-C whip (1–2).
@export_range(1, 2, 1) var whip_lead: int = 2
## Peak of the non-linear hip-dip in RECOVERY, degrees. Bigger reads as a heavier settle.
@export_range(0.0, 8.0, 0.1) var recovery_dip_deg: float = 3.4
## How far the recovery overshoots back past neutral before the idle resumes, 0–1 of the dip.
@export_range(0.0, 1.0, 0.01) var recovery_overshoot: float = 0.30
## Multiplier on the strike's overshoot impulse: a crisp boxer snaps less than a lunge.
@export_range(0.5, 1.6, 0.01) var overshoot_gain: float = 1.0
## Multiplier on the strike's torso counter-twist.
@export_range(0.5, 1.5, 0.01) var twist_gain: float = 1.0
## Extra idle/walk bounce on the beat. 1.0 is the shared moving-hold idle.
@export_range(0.0, 2.0, 0.01) var beat_bounce: float = 1.0


## The three archetypes. Each call returns a fresh instance, so one body retuning its bias in
## the inspector (or at runtime) can never leak into another body in the same match.
static func for_fighter(key: StringName) -> PoseTimingBias:
	var bias := PoseTimingBias.new()
	match key:
		&"feedback":
			# Dudley: crisp boxing jab/hook, a clean upper-body silhouette, minimal waste.
			bias.label = "Feedback — crisp boxer"
			bias.reference = "Dudley (3rd Strike): compact coil, clean contact silhouette"
			bias.anticipation_depth = 0.028
			bias.impact_hold = 2
			bias.whip_lead = 1
			bias.recovery_dip_deg = 2.6
			bias.recovery_overshoot = 0.22
			bias.overshoot_gain = 0.90
			bias.twist_gain = 0.95
			bias.beat_bounce = 0.55
		&"lickshot":
			# Makoto: explosive lunge strikes and long impact holds.
			bias.label = "L!ckshot — explosive lunge"
			bias.reference = "Makoto (3rd Strike): deep load, long held contact"
			bias.anticipation_depth = 0.052
			bias.impact_hold = 3
			bias.whip_lead = 2
			bias.recovery_dip_deg = 3.9
			bias.recovery_overshoot = 0.34
			bias.overshoot_gain = 1.30
			bias.twist_gain = 1.20
			bias.beat_bounce = 0.85
		&"young_selecta":
			# Sean / Elena: rhythmic beat bounce and an expressive recovery settle.
			bias.label = "L!kkle Moore — rhythmic stylist"
			bias.reference = "Sean / Elena (3rd Strike): bounce-led rhythm, playful settle"
			bias.anticipation_depth = 0.038
			bias.impact_hold = 2
			bias.whip_lead = 2
			bias.recovery_dip_deg = 4.7
			bias.recovery_overshoot = 0.42
			bias.overshoot_gain = 1.10
			bias.twist_gain = 1.05
			bias.beat_bounce = 1.65
		_:
			bias.label = "neutral"
			bias.reference = "shared default"
	return bias


## True when this resource carries a real archetype rather than the neutral fallback.
func is_authored() -> bool:
	return reference != "" and label != "neutral"
