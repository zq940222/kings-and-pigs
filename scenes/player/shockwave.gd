extends Node2D
class_name Shockwave

var direction: Vector2 = Vector2.RIGHT
const SPEED := 400.0
const DAMAGE := 2
const KNOCKBACK_FORCE := 200.0
const LIFETIME := 0.8

var _lifetime_timer: float = LIFETIME

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			var kb := direction * KNOCKBACK_FORCE
			body.take_damage(DAMAGE, kb)
		elif body.has_node("Hurtbox"):
			var kb := direction * KNOCKBACK_FORCE
			body.get_node("Hurtbox").hurt.emit(DAMAGE, kb)
