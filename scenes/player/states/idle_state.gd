extends PlayerState
class_name IdleState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("idle")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.regen_stamina(delta)
	player.velocity.x = 0.0
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to("FallState")
		return
	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("JumpState")
		return
	if player.get_input_direction() != 0:
		state_machine.transition_to("RunState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
	if Input.is_action_just_pressed("skill") and Input.is_key_pressed(KEY_SHIFT):
		player.use_skill()
		return
	if Input.is_action_pressed("block"):
		state_machine.transition_to("BlockState")
		return
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("RollState")
		return
