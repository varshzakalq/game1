@abstract

extends Node
class_name Sphere_control_base

@onready var main_body = owner
@onready var Detection_node = main_body.get_node("Detection")
@onready var Health_node = main_body.get_node("Components/Health")

@abstract func _when_target_detected(delta : float)

func _process(delta: float) -> void:
	if main_body.Target != null:
		_when_target_detected(delta)
