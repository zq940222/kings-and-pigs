extends Area2D
class_name Hitbox

@export var damage: int = 1
@export var knockback_force: float = 200.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 8
	monitoring = false
