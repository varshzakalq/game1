extends RigidBody3D

@onready var neck = $Neck
@onready var neck2 = $Neck/Neck2
@onready var camera = $Neck/Neck2/Camera3D
@onready var model = $CSGCombiner3D
@onready var raycast = $Neck/Neck2/Camera3D/RayCast3D


const SPEED = 300.0
const JUMP_VELOCITY = 6
const SENSITIVITY = 0.003 # Adjust this for mouse speed

var velocity : Vector3 = Vector3.ZERO

var gravity = 20

var item_held : bool = false
var held_item_ref : Node = null
var y_rot



func _ready():
	# This captures the mouse so it doesn't leave the game window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	y_rot = rotation.y
	axis_lock_angular_x = true
	axis_lock_angular_z = true


func _unhandled_input(event):
	# Check if the mouse moved
	if event is InputEventMouseMotion:
		# 1. Rotate the whole Player left/right (Y-axis)
		neck.rotate_y(-event.relative.x * SENSITIVITY)
		
		# 2. Rotate only the Camera up/down (X-axis)
		neck2.rotate_x(-event.relative.y * SENSITIVITY)
		
		# 3. Clamp the vertical rotation so you can't do a backflip
		neck2.rotation.x = clamp(neck2.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta):
	# Get input and calculate direction based on the PLAYER'S current facing direction
	get_gravity()
	var Acceleration = Vector3.ZERO
	velocity = lerp(velocity, Vector3.ZERO, 1*delta)
	
	var inp = get_input()
	
	if inp != Vector3.ZERO:
		y_rot = camera.global_rotation.y

		Acceleration = inp
		
		Acceleration = Acceleration.rotated(Vector3(0, 1, 0), y_rot)
		Acceleration *= SPEED
	
	if item_held:
		handle_held_item(delta)
	align(y_rot, delta)
	
	velocity = Acceleration * delta
	
	var collision = move_and_collide(velocity*delta)
	handle_collision(collision, delta)


func _process(delta: float) -> void:
	
	handle_item_input()
	
	
	

func handle_collision(col : KinematicCollision3D , delta):
	return
	var obj = col.get_collider()
	var vel 

func align(yrot, delta):
	var y = yrot
	if (y - model.global_rotation.y) > PI:
		y-= 2*PI
	if (y - model.global_rotation.y) < -PI:
		y+= 2*PI
	model.global_rotation.y = lerp(model.global_rotation.y, y, delta*10)
	

#region item handle

func handle_item_input():
	var press_e = Input.is_action_just_pressed("E")
	if item_held and press_e:
		drop_item()
		return
	if (not item_held) and press_e:
		attempt_grab_item()

func handle_held_item(delta):
	var yrot = model.global_rotation.y
	var dist = 2.
	var disp = dist * Vector3(sin(yrot), 0, cos(yrot))
	held_item_ref.global_position = global_position - disp


func drop_item():
	held_item_ref = null
	item_held = false
	print("ITEM DROPPED")

func attempt_grab_item():
	var obj = raycast.get_collider()
	if not obj:
		push_error("NO OBJECT IN RAYCAST")
		return
	print("SMTH THERE")
	if obj.has_method("pick"):
		held_item_ref = obj
		item_held = true
		print("GOT IT")

#endregion

func get_input():
	var res = Vector3.ZERO
	if Input.is_action_pressed("up"):
		res.z -= 1.
	if Input.is_action_pressed("down"):
		res.z += 1.
	if Input.is_action_pressed("left"):
		res.x -=1
	if Input.is_action_pressed("right"):
		res.x +=1
	
	
	if Input.is_action_just_pressed("ui_accept"):
		apply_central_impulse(Vector3(0,JUMP_VELOCITY,0))
	return res
