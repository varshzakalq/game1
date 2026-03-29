extends Node


# ==========================================
# 3D POSITIONAL AUDIO
# ==========================================
func play_3d(stream: AudioStream, spawn_position: Vector3, volume: float = 0.0, pitch: float = 1.0, randomize_pitch: bool = true) -> AudioStreamPlayer3D:
	if stream == null:
		return null
		
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = stream
	audio_player.global_position = spawn_position
	audio_player.volume_db = volume
	
	if randomize_pitch:
		audio_player.pitch_scale = pitch * randf_range(0.85, 1.15)
	else:
		audio_player.pitch_scale = pitch
		
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
	
	# Hand the reference back to the caller
	return audio_player

# ==========================================
# 2D / UI AUDIO
# ==========================================
func play_2d(stream: AudioStream, volume: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
		
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.volume_db = volume
	audio_player.pitch_scale = pitch
	
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
	
	# Hand the reference back to the caller
	return audio_player
