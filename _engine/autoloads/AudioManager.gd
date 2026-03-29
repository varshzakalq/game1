extends Node

# ==========================================
# 3D POSITIONAL AUDIO (Gunshots, Impacts, Explosions)
# ==========================================
func play_3d(stream: AudioStream, spawn_position: Vector3, volume: float = 0.0, pitch: float = 1.0, randomize_pitch: bool = true) -> void:
	if stream == null:
		return
		
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = stream
	audio_player.global_position = spawn_position
	audio_player.volume_db = volume
	
	# Randomizing pitch slightly makes repeated sounds (like machine guns) feel natural
	if randomize_pitch:
		audio_player.pitch_scale = pitch * randf_range(0.85, 1.15)
	else:
		audio_player.pitch_scale = pitch
		
	# 1. Add it to the main scene tree so it survives if the object that called it dies
	get_tree().current_scene.add_child(audio_player)
	
	# 2. Play the sound
	audio_player.play()
	
	# 3. Automatically delete the node the exact frame the sound track finishes
	audio_player.finished.connect(audio_player.queue_free)

# ==========================================
# 2D / UI AUDIO (Menu clicks, Player taking damage, Voice lines)
# ==========================================
func play_2d(stream: AudioStream, volume: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
		
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.volume_db = volume
	audio_player.pitch_scale = pitch
	
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
