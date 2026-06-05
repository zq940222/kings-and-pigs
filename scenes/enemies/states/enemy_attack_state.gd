extends EnemyState
class_name EnemyAttackState

const ATTACK_COOLDOWN := 1.2
var _cooldown: float = 0.0
var _attack_done: bool = false

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("attack")
	enemy.hitbox.monitoring = true
	_attack_done = false
	_cooldown = ATTACK_COOLDOWN
	enemy.velocity.x = 0.0
	enemy.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	_attack_done = true
	enemy.hitbox.monitoring = false

func exit() -> void:
	enemy.hitbox.monitoring = false
	if enemy.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		enemy.animated_sprite.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.move_and_slide()

	if not _attack_done:
		return
	_cooldown -= delta
	if _cooldown <= 0:
		if enemy.player_ref != null:
			state_machine.transition_to("ChaseState")
		else:
			state_machine.transition_to("PatrolState")
