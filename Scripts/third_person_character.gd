extends CharacterBody3D

@export var move_speed: float = 5.0
@export var run_speed: float = 8.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 9.8

@onready var camera_pivot: Node3D = $CameraPivot
@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var nearest_interactable: Interactable = null

var camera_rotation: Vector2 = Vector2.ZERO
@export var camera_sensitivity: float = 0.3
@export var camera_min_pitch: float = -45.0
@export var camera_max_pitch: float = 45.0

var current_anim: String = ""
var is_emoting: bool = false

const BLEND_TIME := 0.15

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_animations()

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null

func _setup_animations() -> void:
	var library := AnimationLibrary.new()

	var sources := {
		"idle": $IdleAnim,
		"walk": $WalkAnim,
		"run": $RunAnim,
		"gangnam": $GangnamAnim,
	}

	for anim_name in sources:
		var source_node: Node = sources[anim_name]
		var source_player := _find_anim_player(source_node)

		if source_player and source_player.get_animation_list().size() > 0:
			var orig_anim_name = source_player.get_animation_list()[0]
			var anim: Animation = source_player.get_animation(orig_anim_name).duplicate()

			# Retarget and remove root motion
			var tracks_to_remove := []
			for i in range(anim.get_track_count()):
				var track_path := str(anim.track_get_path(i))
				if track_path == "rig":
					tracks_to_remove.append(i)
				elif track_path.begins_with("rig"):
					var new_path := "Model/" + track_path
					anim.track_set_path(i, NodePath(new_path))

			tracks_to_remove.reverse()
			for i in tracks_to_remove:
				anim.remove_track(i)

			anim.loop_mode = Animation.LOOP_LINEAR
			library.add_animation(anim_name, anim)

	anim_player.add_animation_library("anims", library)
	_play_anim("idle")

func _play_anim(anim_name: String) -> void:
	var full_name := "anims/" + anim_name
	if current_anim != anim_name and anim_player.has_animation(full_name):
		anim_player.play(full_name, BLEND_TIME)
		current_anim = anim_name

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

	# Secret emote key
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		is_emoting = !is_emoting
		if is_emoting:
			_play_anim("gangnam")

	# Interact
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if nearest_interactable:
			nearest_interactable.interact()

func _physics_process(delta: float) -> void:
	camera_pivot.rotation_degrees.x = camera_rotation.x
	camera_pivot.rotation_degrees.y = camera_rotation.y

	# Check for interactables
	_check_interactables()

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := Basis(Vector3.UP, deg_to_rad(camera_rotation.y))
	var direction := cam_basis * Vector3(input_dir.x, 0, input_dir.y)
	direction = direction.normalized()

	var is_running := Input.is_key_pressed(KEY_SHIFT)
	var speed := run_speed if is_running else move_speed

	if is_emoting:
		if direction:
			is_emoting = false
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

	if not is_emoting:
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

			var target_angle := atan2(direction.x, direction.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)

			_play_anim("run" if is_running else "walk")
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
			_play_anim("idle")

	move_and_slide()

func _check_interactables() -> void:
	var closest: Interactable = null
	var closest_dist := 999.0

	for area in $InteractionArea.get_overlapping_areas():
		if area is Interactable:
			var dist := global_position.distance_to(area.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = area

	nearest_interactable = closest

func get_interaction_prompt() -> String:
	if nearest_interactable:
		return "[E] " + nearest_interactable.get_prompt()
	return ""
