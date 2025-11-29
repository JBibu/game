extends CharacterBody3D

@export var move_speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var camera_rotation: Vector2 = Vector2.ZERO
@export var camera_sensitivity: float = 0.3
@export var camera_min_pitch: float = -45.0
@export var camera_max_pitch: float = 45.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.y * camera_sensitivity
		camera_rotation.y -= event.relative.x * camera_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, camera_min_pitch, camera_max_pitch)

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Apply camera rotation
	if camera_pivot:
		camera_pivot.rotation_degrees.x = camera_rotation.x
		rotation_degrees.y = camera_rotation.y

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()
