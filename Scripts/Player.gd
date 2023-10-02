extends CharacterBody3D

var speed: float = 0.0

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5
const SENSITIVITY: float = 0.001
# Bob frequency
const BOB_FREQ: float = 2.0
const BOB_AMP: float = 0.08
var t_bob: float = 0.0

# FOV Variables
const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = 9.8

var weapon_to_spawn
var weapon_to_drop

@onready var head = $Head
@onready var camera = $'Head/Camera3D'
@onready var reach = $Head/Camera3D/Reach
@onready var hand = $Head/Hand

@onready var gun_a = preload("res://Gun/gun_a.tscn")
@onready var gun_b = preload("res://Gun/gun_b.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#func _process(_delta):
#	if reach.is_colliding():
#		if reach.get_collider().get_name() == "Gun A":
#			weapon_to_spawn = gun_a.instantiate()
#		elif reach.get_collider().get_name() == "Gun B":
#			weapon_to_spawn = gun_b.instantiate()
#		else:
#			weapon_to_spawn = null
#	else:
#		weapon_to_spawn = null
#
#	if hand.get_child(0) != null:
#		if hand.get_child(0).get_name() == "Gun A":
#			weapon_to_drop = gun_a.instantiate()
#		elif hand.get_child(0).get_name() == "Gun B":
#			weapon_to_drop = gun_b.instantiate()
#	else:
#		weapon_to_drop = null
#
#	if Input.is_action_just_pressed("Interact"):
#		if weapon_to_spawn != null:
#			if hand.get_child(0) != null:
#				get_parent().add_child(weapon_to_drop)
#				weapon_to_drop.global_transform = hand.global_transform
#				weapon_to_drop.dropped = true
#				hand.get_child(0).queue_free()
#			reach.get_collider().queue_free()
#			hand.add_child(weapon_to_spawn)
#			weapon_to_spawn.rotation = hand.rotation



func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(_delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * _delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction.length() > 0.0:
			velocity.x = lerp(velocity.x, direction.x * speed, _delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, _delta * 7.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, _delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, _delta * 3.0)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Head bob
	t_bob += _delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, _delta * 8.0)
	
	
	if Input.is_action_just_pressed("Interact"):
		if reach.is_colliding():
			if reach.get_collider().get_name() == "Gun A":
				weapon_to_spawn = gun_a.instantiate()
				hand.add_child(weapon_to_spawn)
				weapon_to_spawn.rotation = hand.rotation


	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

