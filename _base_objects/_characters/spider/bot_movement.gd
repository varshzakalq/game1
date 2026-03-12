
extends Node3D #change this to CharacterBody3D

@export var move_speed: float = 5.0
@export var rotate_speed: float = 1.0



#region movment

func _move(dir : Vector2, speed : float, delta : float):
	
	#dir is the normalized 2d vector for movement
	#change evertyhing to use forces if needed
	pass


func _handle_movement(delta : float):
	#everything that has to do with getting inputs
	#create an input component that gets inputs and attach that to this node
	#then call this function in the movement component
	pass

func _handle_legs():
	#call this function under _move() to take care of visuals
	pass

#endregion

#region jump_and_stuff

func _handle_jump():
	
	#call this when the inputs for jump are pressed in the input component
	#should handle everything related to jump like checking if you can jump, coyote time, etc
	
	pass

#endregion

#region interations

#nothing for now

#endregion
