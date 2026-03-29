extends StandardEnemy
class_name TimeLeech


@export var explosion_scene: PackedScene
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
var previous_mem = false

func _physics_process(delta: float) -> void:
	# Safety check: if player isn't loaded, don't do anything
	if Globals.player == null:
		return
		

	
	
	super._physics_process(delta)

	move_and_slide()
	

func process_chase(delta: float, distance_to_player: float) -> void:
	var dist = global_position.distance_to(Globals.player.global_position)

	# Only track if within 20 units
	if dist < detection_radius and (_has_line_of_sight(Globals.player) or previous_mem == true):
		navigation_agent_3d.target_position = Globals.player.global_position

	if dist > attack_range:
		if not navigation_agent_3d.is_navigation_finished():
			var next_path_pos = navigation_agent_3d.get_next_path_position()
			var direction = (next_path_pos - global_position).normalized()
			look_at(Vector3(next_path_pos.x, global_position.y, next_path_pos.z ), Vector3.UP)
			velocity = direction * SPEED

func _ready() -> void:
	# 2. Connect the "died" signal to our local function
	# This says: "When the health hits 0, run the _on_death function"
	health_component.died.connect(_on_death)
	
	super._ready()

func _on_death() -> void:
	
	var dist = global_position.distance_to(Globals.player.global_position)
	
	var explosion = explosion_scene.instantiate()
		
		# 4. Add it to the level (the enemy's parent)
	get_parent().add_child(explosion)
		
		# 5. Move it to the enemy's current position
	explosion.global_position = global_position
		
		# 6. If it's a particle system, ensure it starts emitting
	if explosion is GPUParticles3D or explosion is CPUParticles3D:
		explosion.emitting = true
	if dist < 2.: 
		print("damaged")
		var damage = 100./(dist)
		Globals.player.aging_component.age_damage(damage)
	
	
	# 4. Remove the object from the game
	queue_free()

	
