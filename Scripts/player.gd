extends CharacterBody3D


#References
@onready var cam_root = $CamRoot
@onready var camera = $CamRoot/Head/Camera3D
@onready var mesh = $MeshInstance3D
@onready var nametag = $Nametag
@onready var multiplayer_synchronizer = $MultiplayerSynchronizer

var current_vel = Vector3.ZERO
var dir = Vector3.ZERO
var sync_pos : Vector3

const SPEED = 4#*3
const SPRINT_SPEED = 8#*3
const ACCEL = 10.0
const AIR_ACCEL = 8.0
var GRAVITY = -20
const JUMP_SPEED = 10
var MOUSE_SENSITIVITY = 0.1
var jumping = false
var on_floor = false

var data

func _enter_tree():
	set_multiplayer_authority(data, true)
	
	if multiplayer.is_server():
		print(multiplayer.multiplayer_peer.is_server_relay_supported())


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = is_multiplayer_authority()
	mesh.visible = is_multiplayer_authority()
	
	
	

	if is_multiplayer_authority():
		nametag.text = Steam.getPersonaName()
		await get_tree().process_frame
		global_position = get_tree().current_scene.get_node("Main").marker.global_position
	



func _process(_delta):
	if not is_multiplayer_authority():
		return
	
	window_activity()
	
	
	
func _physics_process(delta):
	if not is_multiplayer_authority():
		global_position = global_position.lerp(sync_pos, 0.5)
		return
	
	
	process_movement_inputs()
	process_movement(delta)
	process_jump(delta)
	

	
	
	move_and_slide()
	sync_pos = global_position



func process_movement_inputs():
	# Get the input directions
	dir = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		dir -= global_transform.basis.z
	if Input.is_action_pressed("move_backward"):
		dir += global_transform.basis.z
	if Input.is_action_pressed("move_right"):
		dir += global_transform.basis.x
	if Input.is_action_pressed("move_left"):
		dir -= global_transform.basis.x
	
	# Normalizing the input directions
	dir = dir.normalized()


func process_movement(delta):
	# Set speed and target velocity
	var speed = 0
	if Input.is_action_pressed("sprint"):
		speed = lerpf(speed, SPRINT_SPEED, 0.8)
	else:
		speed = lerpf(speed, SPEED, 0.8)
	
	var target_vel = dir * speed
	#print(speed)
	# Smooth out the player's movement
	var accel = ACCEL if on_floor else AIR_ACCEL
	current_vel = current_vel.lerp(target_vel, accel * delta)
	
	velocity.x = current_vel.x
	velocity.z = current_vel.z
	
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(4)
	set_floor_max_angle(deg_to_rad(45))
	move_and_slide()
	velocity = velocity


func process_jump(delta):
		
	# Apply gravity
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += GRAVITY * delta
		else:
			velocity.y += GRAVITY * 1.5 * delta
	
		
	# Jump
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_SPEED

func _input(event):
	if event is InputEventMouseMotion:
		# Rotates the view vertically
		$CamRoot.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		$CamRoot.rotation_degrees.x = clamp($CamRoot.rotation_degrees.x, -90, 90)
		# Rotates the view horizontally
		rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
func window_activity():
	if Input.is_action_just_pressed("focus"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("unfocus"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
