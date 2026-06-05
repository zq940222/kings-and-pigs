extends PlayerState
class_name DeadState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("dead")
	player.set_invincible(true)
	player.velocity = Vector2.ZERO
	player.animated_sprite.animation_finished.connect(_on_dead_animation_finished, CONNECT_ONE_SHOT)
	GameManager.set_state(GameManager.GameState.DEAD)

func _on_dead_animation_finished() -> void:
	player.player_died.emit()
	GameManager.player_died.emit()
