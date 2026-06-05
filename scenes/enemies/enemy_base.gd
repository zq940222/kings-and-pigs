extends CharacterBody2D
class_name EnemyBase

const GRAVITY := 980.0

@export var max_hp: int = 3
@export var move_speed: float = 80.0
@export var detect_range: float = 200.0
@export var attack_range: float = 50.0
@export var damage: int = 1
@export var patrol_distance: float = 100.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $AttackHitbox
@onready var detection_area: Area2D = $DetectionArea

var current_hp: int
var player_ref: Node = null
var patrol_origin: Vector2 = Vector2.ZERO
var facing_right: bool = true
var is_dead: bool = false

signal died(enemy: EnemyBase)

func _ready() -> void:
	current_hp = max_hp
	patrol_origin = global_position
	hurtbox.hurt.connect(_on_hurt)
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)

func _on_player_detected(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body

func _on_player_lost(body: Node) -> void:
	if body == player_ref:
		player_ref = null

func _on_hurt(dmg: int, knockback: Vector2) -> void:
	if is_dead:
		return
	current_hp -= dmg
	velocity = knockback
	if has_method("update_phase"):
		update_phase()
	if current_hp <= 0:
		is_dead = true
		state_machine.transition_to("EnemyDeadState")
	else:
		state_machine.transition_to("EnemyHurtState")

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func flip_toward(target_x: float) -> void:
	facing_right = target_x > global_position.x
	animated_sprite.flip_h = not facing_right
