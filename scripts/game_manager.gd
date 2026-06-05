extends Node

signal player_died
signal area_unlocked(area_id: int)
signal skill_unlocked(skill_id: String)
signal boss_defeated(boss_id: String)

enum GameState { MAIN_MENU, PLAYING, PAUSED, DEAD, TRANSITIONING }

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var current_state: GameState = GameState.MAIN_MENU
var current_room: String = ""
var player_ref: Node = null
var _pending_spawn_point: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if current_state != GameState.TRANSITIONING or _pending_spawn_point == "":
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != current_room:
		return
	var spawn := _pending_spawn_point
	_pending_spawn_point = ""
	_spawn_player(spawn)
	current_state = GameState.PLAYING

func change_room(target_scene_path: String, spawn_point_name: String = "SpawnPoint") -> void:
	current_state = GameState.TRANSITIONING
	current_room = target_scene_path
	_pending_spawn_point = spawn_point_name
	get_tree().change_scene_to_file(target_scene_path)

func _spawn_player(spawn_point_name: String) -> void:
	var scene_root := get_tree().current_scene
	var player := PLAYER_SCENE.instantiate()
	scene_root.add_child(player)
	var spawn_point := scene_root.get_node_or_null(spawn_point_name)
	if spawn_point:
		player.global_position = spawn_point.global_position
	else:
		player.position = Vector2(100, 300)

func set_state(new_state: GameState) -> void:
	current_state = new_state
	if new_state == GameState.PAUSED or new_state == GameState.DEAD:
		get_tree().paused = true
	elif new_state == GameState.PLAYING:
		get_tree().paused = false

func register_player(player: Node) -> void:
	player_ref = player

func play_bgm(stream: AudioStream) -> void:
	var bgm_player: AudioStreamPlayer = get_node_or_null("BGMPlayer")
	if bgm_player == null:
		return
	if bgm_player.stream == stream:
		return
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm() -> void:
	var bgm_player: AudioStreamPlayer = get_node_or_null("BGMPlayer")
	if bgm_player:
		bgm_player.stop()
