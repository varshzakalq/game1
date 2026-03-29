extends StaticBody3D
class_name Time_Stationary

@export_category("Time Mechanics")
@export var MAX_SNAPSHOT_COUNT : int = 10000
@export var SNAPSHOT_PROPERTY_LIST : Array[String] = [
	"global_position",
	"global_rotation",
]

#INTERVAL VARS
@export var SNAPSHOT_INTERVAL : float = 0.05
var _time_since_last_snapshot : float = 0.0

#REWIND VARS
@export var MIN_REWIND_SPEED : float = 0.25
@export var MAX_REWIND_SPEED : float = 3.0
@export var REWIND_ACCELERATION : float = 1.5

var _reached_history_end : bool = false
var _rewind_tween : Tween

var _current_rewind_speed : float = MIN_REWIND_SPEED
var _rewind_accumulator : float = 0.0 

var snapshots : Dictionary = {}
var _is_rewinding : bool = false

func _ready() -> void:
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
				# Instantly set velocities to preserve exact physical momentum

				if key[0] == '$':
					var temp = key.substr(1)
					set(temp, target_values[key])
				
				else:
					_rewind_tween.tween_property(self, key, target_values[key], tween_duration)

func _take_snapshot(delta: float) -> void:
	if _is_rewinding: return
	
	_reached_history_end = false 
	
	_time_since_last_snapshot += delta
	
	if _time_since_last_snapshot >= SNAPSHOT_INTERVAL:
		_time_since_last_snapshot -= SNAPSHOT_INTERVAL 
		
		for property in SNAPSHOT_PROPERTY_LIST:
			
			var value
			
			if property[0] == '$':
				var temp = property.substr(1)
				value = get(temp)
			
			else: value = get(property)
			
			if value == null:
				push_error("NON EXISTENT PROPERTY %s TO TAKE SNAPSHOT OF" % property)
				continue
			snapshots[property].append(value)
			
			if MAX_SNAPSHOT_COUNT > 0 and snapshots[property].size() > MAX_SNAPSHOT_COUNT:
				snapshots[property].pop_front()

func _stop_rollback() -> void:
	_is_rewinding = false
	_current_rewind_speed = MIN_REWIND_SPEED 
	_rewind_accumulator = 0.0 

func _on_rewind_state(value : bool):
	_is_rewinding = value
	if value == false:
		_stop_rollback()


func _process_time_mechanics(delta: float) -> void:
	if _is_rewinding: _rollback(delta)

func _physics_process(delta: float) -> void:
	_process_time_mechanics(delta)
	_take_snapshot(delta)
