extends Area2D
class_name Hurtbox

signal hurt(damage: int, knockback: Vector2)

@export var invincible: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	area_entered.connect(_on_hitbox_entered)

func _on_hitbox_entered(hitbox: Area2D) -> void:
	if invincible:
		return
	if not hitbox is Hitbox:
		return
	var kb_dir := (global_position - hitbox.global_position).normalized()
	var knockback: Vector2 = kb_dir * hitbox.knockback_force
	hurt.emit(hitbox.damage, knockback)
