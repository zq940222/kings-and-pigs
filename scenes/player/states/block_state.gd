extends PlayerState
class_name BlockState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("block")
	player.set_meta("is_blocking", true)

func exit() -> void:
	player.set_meta("is_blocking", false)

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
	player.regen_stamina(delta)

	if not Input.is_action_pressed("block"):
		state_machine.transition_to("IdleState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
