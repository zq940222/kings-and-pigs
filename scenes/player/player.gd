extends CharacterBody2D
class_name Player

const SPEED := 200.0
const JUMP_VELOCITY := -380.0
const GRAVITY := 980.0
const MAX_STAMINA := 100.0
const STAMINA_REGEN := 20.0
const ROLL_STAMINA_COST := 25.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $AttackHitbox

var max_hp: int = 6
var current_hp: int = 6
var stamina: float = MAX_STAMINA
var is_invincible: bool = false
var facing_right: bool = true

var can_double_jump: bool = false
var has_double_jumped: bool = false
var has_roll_upgrade: bool = false
var has_shockwave: bool = false
var has_kings_aura: bool = false

signal hp_changed(new_hp: int)
signal stamina_changed(new_stamina: float)
signal player_died

func _ready() -> void:
	add_to_group("player")
	GameManager.register_player(self)
	hurtbox.hurt.connect(_on_hurt)
	_load_skills_from_save()
	GameManager.skill_unlocked.connect(func(_id: String) -> void: _load_skills_from_save())

func _load_skills_from_save() -> void:
	can_double_jump = SaveManager.has_skill("double_jump")
	has_roll_upgrade = SaveManager.has_skill("roll_upgrade")
	has_shockwave = SaveManager.has_skill("shockwave")
	has_kings_aura = SaveManager.has_skill("kings_aura")

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")

func flip_sprite(direction: float) -> void:
	if direction != 0:
		facing_right = direction > 0
		animated_sprite.flip_h = not facing_right

func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina)
	return true

func regen_stamina(delta: float) -> void:
	if stamina < MAX_STAMINA:
		stamina = min(stamina + STAMINA_REGEN * delta, MAX_STAMINA)
		stamina_changed.emit(stamina)

func take_damage(damage: int, knockback: Vector2) -> void:
	if is_invincible:
		return
	var facing_attacker := knockback.x * (1.0 if facing_right else -1.0) < 0
	var is_blocking: bool = get_meta("is_blocking", false)
	if is_blocking and facing_attacker:
		damage = int(damage * 0.2)
	current_hp -= damage
	current_hp = max(current_hp, 0)
	hp_changed.emit(current_hp)
	velocity = knockback
	if current_hp <= 0:
		state_machine.transition_to("DeadState")
	else:
		state_machine.transition_to("HurtState")

func _on_hurt(damage: int, knockback: Vector2) -> void:
	take_damage(damage, knockback)

func set_invincible(value: bool) -> void:
	is_invincible = value
	hurtbox.invincible = value

func use_skill() -> void:
	if has_shockwave:
		_cast_shockwave()
	elif has_kings_aura:
		_cast_kings_aura()

func _cast_shockwave() -> void:
	var wave_scene := load("res://scenes/player/shockwave.tscn")
	if wave_scene == null:
		push_error("Player: shockwave.tscn not found")
		return
	var wave := wave_scene.instantiate()
	get_parent().add_child(wave)
	wave.global_position = global_position
	wave.direction = Vector2.RIGHT if facing_right else Vector2.LEFT

func _cast_kings_aura() -> void:
	set_invincible(true)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("stun"):
			enemy.stun(2.0)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self) and current_hp > 0:
		set_invincible(false)

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var sfx_player: AudioStreamPlayer2D = get_node_or_null("SFXPlayer")
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()
