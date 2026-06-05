extends PlayerState
class_name AttackCombo3State

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("attack3")
	player.hitbox.monitoring = true
	player.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	player.hitbox.monitoring = false
	state_machine.transition_to("IdleState")

func exit() -> void:
	player.hitbox.monitoring = false

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
