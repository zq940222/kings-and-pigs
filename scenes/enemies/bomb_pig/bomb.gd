extends Node2D
class_name Bomb

const GRAVITY := 980.0
const FUSE_TIME := 2.0
const EXPLOSION_DAMAGE := 2
const EXPLOSION_KNOCKBACK := 300.0
const EXPLOSION_RADIUS := 60.0

var _velocity: Vector2 = Vector2.ZERO
var _fuse_timer: float = FUSE_TIME

func launch(direction: Vector2, speed: float) -> void:
	_velocity = direction * speed

func _physics_process(delta: float) -> void:
	_velocity.y += GRAVITY * delta
	global_position += _velocity * delta
	_fuse_timer -= delta
	if _fuse_timer <= 0:
		_explode()

func _explode() -> void:
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) <= EXPLOSION_RADIUS:
			var kb_dir: Vector2 = (body.global_position - global_position).normalized()
			body.take_damage(EXPLOSION_DAMAGE, kb_dir * EXPLOSION_KNOCKBACK)
	queue_free()
