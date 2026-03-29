extends Node3D

var sound = preload("uid://cisc24go2238h")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	AudioManager.play_3d(sound,position,40)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	queue_free()
	pass # Replace with function body.
