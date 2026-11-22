class_name ProjectileWave
extends Node2D
## Travelling strike for the two new specials (2026-11-22).
##
## L!ckshot's Sub-Bass Dubplate Wave and L!kkle Moore's thrown dictionary are real combat
## objects: they travel across the sand, test the defender's live hurtbox and call
## `receive_strike` on the owning fighter's behalf, so guard, Record Static Parry, damage,
## knockback and KO rules stay in exactly one place. The 3D disc/book seen on screen is a
## separate arena proxy; nothing visual is read here.
##
## The wave keeps no FSM state and never owns a round: it frees itself on contact, on
## lifetime expiry or when TestArena clears the `projectiles` group between rounds.

const HITSTOP_TICKS := 6
const SHAKE := 0.7

var owner_fighter: BaseFighter = null
var kind: StringName = &"dubplate"
var dir: float = 1.0
var speed: float = 520.0
var lifetime: float = 1.0
var age: float = 0.0
var attack: Dictionary = {}
var attack_id: StringName = &"strong"
var hit_size: Vector2 = Vector2(76, 104)
var _spent: bool = false
var _origin_x: float = 0.0


## Called immediately after `add_child`. `spec` is the attack's `projectile` dictionary.
func launch(attacker: BaseFighter, spec: Dictionary, facing: int) -> void:
	owner_fighter = attacker
	kind = StringName(spec.get("kind", &"dubplate"))
	speed = float(spec.get("speed", 520.0))
	lifetime = float(spec.get("life", 1.0))
	attack_id = StringName(spec.get("attack_id", &"strong"))
	hit_size = spec.get("hitbox_size", Vector2(76, 104))
	attack = {
		"damage": int(spec.get("damage", 16)),
		"blocked_damage": int(spec.get("blocked_damage", 4)),
		"hitstun": int(spec.get("hitstun", 24)),
		"knockback": spec.get("knockback", Vector2(300, -90)),
		"knockdown": bool(spec.get("knockdown", false)),
		"hitbox_size": hit_size,
		"hitbox_pos": Vector2.ZERO,
	}
	dir = 1.0 if facing >= 0 else -1.0
	_origin_x = attacker.global_position.x
	global_position = attacker.global_position + Vector2(dir * 74.0, -104.0)
	add_to_group("projectiles")
	z_index = 3


func travel_distance() -> float:
	return speed * lifetime


func _physics_process(delta: float) -> void:
	if _spent or owner_fighter == null or not is_instance_valid(owner_fighter):
		queue_free()
		return
	age += delta
	global_position.x += dir * speed * delta
	if age >= lifetime or global_position.x < 30.0 or global_position.x > 1250.0:
		queue_free()
		return
	var vol := Rect2(global_position - hit_size * 0.5, hit_size)
	for node in get_tree().get_nodes_in_group("fighters"):
		var target := node as BaseFighter
		if target == null or target == owner_fighter:
			continue
		if target.state in [BaseFighter.State.KO, BaseFighter.State.KNOCKDOWN,
				BaseFighter.State.THROWN, BaseFighter.State.GRABBED]:
			continue
		if not vol.intersects(target.hurt_rect()):
			continue
		_hit(target)
		return


func _hit(target: BaseFighter) -> void:
	_spent = true
	var strike := {
		"attack": attack,
		"attack_id": attack_id,
		"input_beat": {"on_beat": false},
		"contact_beat": {},
	}
	var result := target.receive_strike(owner_fighter, strike)
	if not bool(result.get("ignored", false)):
		owner_fighter._apply_hitstop(HITSTOP_TICKS)
		target._apply_hitstop(HITSTOP_TICKS)
		owner_fighter.camera_shake_requested.emit(SHAKE, 0.16)
		owner_fighter.strike_resolved.emit(owner_fighter, target, result)
	queue_free()
