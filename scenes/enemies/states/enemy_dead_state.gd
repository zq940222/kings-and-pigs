extends EnemyState
class_name EnemyDeadState

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("dead")
	enemy.set_collision_layer_value(1, false)
	enemy.set_collision_mask_value(1, false)
	enemy.hurtbox.set_deferred("monitoring", false)
	enemy.hitbox.set_deferred("monitoring", false)
	enemy.animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

func _on_death_animation_finished() -> void:
	enemy.died.emit(enemy)
	enemy.queue_free()
