extends Node
class_name AgingComponent

signal age_increased(current_age: float)
signal max_age_reached()


@export var max_age: float = 100.0
@export var aging_multiplier: float = 1.0 
@export var current_age: float = 0.0:
	set(value):
		_age_changed(value)
		
		current_age = value
		if current_age > max_age:
			current_age = max_age



func increase_age(delta: float, multiplier : float = 1):
	current_age += delta * multiplier * 0.01



func _age_changed(value : float):
	
	#current_age variable in this func is the value before the change was made
	
	pass
