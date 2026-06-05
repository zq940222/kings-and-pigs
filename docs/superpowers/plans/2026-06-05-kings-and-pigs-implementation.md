# Kings and Pigs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete 2D Metroidvania game using Kings and Pigs pixel art assets in Godot 4.6, with 4 explorable areas, depth combat (attack/block/roll), 4 unlockable skills, boss fights, and a full save/load system.

**Architecture:** Player and enemies use state-machine-driven `CharacterBody2D` nodes. Rooms are independent Scenes connected via `RoomTransition` Area2D nodes managed by `GameManager`. `SaveManager` and `GameManager` are Autoload singletons. Hitboxes and hurtboxes are `Area2D` children for decoupled damage detection.

**Tech Stack:** Godot 4.6, GDScript, CharacterBody2D, AnimatedSprite2D, Area2D (hitboxes/hurtboxes), JSON save files (`user://save.json`), Autoload singletons.

---

## File Map

```
scripts/
  game_manager.gd          # Autoload: state machine, scene switch, event bus
  save_manager.gd          # Autoload: read/write user://save.json
  state_machine.gd         # Reusable state machine node
  hitbox.gd                # Area2D: deals damage on body_entered
  hurtbox.gd               # Area2D: receives damage, emits hurt signal

scenes/player/
  player.tscn + player.gd
  states/
    player_state.gd        # Base state class
    idle_state.gd
    run_state.gd
    jump_state.gd
    fall_state.gd
    attack_state.gd
    attack_combo2_state.gd
    attack_combo3_state.gd
    block_state.gd
    roll_state.gd
    hurt_state.gd
    dead_state.gd

scenes/enemies/
  enemy_base.gd            # Base class (not a scene)
  states/
    enemy_state.gd
    patrol_state.gd
    chase_state.gd
    enemy_attack_state.gd
    enemy_hurt_state.gd
    enemy_dead_state.gd
  pig/pig.tscn + pig.gd
  box_pig/box_pig.tscn + box_pig.gd
  bomb_pig/bomb_pig.tscn + bomb_pig.gd + bomb.tscn + bomb.gd
  king_pig/king_pig.tscn + king_pig.gd

scenes/world/
  room_transition.gd       # Area2D: triggers scene change
  save_point.tscn + save_point.gd
  crown_fragment.tscn + crown_fragment.gd
  area_gate.tscn + area_gate.gd
  area1/ (6 .tscn room files)
  area2/ (6 .tscn room files)
  area3/ (6 .tscn room files)
  area4/ (6 .tscn room files)

resources/
  skill_resource.gd        # Custom Resource class
  skills/roll_upgrade.tres
  skills/double_jump.tres
  skills/shockwave.tres
  skills/kings_aura.tres

scenes/ui/
  hud.tscn + hud.gd
  main_menu.tscn + main_menu.gd
  pause_menu.tscn + pause_menu.gd
  death_screen.tscn + death_screen.gd
  transition.tscn + transition.gd
```

---

## Task 1: 项目结构、输入映射与 Autoload 注册

**Files:**
- Modify: `project.godot`
- Create: `scripts/game_manager.gd`
- Create: `scripts/save_manager.gd`

- [ ] **Step 1: 下载素材包**

前往 https://pixelfrog-assets.itch.io/kings-and-pigs 下载免费素材包，解压后将所有 PNG 图片放入 `assets/sprites/` 目录（按角色分子目录：`player/`、`enemies/`、`ui/`、`tiles/`）。

- [ ] **Step 2: 创建目录结构**

在 Godot 文件系统面板或资源管理器中创建以下目录：
```
scenes/player/states/
scenes/enemies/states/
scenes/enemies/pig/
scenes/enemies/box_pig/
scenes/enemies/bomb_pig/
scenes/enemies/king_pig/
scenes/world/area1/
scenes/world/area2/
scenes/world/area3/
scenes/world/area4/
scenes/ui/
scripts/
resources/skills/
assets/sprites/player/
assets/sprites/enemies/
assets/sprites/ui/
assets/sprites/tiles/
assets/audio/
docs/superpowers/specs/
docs/superpowers/plans/
```

- [ ] **Step 3: 配置输入映射**

打开 Project → Project Settings → Input Map，添加以下动作：

| Action Name | Key |
|-------------|-----|
| `move_left` | A, Left Arrow |
| `move_right` | D, Right Arrow |
| `jump` | Space |
| `attack` | J |
| `block` | K |
| `roll` | L |
| `skill` | Shift + J |
| `pause` | Escape |
| `interact` | F |

- [ ] **Step 4: 创建 GameManager**

创建 `scripts/game_manager.gd`：

```gdscript
extends Node

signal player_died
signal area_unlocked(area_id: int)
signal skill_unlocked(skill_id: String)
signal boss_defeated(boss_id: String)

enum GameState { MAIN_MENU, PLAYING, PAUSED, DEAD, TRANSITIONING }

var current_state: GameState = GameState.MAIN_MENU
var current_room: String = ""
var player_ref: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_room(target_scene_path: String, spawn_point_name: String = "SpawnPoint") -> void:
	current_state = GameState.TRANSITIONING
	current_room = target_scene_path
	get_tree().change_scene_to_file(target_scene_path)

func set_state(new_state: GameState) -> void:
	current_state = new_state
	if new_state == GameState.PAUSED:
		get_tree().paused = true
	elif new_state == GameState.PLAYING:
		get_tree().paused = false

func register_player(player: Node) -> void:
	player_ref = player
```

- [ ] **Step 5: 创建 SaveManager**

创建 `scripts/save_manager.gd`：

```gdscript
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
```

- [ ] **Step 6: 注册 Autoload**

打开 Project → Project Settings → Globals，添加：
- `GameManager` → `scripts/game_manager.gd`（启用）
- `SaveManager` → `scripts/save_manager.gd`（启用）

- [ ] **Step 7: 手动测试**

运行项目（F5），确认无脚本报错，在调试控制台执行：
```
SaveManager.save()
SaveManager.load_save()
print(SaveManager.save_data)
```
预期输出：`{ "current_area": 1, "last_save_point": "area1_save1", ... }`

- [ ] **Step 8: 提交**

```
git add scripts/ project.godot
git commit -m "feat: add GameManager and SaveManager autoloads, configure input map"
```

---

## Task 2: StateMachine 基础组件、Hitbox / Hurtbox

**Files:**
- Create: `scripts/state_machine.gd`
- Create: `scripts/hitbox.gd`
- Create: `scripts/hurtbox.gd`

- [ ] **Step 1: 创建 StateMachine**

创建 `scripts/state_machine.gd`：

```gdscript
extends Node
class_name StateMachine

@export var initial_state: NodePath = ""

var current_state: Node = null
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child.has_method("enter"):
			states[child.name] = child
			child.state_machine = self
	if initial_state != "":
		current_state = get_node(initial_state)
		current_state.enter()

func transition_to(state_name: String, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("StateMachine: state not found: " + state_name)
		return
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter(msg)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
```

- [ ] **Step 2: 创建 Hitbox（攻击判定框）**

创建 `scripts/hitbox.gd`：

```gdscript
extends Area2D
class_name Hitbox

@export var damage: int = 1
@export var knockback_force: float = 200.0
@export var knockback_direction: Vector2 = Vector2.RIGHT

var owner_node: Node = null

func _ready() -> void:
	collision_layer = 4   # layer 3: hitboxes
	collision_mask = 8    # layer 4: hurtboxes
	monitoring = false    # disabled by default, enabled during attack frames
```

- [ ] **Step 3: 创建 Hurtbox（受击判定框）**

创建 `scripts/hurtbox.gd`：

```gdscript
extends Area2D
class_name Hurtbox

signal hurt(damage: int, knockback: Vector2)

@export var invincible: bool = false

func _ready() -> void:
	collision_layer = 8   # layer 4: hurtboxes
	collision_mask = 4    # layer 3: hitboxes
	area_entered.connect(_on_hitbox_entered)

func _on_hitbox_entered(hitbox: Area2D) -> void:
	if invincible:
		return
	if not hitbox is Hitbox:
		return
	var kb_dir := (global_position - hitbox.global_position).normalized()
	var knockback := kb_dir * hitbox.knockback_force
	hurt.emit(hitbox.damage, knockback)
```

- [ ] **Step 4: 手动测试**

打开 Godot，创建测试场景：
- 添加一个 `Node2D`
- 附加 `StateMachine` 子节点
- 运行，确认无错误

- [ ] **Step 5: 提交**

```
git add scripts/state_machine.gd scripts/hitbox.gd scripts/hurtbox.gd
git commit -m "feat: add StateMachine, Hitbox, and Hurtbox base components"
```

---

## Task 3: 玩家基础移动（Idle / Run / Jump / Fall 状态）

**Files:**
- Create: `scenes/player/player.gd`
- Create: `scenes/player/player.tscn`
- Create: `scenes/player/states/player_state.gd`
- Create: `scenes/player/states/idle_state.gd`
- Create: `scenes/player/states/run_state.gd`
- Create: `scenes/player/states/jump_state.gd`
- Create: `scenes/player/states/fall_state.gd`

- [ ] **Step 1: 创建 PlayerState 基类**

创建 `scenes/player/states/player_state.gd`：

```gdscript
extends Node
class_name PlayerState

var state_machine: StateMachine = null
var player: CharacterBody2D = null

func _ready() -> void:
	await owner.ready
	player = owner as CharacterBody2D

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
```

- [ ] **Step 2: 创建 Player 主脚本**

创建 `scenes/player/player.gd`：

```gdscript
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
	GameManager.register_player(self)
	hurtbox.hurt.connect(_on_hurt)
	_load_skills_from_save()
	GameManager.skill_unlocked.connect(func(_id): _load_skills_from_save())

func _load_skills_from_save() -> void:
	can_double_jump = SaveManager.has_skill("double_jump")
	has_roll_upgrade = SaveManager.has_skill("roll_upgrade")
	has_shockwave = SaveManager.has_skill("shockwave")
	has_kings_aura = SaveManager.has_skill("kings_aura")

# 在 _ready 末尾添加，确保 Boss 死亡解锁技能后本帧立即生效
# GameManager.skill_unlocked.connect(func(_id): _load_skills_from_save())

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
```

- [ ] **Step 3: 创建 IdleState**

创建 `scenes/player/states/idle_state.gd`：

```gdscript
extends PlayerState
class_name IdleState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("idle")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.regen_stamina(delta)
	player.velocity.x = 0.0
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to("FallState")
		return
	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("JumpState")
		return
	if player.get_input_direction() != 0:
		state_machine.transition_to("RunState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
	if Input.is_action_pressed("block"):
		state_machine.transition_to("BlockState")
		return
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("RollState")
		return
```

- [ ] **Step 4: 创建 RunState**

创建 `scenes/player/states/run_state.gd`：

```gdscript
extends PlayerState
class_name RunState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("run")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.regen_stamina(delta)

	var dir := player.get_input_direction()
	player.velocity.x = dir * Player.SPEED
	player.flip_sprite(dir)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to("FallState")
		return
	if dir == 0:
		state_machine.transition_to("IdleState")
		return
	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("JumpState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("RollState")
		return
```

- [ ] **Step 5: 创建 JumpState**

创建 `scenes/player/states/jump_state.gd`：

```gdscript
extends PlayerState
class_name JumpState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("jump")
	player.velocity.y = Player.JUMP_VELOCITY
	player.has_double_jumped = false

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.regen_stamina(delta)

	var dir := player.get_input_direction()
	player.velocity.x = dir * Player.SPEED
	player.flip_sprite(dir)
	player.move_and_slide()

	if player.can_double_jump and not player.has_double_jumped and Input.is_action_just_pressed("jump"):
		player.velocity.y = Player.JUMP_VELOCITY
		player.has_double_jumped = true
		player.animated_sprite.play("jump")
		return

	if player.velocity.y >= 0:
		state_machine.transition_to("FallState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
```

- [ ] **Step 6: 创建 FallState**

创建 `scenes/player/states/fall_state.gd`：

```gdscript
extends PlayerState
class_name FallState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("fall")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.regen_stamina(delta)

	var dir := player.get_input_direction()
	player.velocity.x = dir * Player.SPEED
	player.flip_sprite(dir)
	player.move_and_slide()

	if player.can_double_jump and not player.has_double_jumped and Input.is_action_just_pressed("jump"):
		player.velocity.y = Player.JUMP_VELOCITY
		player.has_double_jumped = true
		player.animated_sprite.play("jump")
		state_machine.transition_to("JumpState")
		return

	if player.is_on_floor():
		if player.get_input_direction() != 0:
			state_machine.transition_to("RunState")
		else:
			state_machine.transition_to("IdleState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
```

- [ ] **Step 7: 在 Godot 编辑器中搭建 Player 场景**

打开 Godot，新建场景，保存为 `scenes/player/player.tscn`：

节点树：
```
Player (CharacterBody2D) [script: player.gd]
├── AnimatedSprite2D        [配置国王动画帧: idle/run/jump/fall]
├── CollisionShape2D        [CapsuleShape2D，符合角色尺寸]
├── StateMachine [script: state_machine.gd, initial_state: IdleState]
│   ├── IdleState [script: idle_state.gd]
│   ├── RunState [script: run_state.gd]
│   ├── JumpState [script: jump_state.gd]
│   └── FallState [script: fall_state.gd]
├── Hurtbox (Area2D) [script: hurtbox.gd]
│   └── CollisionShape2D
└── AttackHitbox (Area2D) [script: hitbox.gd, damage=1, monitoring=false]
    └── CollisionShape2D
```

AnimatedSprite2D 配置：
- 在 SpriteFrames 中为 `idle`、`run`、`jump`、`fall` 各创建动画
- 导入 `assets/sprites/player/` 下的对应帧图片
- 设置合适的 FPS（8-12）

- [ ] **Step 8: 创建测试房间，验证移动**

新建场景 `scenes/world/test_room.tscn`：
```
Node2D
├── TileMapLayer [添加几个地面砖块]
└── Player [实例化 player.tscn]
```

运行（F5），验证：
- ✅ 角色可左右移动，动画切换正常
- ✅ 跳跃可正常起跳和落地
- ✅ 静止时播放 idle，移动时播放 run

- [ ] **Step 9: 提交**

```
git add scenes/player/ scripts/state_machine.gd
git commit -m "feat: add player movement with idle/run/jump/fall state machine"
```

---

## Task 4: 玩家战斗系统（Attack 三连击 / Block / Roll / Hurt / Dead）

**Files:**
- Create: `scenes/player/states/attack_state.gd`
- Create: `scenes/player/states/attack_combo2_state.gd`
- Create: `scenes/player/states/attack_combo3_state.gd`
- Create: `scenes/player/states/block_state.gd`
- Create: `scenes/player/states/roll_state.gd`
- Create: `scenes/player/states/hurt_state.gd`
- Create: `scenes/player/states/dead_state.gd`

- [ ] **Step 1: 创建 AttackState**

创建 `scenes/player/states/attack_state.gd`：

```gdscript
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
```

- [ ] **Step 2: 创建 AttackCombo2State**

创建 `scenes/player/states/attack_combo2_state.gd`：

```gdscript
extends PlayerState
class_name AttackCombo2State

var _combo_timer: float = 0.0
const COMBO_WINDOW := 0.5
var _attack_done: bool = false

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("attack2")
	player.hitbox.monitoring = true
	_combo_timer = COMBO_WINDOW
	_attack_done = false
	player.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	_attack_done = true
	player.hitbox.monitoring = false

func exit() -> void:
	player.hitbox.monitoring = false

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()

	if _attack_done:
		_combo_timer -= delta
		if Input.is_action_just_pressed("attack") and _combo_timer > 0:
			state_machine.transition_to("AttackCombo3State")
			return
		if _combo_timer <= 0:
			state_machine.transition_to("IdleState")
			return
```

- [ ] **Step 3: 创建 AttackCombo3State**

创建 `scenes/player/states/attack_combo3_state.gd`：

```gdscript
extends PlayerState
class_name AttackCombo3State

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("attack3")
	player.hitbox.monitoring = true
	player.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	player.hitbox.monitoring = false
	state_machine.transition_to("IdleState")

func exit() -> void:
	player.hitbox.monitoring = false

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
```

- [ ] **Step 4: 创建 BlockState**

创建 `scenes/player/states/block_state.gd`：

```gdscript
extends PlayerState
class_name BlockState

const BLOCK_DAMAGE_REDUCTION := 0.8

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("block")
	_apply_block(true)

func exit() -> void:
	_apply_block(false)

func _apply_block(blocking: bool) -> void:
	# Hurtbox receives damage, but player.take_damage checks is_blocking
	player.set_meta("is_blocking", blocking)

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
	player.regen_stamina(delta)

	if not Input.is_action_pressed("block"):
		state_machine.transition_to("IdleState")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to("AttackState")
		return
```

- [ ] **Step 5: 修改 player.gd 的 take_damage，支持格挡减伤**

打开 `scenes/player/player.gd`，将 `take_damage` 函数替换为：

```gdscript
func take_damage(damage: int, knockback: Vector2) -> void:
	if is_invincible:
		return
	var facing_attacker := knockback.x * (1.0 if facing_right else -1.0) < 0
	var is_blocking: bool = get_meta("is_blocking", false)
	if is_blocking and facing_attacker:
		damage = int(damage * 0.2)  # 80% damage reduction
	current_hp -= damage
	current_hp = max(current_hp, 0)
	hp_changed.emit(current_hp)
	velocity = knockback
	if current_hp <= 0:
		state_machine.transition_to("DeadState")
	else:
		state_machine.transition_to("HurtState")
```

- [ ] **Step 6: 创建 RollState**

创建 `scenes/player/states/roll_state.gd`：

```gdscript
extends PlayerState
class_name RollState

const ROLL_DURATION_BASE := 0.4
const ROLL_DURATION_UPGRADED := 0.6
const ROLL_SPEED_BASE := 350.0
const ROLL_SPEED_UPGRADED := 500.0

var _roll_dir: float = 1.0
var _roll_timer: float = 0.0
var _roll_duration: float = ROLL_DURATION_BASE
var _roll_speed: float = ROLL_SPEED_BASE

func enter(_msg: Dictionary = {}) -> void:
	if not player.use_stamina(Player.ROLL_STAMINA_COST):
		state_machine.transition_to("IdleState")
		return
	_roll_dir = 1.0 if player.facing_right else -1.0
	_roll_duration = ROLL_DURATION_UPGRADED if player.has_roll_upgrade else ROLL_DURATION_BASE
	_roll_speed = ROLL_SPEED_UPGRADED if player.has_roll_upgrade else ROLL_SPEED_BASE
	_roll_timer = _roll_duration
	player.set_invincible(true)
	player.animated_sprite.play("roll")

func exit() -> void:
	player.set_invincible(false)

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = _roll_dir * _roll_speed
	player.move_and_slide()
	_roll_timer -= delta
	if _roll_timer <= 0:
		state_machine.transition_to("IdleState")
```

- [ ] **Step 7: 创建 HurtState**

创建 `scenes/player/states/hurt_state.gd`：

```gdscript
extends PlayerState
class_name HurtState

const HURT_DURATION := 0.4

var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("hurt")
	player.set_invincible(true)
	_timer = HURT_DURATION

func exit() -> void:
	player.set_invincible(false)

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()
	_timer -= delta
	if _timer <= 0:
		state_machine.transition_to("IdleState")
```

- [ ] **Step 8: 创建 DeadState**

创建 `scenes/player/states/dead_state.gd`：

```gdscript
extends PlayerState
class_name DeadState

func enter(_msg: Dictionary = {}) -> void:
	player.animated_sprite.play("dead")
	player.set_invincible(true)
	player.velocity = Vector2.ZERO
	player.animated_sprite.animation_finished.connect(_on_dead_animation_finished, CONNECT_ONE_SHOT)
	GameManager.set_state(GameManager.GameState.DEAD)

func _on_dead_animation_finished() -> void:
	player.player_died.emit()
	GameManager.player_died.emit()
```

- [ ] **Step 9: 在 Player 场景中添加战斗状态节点**

打开 `scenes/player/player.tscn`，在 `StateMachine` 下添加：
```
├── AttackState [script: attack_state.gd]
├── AttackCombo2State [script: attack_combo2_state.gd]
├── AttackCombo3State [script: attack_combo3_state.gd]
├── BlockState [script: block_state.gd]
├── RollState [script: roll_state.gd]
├── HurtState [script: hurt_state.gd]
└── DeadState [script: dead_state.gd]
```

在 AnimatedSprite2D 的 SpriteFrames 中添加动画：`attack1`、`attack2`、`attack3`、`block`、`roll`、`hurt`、`dead`（导入对应帧）

AttackHitbox 的 CollisionShape2D 放置在角色前方，宽约 32px。

- [ ] **Step 10: 手动测试战斗系统**

运行测试房间，验证：
- ✅ 按 J 播放攻击动画，攻击命中 Hurtbox 区域触发 `hurt` 信号
- ✅ 按 J→J→J 完成三连击，第三击后回到 Idle
- ✅ 按 K 进入格挡姿态，松开 K 退出
- ✅ 按 L（有足够耐力）触发翻滚，0.4s 后自动结束
- ✅ 翻滚期间 Hurtbox.invincible = true

- [ ] **Step 11: 提交**

```
git add scenes/player/states/
git commit -m "feat: add player combat states (attack combo, block, roll, hurt, dead)"
```

---

## Task 5: 敌人系统基类与猪兵（Pig）

**Files:**
- Create: `scenes/enemies/enemy_base.gd`
- Create: `scenes/enemies/states/enemy_state.gd`
- Create: `scenes/enemies/states/patrol_state.gd`
- Create: `scenes/enemies/states/chase_state.gd`
- Create: `scenes/enemies/states/enemy_attack_state.gd`
- Create: `scenes/enemies/states/enemy_hurt_state.gd`
- Create: `scenes/enemies/states/enemy_dead_state.gd`
- Create: `scenes/enemies/pig/pig.tscn` + `pig.gd`

- [ ] **Step 1: 创建 EnemyBase**

创建 `scenes/enemies/enemy_base.gd`：

```gdscript
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
```

- [ ] **Step 2: 创建 EnemyState 基类**

创建 `scenes/enemies/states/enemy_state.gd`：

```gdscript
extends Node
class_name EnemyState

var state_machine: StateMachine = null
var enemy: EnemyBase = null

func _ready() -> void:
	await owner.ready
	enemy = owner as EnemyBase

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
```

- [ ] **Step 3: 创建 PatrolState**

创建 `scenes/enemies/states/patrol_state.gd`：

```gdscript
extends EnemyState
class_name PatrolState

var _direction: float = 1.0

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("run")

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.velocity.x = _direction * enemy.move_speed
	enemy.flip_toward(enemy.global_position.x + _direction)
	enemy.move_and_slide()

	var dist_from_origin := enemy.global_position.x - enemy.patrol_origin.x
	if abs(dist_from_origin) >= enemy.patrol_distance:
		_direction *= -1.0

	if enemy.player_ref != null:
		var dist_to_player := enemy.global_position.distance_to(enemy.player_ref.global_position)
		if dist_to_player <= enemy.detect_range:
			state_machine.transition_to("ChaseState")
```

- [ ] **Step 4: 创建 ChaseState**

创建 `scenes/enemies/states/chase_state.gd`：

```gdscript
extends EnemyState
class_name ChaseState

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("run")

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)

	if enemy.player_ref == null:
		state_machine.transition_to("PatrolState")
		return

	var dir := sign(enemy.player_ref.global_position.x - enemy.global_position.x)
	enemy.velocity.x = dir * enemy.move_speed * 1.3
	enemy.flip_toward(enemy.player_ref.global_position.x)
	enemy.move_and_slide()

	var dist := enemy.global_position.distance_to(enemy.player_ref.global_position)
	if dist <= enemy.attack_range:
		state_machine.transition_to("EnemyAttackState")
	elif dist > enemy.detect_range * 1.5:
		state_machine.transition_to("PatrolState")
```

- [ ] **Step 5: 创建 EnemyAttackState**

创建 `scenes/enemies/states/enemy_attack_state.gd`：

```gdscript
extends EnemyState
class_name EnemyAttackState

const ATTACK_COOLDOWN := 1.2

var _cooldown: float = 0.0
var _attack_done: bool = false

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("attack")
	enemy.hitbox.monitoring = true
	_attack_done = false
	_cooldown = ATTACK_COOLDOWN
	enemy.velocity.x = 0.0
	enemy.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	_attack_done = true
	enemy.hitbox.monitoring = false

func exit() -> void:
	enemy.hitbox.monitoring = false

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.move_and_slide()

	if not _attack_done:
		return
	_cooldown -= delta
	if _cooldown <= 0:
		if enemy.player_ref != null:
			state_machine.transition_to("ChaseState")
		else:
			state_machine.transition_to("PatrolState")
```

- [ ] **Step 6: 创建 EnemyHurtState**

创建 `scenes/enemies/states/enemy_hurt_state.gd`：

```gdscript
extends EnemyState
class_name EnemyHurtState

const HURT_DURATION := 0.3

var _timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("hurt")
	_timer = HURT_DURATION

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	_timer -= delta
	if _timer <= 0:
		if enemy.player_ref != null:
			state_machine.transition_to("ChaseState")
		else:
			state_machine.transition_to("PatrolState")
```

- [ ] **Step 7: 创建 EnemyDeadState**

创建 `scenes/enemies/states/enemy_dead_state.gd`：

```gdscript
extends EnemyState
class_name EnemyDeadState

func enter(_msg: Dictionary = {}) -> void:
	enemy.animated_sprite.play("dead")
	enemy.set_collision_layer_value(1, false)
	enemy.set_collision_mask_value(1, false)
	enemy.hurtbox.set_deferred("monitoring", false)
	enemy.hitbox.set_deferred("monitoring", false)
	enemy.animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

func _on_death_animation_finished() -> void:
	enemy.died.emit(enemy)
	enemy.queue_free()
```

- [ ] **Step 8: 创建 Pig 敌人**

创建 `scenes/enemies/pig/pig.gd`：

```gdscript
extends EnemyBase

func _ready() -> void:
	max_hp = 3
	move_speed = 80.0
	detect_range = 180.0
	attack_range = 45.0
	damage = 1
	patrol_distance = 80.0
	add_to_group("enemies")
	super._ready()
```

搭建 `scenes/enemies/pig/pig.tscn` 节点树：
```
Pig (CharacterBody2D) [script: pig.gd]
├── AnimatedSprite2D [配置动画: idle/run/attack/hurt/dead]
├── CollisionShape2D [RectangleShape2D]
├── StateMachine [initial_state: PatrolState]
│   ├── PatrolState
│   ├── ChaseState
│   ├── EnemyAttackState
│   ├── EnemyHurtState
│   └── EnemyDeadState
├── Hurtbox (Area2D) [script: hurtbox.gd, layer 8, mask 4]
│   └── CollisionShape2D
├── AttackHitbox (Area2D) [script: hitbox.gd, damage=1, monitoring=false]
│   └── CollisionShape2D [前方矩形]
└── DetectionArea (Area2D) [layer 0, mask 1，圆形 detect_range 半径]
    └── CollisionShape2D [CircleShape2D]
```

- [ ] **Step 9: 手动测试猪兵**

在测试房间实例化一只 Pig，运行游戏，验证：
- ✅ Pig 在巡逻范围内来回移动
- ✅ 玩家靠近触发追击
- ✅ 接近攻击距离时发起攻击
- ✅ 玩家攻击命中 Pig 的 Hurtbox，Pig 进入 Hurt 状态，HP 减少
- ✅ HP 归 0 后播放死亡动画并消失

- [ ] **Step 10: 提交**

```
git add scenes/enemies/
git commit -m "feat: add EnemyBase state machine and Pig enemy"
```

---

## Task 6: BoxPig（盾兵）与 BombPig（炸弹猪）

**Files:**
- Create: `scenes/enemies/box_pig/box_pig.tscn` + `box_pig.gd`
- Create: `scenes/enemies/bomb_pig/bomb_pig.tscn` + `bomb_pig.gd`
- Create: `scenes/enemies/bomb_pig/bomb.tscn` + `bomb.gd`

- [ ] **Step 1: 创建 BoxPig**

创建 `scenes/enemies/box_pig/box_pig.gd`：

```gdscript
extends EnemyBase

var _is_shielding: bool = false

func _ready() -> void:
	max_hp = 5
	move_speed = 60.0
	detect_range = 200.0
	attack_range = 50.0
	damage = 2
	patrol_distance = 60.0
	add_to_group("enemies")
	super._ready()

func _on_hurt(dmg: int, knockback: Vector2) -> void:
	# 正面受击时格挡（面向玩家方向）
	if _is_shielding and player_ref != null:
		var player_on_front := (player_ref.global_position.x > global_position.x) == facing_right
		if player_on_front:
			dmg = 0  # 完全格挡
	super._on_hurt(dmg, knockback)

func set_shielding(value: bool) -> void:
	_is_shielding = value
	if value:
		animated_sprite.play("shield")
	else:
		animated_sprite.play("idle")
```

- [ ] **Step 2: 创建 BoxPig 特殊 ChaseState**

BoxPig 在移动时会举盾，在 `box_pig.tscn` 中覆写 ChaseState，在 `enter()` 调用 `enemy.set_shielding(true)`，`exit()` 时调用 `enemy.set_shielding(false)`。（场景内创建继承自 ChaseState 的内联脚本节点即可。）

搭建 `scenes/enemies/box_pig/box_pig.tscn`（与 pig.tscn 结构相同，脚本换为 box_pig.gd，动画帧换为盾兵素材）。

- [ ] **Step 3: 创建 Bomb（炸弹）**

创建 `scenes/enemies/bomb_pig/bomb.gd`：

```gdscript
extends Area2D
class_name Bomb

const GRAVITY := 980.0
const EXPLOSION_RADIUS := 60.0
const FUSE_TIME := 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_area: Area2D = $ExplosionArea

var velocity: Vector2 = Vector2.ZERO
var _fuse_timer: float = FUSE_TIME

func launch(direction: Vector2, speed: float) -> void:
	velocity = direction * speed

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	_fuse_timer -= delta
	if _fuse_timer <= 0:
		_explode()

func _explode() -> void:
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(2, (body.global_position - global_position).normalized() * 300)
	queue_free()
```

搭建 `scenes/enemies/bomb_pig/bomb.tscn`：
```
Bomb (Area2D) [script: bomb.gd]
├── Sprite2D [炸弹图片]
└── ExplosionArea (Area2D)
    └── CollisionShape2D [CircleShape2D, radius=60]
```

- [ ] **Step 4: 创建 BombPig**

创建 `scenes/enemies/bomb_pig/bomb_pig.gd`：

```gdscript
extends EnemyBase

const BOMB_SCENE := preload("res://scenes/enemies/bomb_pig/bomb.tscn")
const THROW_COOLDOWN := 3.0
const THROW_SPEED := 250.0
const SAFE_DISTANCE := 150.0

var _throw_timer: float = 0.0

func _ready() -> void:
	max_hp = 4
	move_speed = 60.0
	detect_range = 280.0
	attack_range = 200.0
	damage = 2
	patrol_distance = 80.0
	add_to_group("enemies")
	super._ready()

func throw_bomb() -> void:
	if player_ref == null:
		return
	var bomb := BOMB_SCENE.instantiate()
	get_parent().add_child(bomb)
	bomb.global_position = global_position + Vector2(30 * (1 if facing_right else -1), -20)
	var target_dir := (player_ref.global_position - bomb.global_position).normalized()
	bomb.launch(target_dir, THROW_SPEED)
	_throw_timer = THROW_COOLDOWN
```

BombPig 的 `EnemyAttackState` 调用 `enemy.throw_bomb()` 替代近战。搭建 `bomb_pig.tscn`（结构同 pig.tscn）。

- [ ] **Step 5: 手动测试**

运行游戏，放置 BoxPig 和 BombPig 到测试房间：
- ✅ BoxPig 正面受击无效，绕后攻击可造成伤害
- ✅ BombPig 向玩家方向抛出炸弹，炸弹落地/到时爆炸

- [ ] **Step 6: 提交**

```
git add scenes/enemies/box_pig/ scenes/enemies/bomb_pig/
git commit -m "feat: add BoxPig (shield) and BombPig (ranged) enemy types"
```

---

## Task 7: 房间系统与场景切换

**Files:**
- Create: `scenes/world/room_transition.gd`
- Create: `scenes/world/area1/area1_room1.tscn`（其余 room 场景类似）

- [ ] **Step 1: 创建 RoomTransition 脚本**

创建 `scenes/world/room_transition.gd`：

```gdscript
extends Area2D
class_name RoomTransition

@export var target_scene: String = ""
@export var spawn_point_name: String = "SpawnPoint"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if target_scene == "":
		push_error("RoomTransition: target_scene is empty!")
		return
	SaveManager.mark_room_explored(target_scene)
	GameManager.change_room(target_scene, spawn_point_name)
```

- [ ] **Step 2: 创建过渡动画场景**

创建 `scenes/ui/transition.tscn`：
```
CanvasLayer
└── ColorRect (全屏黑色, 锚点全覆盖)
    └── [AnimationPlayer: fade_in (0→1 alpha, 0.3s), fade_out (1→0 alpha, 0.3s)]
```

创建 `scenes/ui/transition.gd`：
```gdscript
extends CanvasLayer

@onready var rect: ColorRect = $ColorRect
@onready var anim: AnimationPlayer = $ColorRect/AnimationPlayer

func fade_in() -> void:
	anim.play("fade_in")
	await anim.animation_finished

func fade_out() -> void:
	anim.play("fade_out")
	await anim.animation_finished
```

修改 `scripts/game_manager.gd` 中 `change_room` 函数，加入过渡动画（需 Transition 单例或作为场景子节点）。

- [ ] **Step 3: 搭建 Area1 Room1（教学房间）**

创建 `scenes/world/area1/area1_room1.tscn`：

```
Node2D [room_id: "area1_room1"]
├── TileMapLayer [砖块地形，使用 Kings and Pigs 瓦片素材]
├── SpawnPoint (Marker2D) [玩家出生点]
├── Player [实例化 player.tscn]
├── HUD [实例化 hud.tscn]
├── Camera2D [跟随 Player, limit 设置为房间边界]
├── Pig × 2 [巡逻敌人]
├── ExitDoor_Right (Area2D) [script: room_transition.gd]
│   ├── target_scene: "res://scenes/world/area1/area1_room2.tscn"
│   └── CollisionShape2D [门口区域]
└── SavePoint_1 [实例化 save_point.tscn]
```

Room1 作为教学关：地形平坦，1-2 只猪兵，存档点在左侧。

- [ ] **Step 4: 搭建 Area1 剩余 5 个房间**

按同样方式创建 `area1_room2.tscn` 至 `area1_room6.tscn`，每个房间：
- 地形渐进增加跳台挑战
- Room6 为 Boss 房间（空旷大房间）
- 每个房间右侧/上方设置 `RoomTransition`，左侧/下方设置回上一房间的 `RoomTransition`

- [ ] **Step 5: 手动测试房间切换**

运行 area1_room1.tscn，走到右侧出口，验证：
- ✅ 黑色淡出/淡入过渡
- ✅ 进入 area1_room2，玩家在 SpawnPoint 出生
- ✅ 返回左侧回到 area1_room1

- [ ] **Step 6: 提交**

```
git add scenes/world/ scenes/ui/transition.tscn scenes/ui/transition.gd
git commit -m "feat: add room transition system and Area 1 rooms"
```

---

## Task 8: 存档点与 KingPig Boss

**Files:**
- Create: `scenes/world/save_point.tscn` + `save_point.gd`
- Create: `scenes/enemies/king_pig/king_pig.tscn` + `king_pig.gd`

- [ ] **Step 1: 创建存档点**

创建 `scenes/world/save_point.gd`：

```gdscript
extends Area2D

@export var save_point_id: String = "save_point_1"

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_do_save(body)

func _do_save(player: Node) -> void:
	player.current_hp = player.max_hp
	player.hp_changed.emit(player.current_hp)
	SaveManager.save_data["last_save_point"] = save_point_id
	SaveManager.save_data["player_hp"] = player.current_hp
	SaveManager.save()
	anim.play("saved_flash")
```

搭建 `save_point.tscn`（王座/壁炉 Sprite + Area2D + AnimationPlayer 显示存档提示）。

- [ ] **Step 2: 创建 KingPig Boss**

创建 `scenes/enemies/king_pig/king_pig.gd`：

```gdscript
extends EnemyBase

enum Phase { ONE, TWO, THREE }

var current_phase: Phase = Phase.ONE
var _minion_spawned: bool = false

@export var boss_id: String = "boss_area1"
@export var skill_reward: String = "roll_upgrade"

const PIG_SCENE := preload("res://scenes/enemies/pig/pig.tscn")

func _ready() -> void:
	max_hp = 20
	move_speed = 100.0
	detect_range = 400.0
	attack_range = 60.0
	damage = 2
	patrol_distance = 0.0
	add_to_group("enemies")
	add_to_group("boss")
	super._ready()
	died.connect(_on_boss_died)

func update_phase() -> void:
	var hp_percent := float(current_hp) / float(max_hp)
	if hp_percent <= 0.3 and current_phase != Phase.THREE:
		current_phase = Phase.THREE
		move_speed = 140.0
	elif hp_percent <= 0.6 and current_phase == Phase.ONE:
		current_phase = Phase.TWO
		if not _minion_spawned:
			_spawn_minions()
			_minion_spawned = true

func _spawn_minions() -> void:
	for i in 2:
		var minion := PIG_SCENE.instantiate()
		get_parent().add_child(minion)
		minion.global_position = global_position + Vector2(randf_range(-100, 100), 0)

func _on_boss_died(_enemy: EnemyBase) -> void:
	SaveManager.mark_boss_defeated(boss_id)
	SaveManager.unlock_skill(skill_reward)
	SaveManager.save()
	GameManager.boss_defeated.emit(boss_id)
	GameManager.skill_unlocked.emit(skill_reward)
```

- [ ] **Step 3: Boss 受伤时更新阶段**

在 `enemy_base.gd` 的 `_on_hurt` 中，如果 enemy 有 `update_phase` 方法则调用：

```gdscript
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
```

- [ ] **Step 4: 搭建 Boss 场景并放入 Room6**

创建 `king_pig.tscn`（结构同 pig.tscn，使用国王猪素材），放入 `area1_room6.tscn` 中央。

- [ ] **Step 5: 手动测试 Boss**

运行，进入 Room6，验证：
- ✅ Boss 阶段 2（60% 血）时召唤 2 只猪兵
- ✅ 阶段 3（30% 血）时速度加快
- ✅ 击败 Boss 后 SaveManager 记录 `boss_area1` 已击败，`roll_upgrade` 已解锁

- [ ] **Step 6: 提交**

```
git add scenes/world/save_point.tscn scenes/world/save_point.gd scenes/enemies/king_pig/
git commit -m "feat: add SavePoint interaction and KingPig Boss with 3-phase combat"
```

---

## Task 9: 技能系统（SkillResource + 4 技能）

**Files:**
- Create: `resources/skill_resource.gd`
- Create: `resources/skills/roll_upgrade.tres`
- Create: `resources/skills/double_jump.tres`
- Create: `resources/skills/shockwave.tres`
- Create: `resources/skills/kings_aura.tres`
- Create: `scenes/world/crown_fragment.tscn` + `crown_fragment.gd`

- [ ] **Step 1: 创建 SkillResource**

创建 `resources/skill_resource.gd`：

```gdscript
extends Resource
class_name SkillResource

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
```

- [ ] **Step 2: 创建 4 个技能资源文件**

在 Godot 编辑器中，新建 Resource → 选择 SkillResource，保存并填写属性：

`resources/skills/roll_upgrade.tres`：
- `skill_id`: `"roll_upgrade"`
- `display_name`: `"翻滚强化"`
- `description`: `"翻滚距离+50%，无敌帧延长至0.6秒"`

`resources/skills/double_jump.tres`：
- `skill_id`: `"double_jump"`
- `display_name`: `"二段跳"`
- `description`: `"空中可再跳一次"`

`resources/skills/shockwave.tres`：
- `skill_id`: `"shockwave"`
- `display_name`: `"冲击波斩"`
- `description`: `"释放前向冲击波，可远程命中敌人"`

`resources/skills/kings_aura.tres`：
- `skill_id`: `"kings_aura"`
- `display_name`: `"王者之气"`
- `description`: `"短时无敌并震慑场景内所有敌人"`

- [ ] **Step 3: 实现冲击波技能**

在 `scenes/player/player.gd` 中添加冲击波投射物：

```gdscript
const SHOCKWAVE_SCENE := preload("res://scenes/player/shockwave.tscn")

func use_skill() -> void:
	if has_shockwave and SaveManager.has_skill("shockwave"):
		_cast_shockwave()
	elif has_kings_aura and SaveManager.has_skill("kings_aura"):
		_cast_kings_aura()

func _cast_shockwave() -> void:
	var wave := SHOCKWAVE_SCENE.instantiate()
	get_parent().add_child(wave)
	wave.global_position = global_position
	wave.direction = Vector2.RIGHT if facing_right else Vector2.LEFT

func _cast_kings_aura() -> void:
	set_invincible(true)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("stun"):
			enemy.stun(2.0)
	await get_tree().create_timer(3.0).timeout
	set_invincible(false)
```

创建 `scenes/player/shockwave.tscn`：
```
Area2D [script: shockwave.gd]
├── Sprite2D [冲击波效果图]
└── CollisionShape2D [细长矩形]
```

创建 `scenes/player/shockwave.gd`：
```gdscript
extends Area2D

var direction: Vector2 = Vector2.RIGHT
const SPEED := 400.0
const DAMAGE := 2

func _ready() -> void:
	body_entered.connect(_on_hit)
	await get_tree().create_timer(0.8).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta

func _on_hit(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.hurtbox.hurt.emit(DAMAGE, direction * 200)
```

- [ ] **Step 4: 在 Idle/Run/Fall 状态中绑定技能按键**

在 `idle_state.gd`、`run_state.gd` 等状态的 `physics_update` 中添加：
```gdscript
if Input.is_action_just_pressed("skill"):
	player.use_skill()
```

- [ ] **Step 5: 创建王冠碎片收集物**

创建 `scenes/world/crown_fragment.gd`：

```gdscript
extends Area2D

@export var fragment_id: String = "fragment_1"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if SaveManager.save_data.get("crown_fragments", []).has(fragment_id):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	SaveManager.collect_crown_fragment(fragment_id)
	if SaveManager.has_all_crown_fragments():
		SaveManager.unlock_skill("kings_aura")
		body.has_kings_aura = true
		GameManager.skill_unlocked.emit("kings_aura")
	queue_free()
```

在 Area1-4 各放置一个 `crown_fragment.tscn`（隐藏在探索位置）。

- [ ] **Step 6: 手动测试技能**

运行游戏，先在调试中手动解锁技能：
```gdscript
SaveManager.unlock_skill("shockwave")
player.has_shockwave = true
```
按 Shift+J，验证：
- ✅ 冲击波向前方飞出
- ✅ 命中敌人 Hurtbox 造成 2 点伤害

- [ ] **Step 7: 提交**

```
git add resources/ scenes/player/shockwave.tscn scenes/player/shockwave.gd scenes/world/crown_fragment.tscn scenes/world/crown_fragment.gd
git commit -m "feat: add SkillResource, 4 unlockable skills, and crown fragments"
```

---

## Task 10: HUD 界面

**Files:**
- Create: `scenes/ui/hud.tscn` + `scenes/ui/hud.gd`

- [ ] **Step 1: 搭建 HUD 场景**

创建 `scenes/ui/hud.tscn`：

```
CanvasLayer
└── MarginContainer (全屏)
    ├── HBoxContainer (左上角，anchor top-left)
    │   ├── TextureRect [王冠图标]
    │   └── HBoxContainer (id: HeartContainer)
    │       └── [6 × TextureRect heart_icon] (动态生成)
    ├── ProgressBar (id: StaminaBar, 右下角)
    └── HBoxContainer (右上角，id: SkillIcons)
        └── [最多 4 × TextureRect skill_icon]
```

- [ ] **Step 2: 创建 HUD 脚本**

创建 `scenes/ui/hud.gd`：

```gdscript
extends CanvasLayer

@onready var heart_container: HBoxContainer = $MarginContainer/HBoxContainer/HeartContainer
@onready var stamina_bar: ProgressBar = $MarginContainer/StaminaBar
@onready var skill_icons: HBoxContainer = $MarginContainer/SkillIcons

const HEART_FULL := preload("res://assets/sprites/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/sprites/ui/heart_empty.png")

var heart_icons: Array[TextureRect] = []

func _ready() -> void:
	_init_hearts(6)
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0

func _init_hearts(count: int) -> void:
	for child in heart_container.get_children():
		child.queue_free()
	heart_icons.clear()
	for i in count:
		var icon := TextureRect.new()
		icon.texture = HEART_FULL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(16, 16)
		heart_container.add_child(icon)
		heart_icons.append(icon)

func update_hp(new_hp: int) -> void:
	for i in heart_icons.size():
		heart_icons[i].texture = HEART_FULL if i < new_hp else HEART_EMPTY

func update_stamina(new_stamina: float) -> void:
	stamina_bar.value = new_stamina

func connect_to_player(player: Node) -> void:
	player.hp_changed.connect(update_hp)
	player.stamina_changed.connect(update_stamina)
	update_hp(player.current_hp)
	update_stamina(player.stamina)
```

- [ ] **Step 3: 在各房间场景中实例化 HUD 并连接**

在每个房间的 `_ready` 中（或通过 GameManager）调用：
```gdscript
$HUD.connect_to_player(GameManager.player_ref)
```

- [ ] **Step 4: 手动测试 HUD**

运行游戏，验证：
- ✅ 左上角显示 6 颗心，受伤后心脏变灰
- ✅ 翻滚后耐力槽减少，自动恢复
- ✅ 治疗后心脏恢复满格

- [ ] **Step 5: 提交**

```
git add scenes/ui/hud.tscn scenes/ui/hud.gd
git commit -m "feat: add HUD with heart HP display and stamina bar"
```

---

## Task 11: 主菜单 / 暂停菜单 / 死亡界面

**Files:**
- Create: `scenes/ui/main_menu.tscn` + `main_menu.gd`
- Create: `scenes/ui/pause_menu.tscn` + `pause_menu.gd`
- Create: `scenes/ui/death_screen.tscn` + `death_screen.gd`

- [ ] **Step 1: 创建主菜单**

创建 `scenes/ui/main_menu.gd`：

```gdscript
extends Control

@onready var continue_btn: Button = $VBoxContainer/ContinueButton

func _ready() -> void:
	continue_btn.disabled = not SaveManager.has_save()

func _on_new_game_pressed() -> void:
	SaveManager.delete_save()
	GameManager.change_room("res://scenes/world/area1/area1_room1.tscn")

func _on_continue_pressed() -> void:
	if SaveManager.load_save():
		var save := SaveManager.save_data
		var scene_path := "res://scenes/world/area1/area1_room1.tscn"
		# 根据 last_save_point 映射到对应场景
		GameManager.change_room(scene_path)

func _on_quit_pressed() -> void:
	get_tree().quit()
```

搭建 `main_menu.tscn`：
```
Control (全屏)
├── TextureRect [背景图片]
└── VBoxContainer (居中)
    ├── Label [游戏标题: "Kings and Pigs"]
    ├── Button (id: NewGameButton) ["新游戏"]
    ├── Button (id: ContinueButton) ["继续游戏"]
    └── Button (id: QuitButton) ["退出"]
```

- [ ] **Step 2: 创建暂停菜单**

创建 `scenes/ui/pause_menu.gd`：

```gdscript
extends Control

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		if visible:
			_on_resume_pressed()
		else:
			_show_pause()

func _show_pause() -> void:
	show()
	GameManager.set_state(GameManager.GameState.PAUSED)

func _on_resume_pressed() -> void:
	hide()
	GameManager.set_state(GameManager.GameState.PLAYING)

func _on_main_menu_pressed() -> void:
	hide()
	get_tree().paused = false
	GameManager.change_room("res://scenes/ui/main_menu.tscn")
```

- [ ] **Step 3: 创建死亡界面**

创建 `scenes/ui/death_screen.gd`：

```gdscript
extends Control

func _ready() -> void:
	hide()
	GameManager.player_died.connect(_on_player_died)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_player_died() -> void:
	show()
	await get_tree().create_timer(1.0).timeout

func _on_retry_pressed() -> void:
	hide()
	var save := SaveManager.save_data
	var last_point: String = save.get("last_save_point", "area1_save1")
	# 根据存档点映射回场景路径
	var scene := _get_scene_for_save_point(last_point)
	get_tree().paused = false
	GameManager.change_room(scene)

func _get_scene_for_save_point(save_point_id: String) -> String:
	var map := {
		"area1_save1": "res://scenes/world/area1/area1_room1.tscn",
		"area1_save2": "res://scenes/world/area1/area1_room3.tscn",
		"area2_save1": "res://scenes/world/area2/area2_room1.tscn",
		"area2_save2": "res://scenes/world/area2/area2_room3.tscn",
		"area3_save1": "res://scenes/world/area3/area3_room1.tscn",
		"area3_save2": "res://scenes/world/area3/area3_room3.tscn",
		"area4_save1": "res://scenes/world/area4/area4_room1.tscn",
		"area4_save2": "res://scenes/world/area4/area4_room3.tscn",
	}
	return map.get(save_point_id, "res://scenes/world/area1/area1_room1.tscn")
```

- [ ] **Step 4: 在 project.godot 设置主场景**

打开 Project → Project Settings → Application → Run，将 `Main Scene` 设置为 `res://scenes/ui/main_menu.tscn`。

- [ ] **Step 5: 手动测试完整流程**

运行游戏，验证：
- ✅ 启动进入主菜单，无存档时"继续游戏"置灰
- ✅ 新游戏进入 area1_room1
- ✅ Esc 开启/关闭暂停菜单，游戏暂停
- ✅ 血量归 0 出现死亡界面
- ✅ 点击重试从最后存档点重新开始，HP 恢复满格

- [ ] **Step 6: 提交**

```
git add scenes/ui/
git commit -m "feat: add main menu, pause menu, and death screen with retry flow"
```

---

## Task 12: 区域封锁门与区域解锁

**Files:**
- Create: `scenes/world/area_gate.tscn` + `area_gate.gd`

- [ ] **Step 1: 创建区域封锁门**

创建 `scenes/world/area_gate.gd`：

```gdscript
extends StaticBody2D

@export var required_skill: String = ""
@export var required_boss: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	_check_unlock()
	GameManager.skill_unlocked.connect(_on_skill_unlocked)
	GameManager.boss_defeated.connect(_on_boss_defeated)

func _check_unlock() -> bool:
	var skill_ok := required_skill == "" or SaveManager.has_skill(required_skill)
	var boss_ok := required_boss == "" or SaveManager.has_defeated_boss(required_boss)
	if skill_ok and boss_ok:
		_unlock()
		return true
	return false

func _on_skill_unlocked(_skill_id: String) -> void:
	_check_unlock()

func _on_boss_defeated(_boss_id: String) -> void:
	_check_unlock()

func _unlock() -> void:
	sprite.hide()
	collision.set_deferred("disabled", true)
	hint_label.hide()
```

搭建 `area_gate.tscn`（封锁门 Sprite + StaticBody2D + 碰撞体 + HintLabel 显示所需条件）。

在 Area1→Area2 的衔接房间放置两个 `AreaGate`：
- 一个要求 `required_boss = "boss_area1"`
- 一个要求 `required_skill = "roll_upgrade"`

- [ ] **Step 2: 手动测试封锁门**

运行游戏，验证：
- ✅ 未击败 Boss 时封锁门阻挡通路
- ✅ 击败 Boss 后封锁门消失，可进入下一区域

- [ ] **Step 3: 提交**

```
git add scenes/world/area_gate.tscn scenes/world/area_gate.gd
git commit -m "feat: add area gate system requiring boss defeat + skill unlock"
```

---

## Task 13: 区域 2-4 内容

**Files:**
- Create: `scenes/world/area2/` (6 rooms)
- Create: `scenes/world/area3/` (6 rooms)
- Create: `scenes/world/area4/` (6 rooms)

- [ ] **Step 1: 搭建 Area 2（猪兵营地）**

创建 6 个房间 `area2_room1.tscn` ~ `area2_room6.tscn`：
- 使用不同颜色/风格的营地瓦片
- Room1-5 放置 Pig 和 BoxPig 敌人
- Room6 为 Boss 战（KingPig，boss_id="boss_area2"，skill_reward="double_jump"）
- 每区域 2 个存档点（room1 和 room4）
- Room 出口接 Area3 入口封锁门（需要 boss_area2 + double_jump）

- [ ] **Step 2: 搭建 Area 3（地下猪窟）**

创建 6 个房间 `area3_room1.tscn` ~ `area3_room6.tscn`：
- 深色岩石瓦片，灯笼光源装饰
- 增加纵向跳台挑战（需要二段跳）
- 加入 BombPig 敌人
- Room6 Boss（KingPig，boss_id="boss_area3"，skill_reward="shockwave"）

- [ ] **Step 3: 搭建 Area 4（猪王城堡）**

创建 6 个房间 `area4_room1.tscn` ~ `area4_room6.tscn`：
- 城堡石砖瓦片
- 所有敌人类型混合
- Room6 最终 Boss（KingPig，boss_id="boss_area4"，skill_reward="" — 游戏通关）
- 最终 Boss 房间战后显示通关画面（通过 GameManager 信号触发）

- [ ] **Step 4: 提交**

```
git add scenes/world/area2/ scenes/world/area3/ scenes/world/area4/
git commit -m "feat: add Areas 2-4 with rooms, enemies, bosses, and save points"
```

---

## Task 14: 音效集成与最终打磨

**Files:**
- Modify: `scenes/player/player.gd`（添加音效调用）
- Create: `assets/audio/` (SFX 文件)

- [ ] **Step 1: 添加 AudioStreamPlayer 到 Player**

在 `player.tscn` 中添加 `AudioStreamPlayer2D` 节点（id: SFXPlayer）。

在 `player.gd` 中添加：
```gdscript
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer

const SFX_ATTACK := preload("res://assets/audio/attack.wav")
const SFX_HURT := preload("res://assets/audio/hurt.wav")
const SFX_JUMP := preload("res://assets/audio/jump.wav")
const SFX_ROLL := preload("res://assets/audio/roll.wav")

func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()
```

在对应状态的 `enter()` 中调用 `player.play_sfx()`。

- [ ] **Step 2: 背景音乐**

在 `game_manager.gd` 中添加 BGM 管理：
```gdscript
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

func play_bgm(stream: AudioStream) -> void:
	if bgm_player.stream == stream:
		return
	bgm_player.stream = stream
	bgm_player.play()
```

每个区域入口房间的 `_ready()` 调用 `GameManager.play_bgm(area_bgm)`。

- [ ] **Step 3: 相机跟随与限制**

确认每个房间的 `Camera2D` 设置了 `limit_left/right/top/bottom` 与房间边界匹配，避免相机越界。

- [ ] **Step 4: Windows 导出配置**

打开 Project → Export，添加 Windows Desktop 导出预设：
- 设置产品名称、版本
- 勾选 Embed PCK
- 导出到 `export/windows/KingsAndPigs.exe`

- [ ] **Step 5: 完整流程通关测试**

从主菜单开始，完整游玩一遍，验证：
- ✅ 主菜单 → Area1 → 击败 Boss → 区域解锁 → Area2 → … → Area4 最终 Boss
- ✅ 存档正确保存和恢复
- ✅ 所有技能效果正常
- ✅ 死亡 → 重试流程正常
- ✅ Windows 可执行文件可直接运行

- [ ] **Step 6: 最终提交**

```
git add .
git commit -m "feat: complete Kings and Pigs Metroidvania with audio and Windows export"
```

---

## 规范覆盖检查

| 规范需求 | 对应任务 |
|----------|----------|
| 玩家移动（SPEED=200, JUMP=380） | Task 3 |
| 三连击攻击 | Task 4 |
| 格挡（80% 减伤）| Task 4 |
| 翻滚（0.4s 无敌帧，耐力 25）| Task 4 |
| 技能释放（Shift+J）| Task 9 |
| 4 种敌人 | Task 5, 6 |
| Boss 三阶段 | Task 8 |
| 4 个区域，各 6 房间 | Task 7, 13 |
| 房间切换（淡入淡出）| Task 7 |
| 存档系统（JSON）| Task 1 |
| 存档点（王座/壁炉）| Task 8 |
| 4 个技能解锁 | Task 9 |
| 王冠碎片收集 | Task 9 |
| 区域封锁门 | Task 12 |
| HUD（心 + 耐力）| Task 10 |
| 主菜单 | Task 11 |
| 暂停菜单 | Task 11 |
| 死亡界面 | Task 11 |
| 音效与 BGM | Task 14 |
| Windows 导出 | Task 14 |
