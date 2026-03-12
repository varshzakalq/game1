extends CharacterBody3D

var Health : float = 100.0:
	set(val):
		Health = val
		_play_damage_animation()

var Detection_range : float = 10
var Detection_angle : float = 30

var Target = null


func _play_damage_animation():
	pass

func _scan_player() -> Vector3 :
	#return zero if player was not found
	if Target == null:
		return Vector3.ZERO
	
	var displacement : Vector3 = Target.global_position - global_position
	return displacement
	
	
	
