extends EnemyBase

enum Phase { ONE, TWO, THREE }

var current_phase: Phase = Phase.ONE
var _minion_spawned: bool = false

@export var boss_id: String = "boss_area1"
@export var skill_reward: String = "roll_upgrade"

func _ready() -> void:
	max_hp = 20
	move_speed = 100.0
	detect_range = 400.0
	attack_range = 60.0
	damage = 2
	patrol_distance = 0.0
	add_to_group("enemies")
	add_to_group("boss")
	super._ready()
	died.connect(_on_boss_died)

func update_phase() -> void:
	var hp_percent := float(current_hp) / float(max_hp)
	if hp_percent <= 0.3 and current_phase != Phase.THREE:
		current_phase = Phase.THREE
		move_speed = 140.0
	elif hp_percent <= 0.6 and current_phase == Phase.ONE:
		current_phase = Phase.TWO
		if not _minion_spawned:
			_spawn_minions()
			_minion_spawned = true

func _spawn_minions() -> void:
	var pig_scene := load("res://scenes/enemies/pig/pig.tscn")
	if pig_scene == null:
		push_error("KingPig: pig.tscn not found")
		return
	for i: int in 2:
		var minion: Node = pig_scene.instantiate()
		get_parent().add_child(minion)
		minion.global_position = global_position + Vector2(float(i * 2 - 1) * 80.0, 0.0)

func _on_boss_died(_enemy: EnemyBase) -> void:
	SaveManager.mark_boss_defeated(boss_id)
	if not skill_reward.is_empty():
		SaveManager.unlock_skill(skill_reward)
		GameManager.skill_unlocked.emit(skill_reward)
	SaveManager.save()
	GameManager.boss_defeated.emit(boss_id)
