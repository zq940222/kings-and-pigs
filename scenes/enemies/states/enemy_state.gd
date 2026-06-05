extends Node
class_name EnemyState

var state_machine: StateMachine = null
var enemy: EnemyBase = null

func _ready() -> void:
	enemy = owner as EnemyBase

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
