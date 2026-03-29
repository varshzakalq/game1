extends StandardEnemy
class_name RangedEnemy


@export var explosion_scene: PackedScene
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
var previous_mem = false


@export_category("Combat Setup")
@export var projectile_scene: PackedScene
# Create a Marker3D as a child of your enemy and position it where the projectile should spawn!
@export var fire_point: Marker3D

func _physics_process(delta: float) -> void:
	# Safety check: if player isn't loaded, don't do anything
	if Globals.player == null:
		return
		
	
	
	super._physics_process(delta)

	move_and_slide()
	

func process_chase(delta: float, distance_to_player: float) -> void:
	var dist = global_position.distance_to(Globals.player.global_position)

	if dist < detection_radius and (_has_line_of_sight(Globals.player) or previous_mem == true):
		navigation_agent_3d.target_position = Globals.player.global_position

	if dist > attack_range:
		if not navigation_agent_3d.is_navigation_finished():
			var next_path_pos = navigation_agent_3d.get_next_path_position()
			var direction = (next_path_pos - global_position).normalized()
			
			velocity = direction * SPEED
			
			
func launch_attack(age_component, age_damage: float) -> void:
	if projectile_scene == null:
		push_warning("Enemy: No projectile scene assigned in Inspector!")
		return
		
	if fire_point == null:
		push_warning("Enemy: No fire_point Marker assigned!")
		return
		
	# 1. Create the bullet
	var proj = projectile_scene.instantiate()
	
	# 2. Add it to the world (NOT the enemy!)
	# If you add it as a child of the enemy, the bullet will swing wildly 
	# if the enemy turns around while the bullet is mid-air.
	get_tree().current_scene.add_child(proj)
	
	# 3. Inject your specific attack data into this specific bullet
	if proj is TemporalProjectile:
		proj.damage = age_damage
		
		# (Optional) Since you passed the specific component into this function, 
		# you could theoretically pass it straight to the projectile here so the 
		# bullet doesn't have to search for it upon impact!
		# proj.target_component = age_component 
		
		# 4. Fire the bullet using the barrel's exact position/rotation
		proj.fire(fire_point.global_transform, Globals.player)

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
	if dist < 1.5: 
		print("damaged")
		Globals.player.aging_component.age_damage(200)
	
	
	# 4. Remove the object from the game
	queue_free()

	
