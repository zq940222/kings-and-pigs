extends Control

@onready var continue_btn: Button = $VBoxContainer/ContinueButton

const SAVE_POINT_SCENE_MAP: Dictionary = {
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
	continue_btn.disabled = not SaveManager.has_save()
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
	SaveManager.delete_save()
	GameManager.change_room("res://scenes/world/area1/area1_room1.tscn")

func _on_continue_pressed() -> void:
	if SaveManager.load_save():
		var last_point: String = SaveManager.save_data.get("last_save_point", "area1_save1")
		var scene: String = SAVE_POINT_SCENE_MAP.get(last_point, "res://scenes/world/area1/area1_room1.tscn")
		GameManager.change_room(scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
