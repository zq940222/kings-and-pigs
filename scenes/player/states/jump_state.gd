extends PlayerState
class_name JumpState

func enter(msg: Dictionary = {}) -> void:
	player.animated_sprite.play("jump")
	player.velocity.y = Player.JUMP_VELOCITY
	var jump_sfx := load("res://assets/audio/jump.wav")
	player.play_sfx(jump_sfx)
	if msg.get("reset_double_jump", true):
		player.has_double_jumped = false

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
		player.animated_sprite.play("jump")
		return

	if player.velocity.y >= 0:
		state_machine.transition_to("FallState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
