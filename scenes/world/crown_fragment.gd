extends Area2D

@export var fragment_id: String = "fragment_1"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if SaveManager.save_data.get("crown_fragments", []).has(fragment_id):
		queue_free.call_deferred()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	SaveManager.collect_crown_fragment(fragment_id)
	if SaveManager.has_all_crown_fragments():
		SaveManager.unlock_skill("kings_aura")
		if body.has_method("_load_skills_from_save"):
			body._load_skills_from_save()
		GameManager.skill_unlocked.emit("kings_aura")
	queue_free()
