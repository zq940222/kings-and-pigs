extends Area2D

@export var save_point_id: String = "save_point_1"

var _used_this_session: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _used_this_session:
		return
	_used_this_session = true
	_do_save(body)

func _do_save(player: Node) -> void:
	player.current_hp = player.max_hp
	player.hp_changed.emit(player.current_hp)
	SaveManager.save_data["last_save_point"] = save_point_id
	SaveManager.save_data["player_hp"] = player.current_hp
	SaveManager.save()
