extends Node

signal player_died
signal area_unlocked(area_id: int)
signal skill_unlocked(skill_id: String)
signal boss_defeated(boss_id: String)

enum GameState { MAIN_MENU, PLAYING, PAUSED, DEAD, TRANSITIONING }

var current_state: GameState = GameState.MAIN_MENU
var current_room: String = ""
var player_ref: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_room(target_scene_path: String, spawn_point_name: String = "SpawnPoint") -> void:
	current_state = GameState.TRANSITIONING
	current_room = target_scene_path
	get_tree().change_scene_to_file(target_scene_path)

func set_state(new_state: GameState) -> void:
	current_state = new_state
	if new_state == GameState.PAUSED or new_state == GameState.DEAD:
		get_tree().paused = true
	elif new_state == GameState.PLAYING:
		get_tree().paused = false

func register_player(player: Node) -> void:
	player_ref = player
