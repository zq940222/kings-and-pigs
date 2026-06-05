extends CanvasLayer
class_name SceneTransition

@onready var rect: ColorRect = $ColorRect
@onready var anim: AnimationPlayer = $ColorRect/AnimationPlayer

func fade_in() -> void:
	anim.play("fade_in")
	await anim.animation_finished

func fade_out() -> void:
	anim.play("fade_out")
	await anim.animation_finished
