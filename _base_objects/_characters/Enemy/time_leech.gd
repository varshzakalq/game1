extends StandardEnemy
class_name TimeLeech

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

func _physics_process(_delta: float) -> void:
	# Safety check: if player isn't loaded, don't do anything
	if Globals.player == null:
		return
		
	var player_pos = Globals.player.global_position
	var dist = global_position.distance_to(player_pos)

	# Only track if within 20 units
	if dist < 20.0:
		navigation_agent_3d.target_position = player_pos

	# Movement Logic
	if not navigation_agent_3d.is_navigation_finished():
		var next_path_pos = navigation_agent_3d.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		
		velocity = direction * 2.0
		move_and_slide()
