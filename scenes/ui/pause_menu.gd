extends Control

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		if visible:
			_on_resume_pressed()
		else:
			_show_pause()

func _show_pause() -> void:
	show()
	GameManager.set_state(GameManager.GameState.PAUSED)

func _on_resume_pressed() -> void:
	hide()
	GameManager.set_state(GameManager.GameState.PLAYING)

func _on_main_menu_pressed() -> void:
	hide()
	get_tree().paused = false
	GameManager.change_room("res://scenes/ui/main_menu.tscn")
