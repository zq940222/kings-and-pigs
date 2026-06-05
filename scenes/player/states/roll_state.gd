extends PlayerState
class_name RollState

const ROLL_DURATION_BASE := 0.4
const ROLL_DURATION_UPGRADED := 0.6
const ROLL_SPEED_BASE := 350.0
const ROLL_SPEED_UPGRADED := 500.0

var _roll_dir: float = 1.0
var _roll_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	if not player.use_stamina(Player.ROLL_STAMINA_COST):
		state_machine.transition_to("IdleState")
		return
	_roll_dir = 1.0 if player.facing_right else -1.0
	var duration := ROLL_DURATION_UPGRADED if player.has_roll_upgrade else ROLL_DURATION_BASE
	_roll_timer = duration
	player.set_invincible(true)
	player.animated_sprite.play("roll")

func exit() -> void:
	player.set_invincible(false)

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var speed := ROLL_SPEED_UPGRADED if player.has_roll_upgrade else ROLL_SPEED_BASE
	player.velocity.x = _roll_dir * speed
	player.move_and_slide()
	_roll_timer -= delta
	if _roll_timer <= 0:
		state_machine.transition_to("IdleState")
