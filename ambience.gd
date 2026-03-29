extends WorldEnvironment

var amb = preload("uid://meqgsqm3vlxk")
var time =102
var dur = 103
var audio_player = AudioStreamPlayer.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	audio_player.stream = amb
	audio_player.volume_db = 100
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time = time + delta
	if time >= dur:
		AudioManager.play_2d(amb,-10)
		print("playing")
		time = 0
	
	pass
