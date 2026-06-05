extends PlayerState
class_name FallState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("fall")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.regen_stamina(delta)

	var dir := player.get_input_direction()
	player.velocity.x = dir * Player.SPEED
	player.flip_sprite(dir)
	player.move_and_slide()

	if player.can_double_jump and not player.has_double_jumped and Input.is_action_just_pressed("jump"):
		player.velocity.y = Player.JUMP_VELOCITY
		player.has_double_jumped = true
		state_machine.transition_to("JumpState")
		return

	if player.is_on_floor():
		if player.get_input_direction() != 0:
			state_machine.transition_to("RunState")
		else:
			state_machine.transition_to("IdleState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
