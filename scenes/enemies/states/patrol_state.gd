extends EnemyState
class_name PatrolState

var _direction: float = 1.0

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("run")

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.velocity.x = _direction * enemy.move_speed
	enemy.flip_toward(enemy.global_position.x + _direction)
	enemy.move_and_slide()

	var dist_from_origin := enemy.global_position.x - enemy.patrol_origin.x
	if abs(dist_from_origin) >= enemy.patrol_distance and signf(dist_from_origin) == signf(_direction):
		_direction *= -1.0

	if enemy.player_ref != null:
		var dist_to_player := enemy.global_position.distance_to(enemy.player_ref.global_position)
		if dist_to_player <= enemy.detect_range:
			state_machine.transition_to("ChaseState")
