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
var target_player: Time_Character = null 
var _time_since_last_attack: float = 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta) 
	
	if _is_rewinding: 
		return
		
	_time_since_last_attack += delta
	_detect_player()
	
	if has_detected_player and target_player:
		var distance_to_target = global_position.distance_to(target_player.global_position)
		
		if distance_to_target <= attack_range:
			_attempt_time_attack()

# ==========================================
# TIME ATTACK LOGIC
# ==========================================
func _attempt_time_attack() -> void:
	if _time_since_last_attack >= attack_cooldown:
		_time_since_last_attack = 0.0
		
		if target_player.aging_component != null:
			launch_attack(target_player.aging_component, age_damage_per_hit)

func launch_attack(age_component, age_damage):
	pass

# ==========================================
# DETECTION LOGIC
# ==========================================
func _detect_player() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return
		
	var potential_target = players[0] as Time_Character
	if not potential_target:
		return
		
	var distance_to_target = global_position.distance_to(potential_target.global_position)
	
	if distance_to_target <= detection_radius:
		if _has_line_of_sight(potential_target):
			has_detected_player = true
			target_player = potential_target
			return
			
	has_detected_player = false
	target_player = null

func _has_line_of_sight(target: Node3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, target.global_position)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == target:
		return true
		
	return false
