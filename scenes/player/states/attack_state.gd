extends PlayerState
class_name AttackState

var _combo_timer: float = 0.0
const COMBO_WINDOW := 0.5
var _attack_done: bool = false

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("attack1")
	player.hitbox.monitoring = true
	_combo_timer = COMBO_WINDOW
	_attack_done = false
	player.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	_attack_done = true
	player.hitbox.monitoring = false

func exit() -> void:
	player.hitbox.monitoring = false
	if player.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		player.animated_sprite.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()

	if _attack_done:
		_combo_timer -= delta
		if Input.is_action_just_pressed("attack") and _combo_timer > 0:
			state_machine.transition_to("AttackCombo2State")
			return
		if _combo_timer <= 0:
			state_machine.transition_to("IdleState")
			return
