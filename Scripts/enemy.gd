extends CharacterBody3D
class_name Enemy

enum State { PATROL, CHASE, RETURN }

@export var move_speed: float = 1.5
@export var chase_speed: float = 2.5
@export var detection_range: float = 8.0
@export var lose_range: float = 12.0
@export var damage: int = 1
@export var patrol_points: Array[Vector3] = []
@export var gravity: float = 9.8

var current_state: State = State.PATROL
var current_patrol_index: int = 0
var player: CharacterBody3D = null
var start_position: Vector3

func _ready() -> void:
	start_position = global_position
	if patrol_points.is_empty():
		patrol_points = [start_position]

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Find player
	if not player:
		player = get_tree().current_scene.get_node_or_null("ThirdPersonCharacter")

	# State machine
	match current_state:
		State.PATROL:
			_patrol(delta)
			_check_player_detection()
		State.CHASE:
			_chase(delta)
			_check_player_lost()
		State.RETURN:
			_return_to_patrol(delta)

	move_and_slide()

	# Check collision with player
	_check_player_collision()

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target := patrol_points[current_patrol_index]
	var direction := (target - global_position)
	direction.y = 0

	if direction.length() < 0.5:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_face_direction(direction, delta)

func _chase(delta: float) -> void:
	if not player:
		current_state = State.RETURN
		return

	var direction := (player.global_position - global_position)
	direction.y = 0
	direction = direction.normalized()

	velocity.x = direction.x * chase_speed
	velocity.z = direction.z * chase_speed
	_face_direction(direction, delta)

func _return_to_patrol(delta: float) -> void:
	var target := patrol_points[current_patrol_index] if not patrol_points.is_empty() else start_position
	var direction := (target - global_position)
	direction.y = 0

	if direction.length() < 0.5:
		current_state = State.PATROL
	else:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_face_direction(direction, delta)

func _check_player_detection() -> void:
	if not player:
		return

	var distance := global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.CHASE

func _check_player_lost() -> void:
	if not player:
		current_state = State.RETURN
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > lose_range:
		current_state = State.RETURN

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)

func _check_player_collision() -> void:
	if not player:
		return

	var distance := global_position.distance_to(player.global_position)
	if distance < 1.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)
