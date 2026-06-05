extends EnemyBase

func _ready() -> void:
	max_hp = 3
	move_speed = 80.0
	detect_range = 180.0
	attack_range = 45.0
	damage = 1
	patrol_distance = 80.0
	add_to_group("enemies")
	super._ready()
