extends Node

signal sensitivity_changed(value : float)
signal fov_changed(value : float)

signal rewinding(value : bool)
signal ambient_aging(value : float)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Rewind"):
		rewinding.emit(true)
	if event.is_action_released("Rewind"): rewinding.emit(false)
	
