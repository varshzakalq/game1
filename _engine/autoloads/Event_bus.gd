extends Node

signal rewinding(value : bool)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Rewind"): rewinding.emit(true)
	if event.is_action_released("Rewind"): rewinding.emit(false)
	
