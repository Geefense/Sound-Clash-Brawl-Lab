extends SceneTree
## Does a scripted InputMap heavy actually reach the defender? Prints the attacker's and the
## defender's states and the defender's health while the attack is held and released.

const QAMatch := preload("res://tools/qa_match.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	var arena = await QAMatch.boot(self, &"feedback", &"lickshot", 2)
	print("[play] mirrored %d p2_ actions (p1_ must exist first: the fighter registers them in _ready)" % QAMatch.mirror_actions())
	var attacker: BaseFighter = arena.p2
	var defender: BaseFighter = arena.p1
	var dx0: float = defender.global_position.x - attacker.global_position.x
	print("[play] start dx %.1f  a.health %.0f d.health %.0f  floor a %s" % [dx0,
		attacker.health, defender.health, str(attacker.is_on_floor())])
	attacker.use_local_input = true
	attacker.input_locked = false
	defender.input_locked = false
	print("[play] prefix a='%s' d='%s' locked a=%s d=%s local a=%s" % [attacker.input_prefix,
		defender.input_prefix, str(attacker.input_locked), str(defender.input_locked),
		str(attacker.use_local_input)])
	for tick in 300:
		var dx: float = defender.global_position.x - attacker.global_position.x
		var action := ""
		if absf(dx) > 96.0:
			action = "p2_right" if dx > 0.0 else "p2_left"
		elif attacker.state == BaseFighter.State.IDLE:
			action = "p2_heavy"
		if action != "":
			Input.action_press(action)
		await physics_frame
		if action != "":
			await physics_frame
			Input.action_release(action)
		if tick % 10 == 0:
			print("t%03d dx %+.0f a=%d d=%d ah %.0f dh %.0f" % [tick, dx, attacker.state,
				defender.state, attacker.health, defender.health])
		if defender.state == BaseFighter.State.KNOCKDOWN:
			print("[play] defender knocked down at t%d (d.health %.0f)" % [tick, defender.health])
			break
	await QAMatch.close(self, arena)
	quit(0)
