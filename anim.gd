extends MeshInstance3D
var speed = 10

@onready var cube1: MeshInstance3D = $"../MeshInstance3D"
@onready var cube3: MeshInstance3D = $"../cube3"
@onready var c3follower: MeshInstance3D = $"../c3follower"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_pressed("up"):
		translate(Vector3(1,0,0)*delta*speed)
		cube3.translate(Vector3(1,0,0)*delta*speed)
	if Input.is_action_pressed("down"):
		translate(Vector3(-1,0,0)*delta*speed)	
		cube3.translate(Vector3(-1,0,0)*delta*speed)	
		
		pass
	
	var distance = position - cube1.position
	if abs(distance.x) > 3:
		print("gaya")
		var tween = create_tween()
		tween.tween_property(cube1,"position",position,0.1)
		pass
	var distance1 = cube3.position - c3follower.position
	if abs(distance1.x) > 3:
		print("gaya2")
		var tween = create_tween()
		tween.tween_property(c3follower,"position",cube3.position,0.1)
		pass
	
	
	
	
		  
	

		
	pass
