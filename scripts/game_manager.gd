extends Node

signal player_died
signal area_unlocked(area_id: int)
signal skill_unlocked(skill_id: String)
signal boss_defeated(boss_id: String)

enum GameState { MAIN_MENU, PLAYING, PAUSED, DEAD, TRANSITIONING }

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const DEATH_SCREEN_SCENE := preload("res://scenes/ui/death_screen.tscn")

var current_state: GameState = GameState.MAIN_MENU
var current_room: String = ""
var player_ref: Node = null
var _pending_spawn_point: String = ""

var _hud: Node = null
var _pause_layer: CanvasLayer = null
var _death_layer: CanvasLayer = null

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
	var is_gameplay := target_scene_path.begins_with("res://scenes/world/")
	var was_gameplay := current_room.begins_with("res://scenes/world/")
	if is_gameplay and not was_gameplay:
		_create_gameplay_ui()
	elif not is_gameplay and was_gameplay:
		_destroy_gameplay_ui()
	current_state = GameState.TRANSITIONING
	current_room = target_scene_path
	_pending_spawn_point = spawn_point_name
	get_tree().change_scene_to_file(target_scene_path)

func _create_gameplay_ui() -> void:
	if _hud != null:
		return
	_hud = HUD_SCENE.instantiate()
	get_tree().root.add_child(_hud)
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 20
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_layer.add_child(PAUSE_MENU_SCENE.instantiate())
	get_tree().root.add_child(_pause_layer)
	_death_layer = CanvasLayer.new()
	_death_layer.layer = 25
	_death_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_death_layer.add_child(DEATH_SCREEN_SCENE.instantiate())
	get_tree().root.add_child(_death_layer)

func _destroy_gameplay_ui() -> void:
	if _hud:
		_hud.queue_free()
		_hud = null
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	if _death_layer:
		_death_layer.queue_free()
		_death_layer = null

func _spawn_player(spawn_point_name: String) -> void:
	var scene_root := get_tree().current_scene
	var player := PLAYER_SCENE.instantiate()
	scene_root.add_child(player)
	var spawn_point := scene_root.get_node_or_null(spawn_point_name)
	if spawn_point:
		player.global_position = spawn_point.global_position
	else:
		player.position = Vector2(100, 300)
	if _hud != null:
		_hud.connect_to_player(player)

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
