extends EnemyState
class_name ChaseState

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("run")

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)

	if enemy.player_ref == null:
		state_machine.transition_to("PatrolState")
		return

	var dir: float = sign(enemy.player_ref.global_position.x - enemy.global_position.x)
	enemy.velocity.x = dir * enemy.move_speed * 1.3
	enemy.flip_toward(enemy.player_ref.global_position.x)
	enemy.move_and_slide()

	var dist: float = enemy.global_position.distance_to(enemy.player_ref.global_position)
	if dist <= enemy.attack_range:
		state_machine.transition_to("EnemyAttackState")
	elif dist > enemy.detect_range * 1.5:
		state_machine.transition_to("PatrolState")
