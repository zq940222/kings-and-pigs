extends Area2D
class_name RoomTransition

@export var target_scene: String = ""
@export var spawn_point_name: String = "SpawnPoint"

var _transitioning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _transitioning:
		return
	if not body.is_in_group("player"):
		return
	if target_scene.is_empty():
		push_error("RoomTransition: target_scene is empty on node " + name)
		return
	_transitioning = true
	SaveManager.mark_room_explored(target_scene)
	GameManager.change_room(target_scene, spawn_point_name)
