extends EnemyBase

var _is_shielding: bool = false

func _ready() -> void:
	max_hp = 5
	move_speed = 60.0
	detect_range = 200.0
	attack_range = 50.0
	damage = 2
	patrol_distance = 60.0
	add_to_group("enemies")
	super._ready()

func _on_hurt(dmg: int, knockback: Vector2) -> void:
	if _is_shielding and player_ref != null:
		var player_on_front := (player_ref.global_position.x > global_position.x) == facing_right
		if player_on_front:
			return
	super._on_hurt(dmg, knockback)

func set_shielding(value: bool) -> void:
	_is_shielding = value
