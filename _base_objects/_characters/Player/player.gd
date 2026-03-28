extends Time_Character
class_name Player



# ==========================================
# NODE REFERENCES
# ==========================================
@onready var camera = %Camera
@onready var camera_rotation = camera.global_rotation.x :
	set(value):
		if camera.global_rotation.x != value:
			camera.global_rotation.x = value
			camera_rotation = value


# ==========================================
# MODULAR INPUT STATE
# ==========================================

var _input_direction : Vector2 = Vector2.ZERO
var _input_jump_requested : bool = false
var _input_sprint_held : bool = false

# ==========================================
# CORE LOOP
# ==========================================
func _physics_process(delta: float) -> void:
	
	_gather_inputs()
	
	
	if not _is_rewinding:
		_process_normal_movement(delta)
		
		move_and_slide()
		
	#EXTREMELY IMPORTANT
	super._physics_process(delta)

# ==========================================
# FUNCTION BLOCKS
# ==========================================

func _ready() -> void:
	Globals.player = self
	just_finished_rewinding.connect(_on_rollback_finish)
	super._ready()

func _gather_inputs() -> void:
	# Capture movement vector (Normalized automatically by get_vector)
	_input_direction = Input.get_vector("Forward", "Backward", "Left", "Right")
	
	# Capture discrete actions
	_input_jump_requested = Input.is_action_just_pressed("Jump")
	
	# Capture continuous actions
	_input_sprint_held = Input.is_action_pressed("Sprint")

func _process_normal_movement(delta: float) -> void:
	
	# Apply standard directional movement
	_is_sprinting = _input_sprint_held
	_move_self(_input_direction, delta)
	
	# Apply jump logic
	if _input_jump_requested:
		_attempt_jump()

func age_effects(age : float):
	pass

func _on_rollback_finish():
	var age = aging_component.current_age
	
	
