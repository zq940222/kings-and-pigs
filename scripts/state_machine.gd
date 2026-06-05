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
	if not initial_state.is_empty():
		current_state = get_node_or_null(initial_state)
		if not current_state:
			push_error("StateMachine: initial_state path is invalid: " + str(initial_state))
			return
		call_deferred("_enter_initial_state")

func _enter_initial_state() -> void:
	current_state.enter({})

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
