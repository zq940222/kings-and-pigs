extends EnemyState
class_name EnemyHurtState

const HURT_DURATION := 0.3
var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("hurt")
	_timer = HURT_DURATION

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	_timer -= delta
	if _timer <= 0:
		if enemy.player_ref != null:
			state_machine.transition_to("ChaseState")
		else:
			state_machine.transition_to("PatrolState")
