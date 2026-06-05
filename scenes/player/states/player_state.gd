extends Node
class_name PlayerState

var state_machine: StateMachine = null
var player: Player = null

func _ready() -> void:
	player = owner as Player

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
