extends Node

const SAVE_PATH := "user://save.json"

var save_data: Dictionary = {}

func _ready() -> void:
	_init_default_save()

func _init_default_save() -> void:
	save_data = {
		"current_area": 1,
		"last_save_point": "area1_save1",
		"player_hp": 6,
		"unlocked_skills": [],
		"defeated_bosses": [],
		"explored_rooms": [],
		"crown_fragments": []
	}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		return false
	save_data = parsed
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_init_default_save()

func has_skill(skill_id: String) -> bool:
	return skill_id in save_data.get("unlocked_skills", [])

func unlock_skill(skill_id: String) -> void:
	if not has_skill(skill_id):
		save_data["unlocked_skills"].append(skill_id)

func has_defeated_boss(boss_id: String) -> bool:
	return boss_id in save_data.get("defeated_bosses", [])

func mark_boss_defeated(boss_id: String) -> void:
	if not has_defeated_boss(boss_id):
		save_data["defeated_bosses"].append(boss_id)

func mark_room_explored(room_id: String) -> void:
	if not room_id in save_data.get("explored_rooms", []):
		save_data["explored_rooms"].append(room_id)

func collect_crown_fragment(fragment_id: String) -> void:
	if not fragment_id in save_data.get("crown_fragments", []):
		save_data["crown_fragments"].append(fragment_id)

func has_all_crown_fragments() -> bool:
	return save_data.get("crown_fragments", []).size() >= 4
