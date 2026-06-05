extends Control

const SAVE_POINT_SCENE_MAP := {
	"area1_save1": "res://scenes/world/area1/area1_room1.tscn",
	"area1_save2": "res://scenes/world/area1/area1_room3.tscn",
	"area2_save1": "res://scenes/world/area2/area2_room1.tscn",
	"area2_save2": "res://scenes/world/area2/area2_room3.tscn",
	"area3_save1": "res://scenes/world/area3/area3_room1.tscn",
	"area3_save2": "res://scenes/world/area3/area3_room3.tscn",
	"area4_save1": "res://scenes/world/area4/area4_room1.tscn",
	"area4_save2": "res://scenes/world/area4/area4_room3.tscn",
}

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.player_died.connect(_on_player_died)
	$VBoxContainer/RetryButton.pressed.connect(_on_retry_pressed)

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	show()

func _on_retry_pressed() -> void:
	hide()
	get_tree().paused = false
	var last_point: String = SaveManager.save_data.get("last_save_point", "area1_save1")
	var scene: String = SAVE_POINT_SCENE_MAP.get(last_point, "res://scenes/world/area1/area1_room1.tscn")
	GameManager.change_room(scene)
