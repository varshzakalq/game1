extends Node3D
@onready var player: Player = $"../Player"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dis = player.position - position
	print(dis.length())
	
	if dis.length() <7 and Input.is_action_just_pressed("interact ") and open == false:
		animation_player.play("door_open/Cube_001Action")
		open = true
		pass
		
	pass
