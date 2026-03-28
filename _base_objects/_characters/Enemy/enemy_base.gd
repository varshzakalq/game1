class_name StandardEnemy
extends Time_Character 

# --- TIME ATTACK STATS ---
@export_category("Time Attack Settings")
@export var age_damage_per_hit: float = 500.0 
@export var attack_range: float = 2.0
@export var detection_radius: float = 20.0
@export var attack_cooldown: float = 1.5

# --- STATE TRACKING ---
var has_detected_player: bool = false
var _time_since_last_attack: float = 0.0

# ==========================================
# CORE ENGINE LOGIC (Do not override in child classes)
# ==========================================
func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Keeps time mechanics alive
	
	if _is_rewinding: 
		return
		
	_time_since_last_attack += delta
	
	# If the player doesn't exist, do nothing
	if Globals.player == null:
		if has_detected_player:
			has_detected_player = false
			on_player_lost()
		return
		
	_handle_detection_and_combat(delta)
	move_and_slide()

func _handle_detection_and_combat(delta: float) -> void:
	var distance_to_player = global_position.distance_to(Globals.player.global_position)
	
	# 1. Detection Checks
	if distance_to_player <= detection_radius and _has_line_of_sight(Globals.player):
		if not has_detected_player:
			has_detected_player = true
			on_player_detected()
	else:
		if has_detected_player:
			has_detected_player = false
			on_player_lost()
			
	# 2. State Execution
	if has_detected_player:
		process_chase(delta, distance_to_player)
		
		# Check if close enough to attack
		if distance_to_player <= attack_range and _time_since_last_attack >= attack_cooldown:
			_time_since_last_attack = 0.0
			if Globals.player.aging_component != null:
				launch_attack(Globals.player.aging_component, age_damage_per_hit)
	else:
		process_idle(delta)

func _has_line_of_sight(target: Node3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, target.global_position)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	return result and result.collider == target

# ==========================================
# OVERRIDE HOOKS (Use these in your child classes!)
# ==========================================

## Triggered the exact frame the enemy executes an attack.
func launch_attack(age_component, age_damage: float) -> void:
	pass

## Runs every frame while the player is out of sight. Put patrol logic here.
func process_idle(delta: float) -> void:
	pass

## Runs every frame while the player is detected. Put movement/pathfinding here.
func process_chase(delta: float, distance_to_player: float) -> void:
	pass

## Triggered once the moment the player enters line of sight. Good for alert sounds.
func on_player_detected() -> void:
	pass

## Triggered once the moment the player escapes. Good for confusion animations.
func on_player_lost() -> void:
	pass
