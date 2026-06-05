extends PlayerState
class_name HurtState

const HURT_DURATION := 0.4
var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("hurt")
	player.set_invincible(true)
	var hurt_sfx := load("res://assets/audio/hurt.wav")
	player.play_sfx(hurt_sfx)
	_timer = HURT_DURATION

func exit() -> void:
	player.set_invincible(false)

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()
	_timer -= delta
	if _timer <= 0:
		state_machine.transition_to("IdleState")
