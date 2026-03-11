extends Node3D

@export var move_speed: float = 5.0
@export var rotate_speed: float = 1.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var dir = Input.get_axis("up", "down")
	translate(Vector3(0,0,-dir) * move_speed * delta)
	var a_dir = Input.get_axis("right","left")
	rotate_object_local(Vector3.UP, a_dir* rotate_speed*delta)
	
	pass
 
