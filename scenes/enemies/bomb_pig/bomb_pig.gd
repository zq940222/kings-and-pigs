extends EnemyBase

const THROW_COOLDOWN := 3.0
const THROW_SPEED := 250.0

var _throw_timer: float = 0.0

func _ready() -> void:
	max_hp = 4
	move_speed = 60.0
	detect_range = 280.0
	attack_range = 200.0
	damage = 2
	patrol_distance = 80.0
	add_to_group("enemies")
	super._ready()

func _physics_process(delta: float) -> void:
	if _throw_timer > 0.0:
		_throw_timer -= delta
	if player_ref != null and not is_dead:
		var dist := global_position.distance_to(player_ref.global_position)
		if dist <= attack_range and _throw_timer <= 0.0:
			flip_toward(player_ref.global_position.x)
			throw_bomb()

func throw_bomb() -> void:
	if player_ref == null:
		return
	var bomb_scene := load("res://scenes/enemies/bomb_pig/bomb.tscn")
	if bomb_scene == null:
		push_error("BombPig: bomb.tscn not found")
		return
	var bomb := bomb_scene.instantiate()
	get_parent().add_child(bomb)
	var offset := Vector2(30.0 * (1.0 if facing_right else -1.0), -20.0)
	bomb.global_position = global_position + offset
	var target_dir := (player_ref.global_position - bomb.global_position).normalized()
	bomb.launch(target_dir, THROW_SPEED)
	_throw_timer = THROW_COOLDOWN
