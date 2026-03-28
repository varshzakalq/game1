
extends CharacterBody3D
class_name Sphere_enemy

#region nodes_and_scripts
@onready var controller = $Components/AI


var Melee_script_dir = "res://_base_objects/_characters/old enemy(for reference)/Sphere/Components/AI/Melee.gd"
var Ranged_script_dir = "res://_base_objects/_characters/old enemy(for reference)/Sphere/Components/AI/Ranged.gd"

#endregion

#region exports

@export_group("Common")
@export_subgroup("detection")
@export var Detection_range : float = 10
@export var Detection_angle : float = 30
@export var Target_class : String = ""

@export_subgroup("movement")
@export var Speed : float = 1
@export var Can_jump : bool = false

enum Enemy_type{
	Melee,
	Ranged
}

@export_group("")
@export var Type : Enemy_type 

#endregion

#region runtime_variables

var Target = null
var target_pos : Vector3


#endregion


#region animation_functions

#region health_related

func _play_take_damage_animation():
	pass

func _play_heal_animation():
	pass

func _play_death_animation():
	pass

func kill_self():
	_play_death_animation()

#endregion

#region attacks

func _play_melee_attack_animation():
	pass

func _play_ranged_attack_animation():
	pass

#endregion

#endregion

func _handle_gravity():
	velocity += get_gravity()

func _get_target_vector() -> Vector3 :
	#return zero if player was not found
	if Target == null:
		return Vector3.ZERO
	
	var displacement : Vector3 = Target.global_position - global_position
	return displacement


func _move_towards(pos : Vector3 = target_pos):
	target_pos = pos
	var disp = target_pos - global_position
	var dir = disp.normalized()
	
	velocity = dir*Speed

func _handle_jump():
	if not Can_jump: return
	
	pass

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_handle_gravity()
	move_and_slide()

func _ready() -> void:
	match Type:
		Enemy_type.Melee:
			controller.set_script(load(Melee_script_dir))
		Enemy_type.Ranged:
			controller.set_script(load(Ranged_script_dir))
		_:
			push_error("This shouldnt even be possible")
