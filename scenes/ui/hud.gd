extends CanvasLayer
class_name HUD

@onready var heart_container: HBoxContainer = $MarginContainer/TopLeft/HeartContainer
@onready var stamina_bar: ProgressBar = $MarginContainer/StaminaBar
@onready var skill_icons: HBoxContainer = $MarginContainer/SkillIcons

const HEART_SIZE := Vector2(16, 16)
const HEART_FULL_COLOR := Color(0.9, 0.1, 0.1, 1.0)
const HEART_EMPTY_COLOR := Color(0.3, 0.3, 0.3, 1.0)

var heart_icons: Array[ColorRect] = []

func _ready() -> void:
	assert(heart_container != null, "HUD: HeartContainer node missing")
	assert(stamina_bar != null, "HUD: StaminaBar node missing")
	_init_hearts(6)
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0

func _init_hearts(count: int) -> void:
	for child in heart_container.get_children():
		child.queue_free()
	heart_icons.clear()
	for i in count:
		var icon := ColorRect.new()
		icon.custom_minimum_size = HEART_SIZE
		icon.color = HEART_FULL_COLOR
		heart_container.add_child(icon)
		heart_icons.append(icon)

func update_hp(new_hp: int) -> void:
	for i in heart_icons.size():
		heart_icons[i].color = HEART_FULL_COLOR if i < new_hp else HEART_EMPTY_COLOR

func update_stamina(new_stamina: float) -> void:
	stamina_bar.value = new_stamina

func connect_to_player(player: Node) -> void:
	if player.hp_changed.is_connected(update_hp):
		return
	player.hp_changed.connect(update_hp)
	player.stamina_changed.connect(update_stamina)
	update_hp(player.current_hp)
	update_stamina(player.stamina)
