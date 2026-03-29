extends CharacterBody3D
class_name Time_Character



signal just_finished_rewinding



@export_category("Movement")
@export var SPEED : float = 2.0
@export var GRAVITY : float = 10.0
@export var JUMP_FORCE : float = 2.0
@export var SPRINT_MULTIPLIER : float = 1.5

var _is_sprinting = false

@export_category("Time Mechanics")
@export var MAX_SNAPSHOT_COUNT : int = 10000
@export var SNAPSHOT_PROPERTY_LIST : Array[String] = [
	"velocity",
	"position"
]

#INTERVAL VARS
var SNAPSHOT_INTERVAL : float = Globals.SNAPSHOT_INTERVAL
var _time_since_last_snapshot : float = 0.0

#REWIND VARS
var MIN_REWIND_SPEED =  Globals.MIN_REWIND_SPEED
var MAX_REWIND_SPEED = Globals.MAX_REWIND_SPEED 
var REWIND_ACCELERATION = Globals.REWIND_ACCELERATION

var _reached_history_end : bool = false
var _rewind_tween : Tween

var _current_rewind_speed : float = MIN_REWIND_SPEED
var _rewind_accumulator : float = 0.0 

var snapshots : Dictionary = {}
var _is_rewinding : bool = false

var movement_multiplier : float = 1.2
var jump_multiplier : float = 1.2

var _gravity_affected = true

@onready var aging_component



func _ready() -> void:
	
	aging_component = get_node("Aging Component")
	if aging_component != null:
		aging_component.age_increased.connect(_handle_age_increase)
	
	for prop in SNAPSHOT_PROPERTY_LIST:
		snapshots[prop] = []
	EventBus.rewinding.connect(_on_rewind_state)

func _rollback(delta: float) -> void:
	

	if _reached_history_end or snapshots[SNAPSHOT_PROPERTY_LIST[0]].is_empty():
		_reached_history_end = true
		return
		
	_is_rewinding = true
	
	_current_rewind_speed = move_toward(_current_rewind_speed, MAX_REWIND_SPEED, REWIND_ACCELERATION * delta)
	_rewind_accumulator += _current_rewind_speed
	
	var frames_to_pop : int = floor(_rewind_accumulator)
	
	if frames_to_pop > 0:
		_rewind_accumulator -= frames_to_pop
		
		var target_values : Dictionary = {}
		
		for i in range(frames_to_pop):
			if snapshots[SNAPSHOT_PROPERTY_LIST[0]].is_empty():
				_reached_history_end = true
				break
				
			for key in snapshots:
				
				if key == "global_rotation":
					var temp = snapshots[key].pop_back()
					
					if temp.y - global_rotation.y > PI:
						temp.y -= 2*PI
					elif temp.y - global_rotation.y < -PI:
						temp.y += 2*PI
					
					target_values[key] = temp
					continue
				
				target_values[key] = snapshots[key].pop_back()
				
		if not target_values.is_empty():
			if _rewind_tween and _rewind_tween.is_valid():
				_rewind_tween.kill()
				
			_rewind_tween = create_tween()
			_rewind_tween.set_parallel(true)
			
			var tween_duration = SNAPSHOT_INTERVAL / _current_rewind_speed
			
			for key in target_values:
				if key[0] == '$':
					var temp = key.substr(1)
					set(temp, target_values[key])
				
				else:
					_rewind_tween.tween_property(self, key, target_values[key], tween_duration/2)

func _take_snapshot(delta: float) -> void:
	if _is_rewinding: return
	
	_reached_history_end = false 
	
	_time_since_last_snapshot += delta
	
	if _time_since_last_snapshot >= SNAPSHOT_INTERVAL:
		_time_since_last_snapshot -= SNAPSHOT_INTERVAL 
		
		for property in SNAPSHOT_PROPERTY_LIST:
			var value = get(property)
			
			if property[0] == '$':
				var temp = property.substr(1)
				value = get(temp)
				
			if value == null:
				push_error("NON EXISTENT PROPERTY %s TO TAKE SNAPSHOT OF" % property)
				continue
			if not snapshots.has(property): snapshots[property] = []
			snapshots[property].append(value)
			
			if MAX_SNAPSHOT_COUNT > 0 and snapshots[property].size() > MAX_SNAPSHOT_COUNT:
				snapshots[property].pop_front()

func _stop_rollback() -> void:
	_is_rewinding = false
	_current_rewind_speed = MIN_REWIND_SPEED 
	_rewind_accumulator = 0.0 
	
	just_finished_rewinding.emit()

func _move_self(direction: Vector2, delta: float) -> void:
	if _is_rewinding: return 
	
	var speed = SPEED * movement_multiplier
	if _is_sprinting: speed *= SPRINT_MULTIPLIER
	
	var movement_dir = Vector3(direction.y, 0, direction.x)
	
	var vertical_vel = velocity.y
	velocity = lerp(velocity, speed*movement_dir.rotated(Vector3.UP, global_rotation.y), 5 * delta)
	velocity.y = vertical_vel

func _attempt_jump() -> void:
	if _is_rewinding: return
	if is_on_floor():
		velocity.y = JUMP_FORCE*jump_multiplier

func _get_gravity(delta : float) -> void:
	if _is_rewinding: return
	
	if not is_on_floor() and _gravity_affected:
		velocity.y -= GRAVITY*delta


#func _handle_stair_step_up(delta: float) -> void:
	#pass






func _on_rewind_state(value : bool):
	_is_rewinding = value
	if value == false:
		_stop_rollback()
	






func _process_time_mechanics(delta: float) -> void:
	if _is_rewinding: _rollback(delta)

func _handle_age_increase(age : float):
	if age < 20:
		movement_multiplier = 1.2
		jump_multiplier = 1.2
	elif age < 50:
		movement_multiplier = 1
		jump_multiplier = 1
	elif age < 70:
		movement_multiplier = 0.9
		jump_multiplier = 0.9
	else:
		movement_multiplier = 0.7
		jump_multiplier = 0.7
	
	age_effects(age)

func age_effects(_age : float):
	pass


func _physics_process(delta: float) -> void:
	_process_time_mechanics(delta)
	_get_gravity(delta)
	_take_snapshot(delta)
	#_handle_stair_step_up(delta)
