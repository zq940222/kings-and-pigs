extends Control

@onready var continue_btn: Button = $VBoxContainer/ContinueButton

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
		GameManager.change_room("res://scenes/world/area1/area1_room1.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
