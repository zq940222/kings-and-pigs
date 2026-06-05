extends StaticBody2D
class_name AreaGate

@export var required_skill: String = ""
@export var required_boss: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	if not _check_unlock():
		GameManager.skill_unlocked.connect(_on_condition_changed)
		GameManager.boss_defeated.connect(_on_condition_changed)

func _check_unlock() -> bool:
	var skill_ok := required_skill.is_empty() or SaveManager.has_skill(required_skill)
	var boss_ok := required_boss.is_empty() or SaveManager.has_defeated_boss(required_boss)
	if skill_ok and boss_ok:
		_unlock()
		return true
	return false

func _on_condition_changed(_id: String) -> void:
	if _check_unlock():
		GameManager.skill_unlocked.disconnect(_on_condition_changed)
		GameManager.boss_defeated.disconnect(_on_condition_changed)

func _unlock() -> void:
	if sprite:
		sprite.hide()
	if collision:
		collision.set_deferred("disabled", true)
	if hint_label:
		hint_label.hide()
