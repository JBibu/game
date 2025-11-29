extends CharacterBody3D

# Movement
@export var move_speed: float = 5.0
@export var run_speed: float = 8.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 9.8

# Camera
@export var camera_sensitivity: float = 0.3
@export var camera_min_pitch: float = -45.0
@export var camera_max_pitch: float = 45.0

# Health
@export var max_health: int = 10
var health: int = 10
var invincible: bool = false
var invincible_time: float = 2.0

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var flashlight_mesh: MeshInstance3D = $FlashlightMesh
@onready var flashlight_light: SpotLight3D = $FlashlightLight

# Internal state
var camera_rotation: Vector2 = Vector2.ZERO
var current_anim: String = ""
var is_emoting: bool = false
var nearest_interactable: Interactable = null
var skeleton: Skeleton3D = null
var left_hand_bone_idx: int = -1
var light_bob_time: float = 0.0

const BLEND_TIME := 0.15

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health = max_health
	_setup_animations()
	_setup_flashlight()

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

	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		is_emoting = !is_emoting
		if is_emoting:
			_play_anim("gangnam")

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if nearest_interactable:
			nearest_interactable.interact()

func _physics_process(delta: float) -> void:
	camera_pivot.rotation_degrees.x = camera_rotation.x
	camera_pivot.rotation_degrees.y = camera_rotation.y

	_check_interactables()

	if not is_on_floor():
		velocity.y -= gravity * delta

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
	_update_flashlight(delta, direction.length() > 0.1)

# Animation setup

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

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null

func _play_anim(anim_name: String) -> void:
	var full_name := "anims/" + anim_name
	if current_anim != anim_name and anim_player.has_animation(full_name):
		anim_player.play(full_name, BLEND_TIME)
		current_anim = anim_name

# Flashlight

func _setup_flashlight() -> void:
	skeleton = _find_skeleton(model)
	if skeleton:
		left_hand_bone_idx = skeleton.find_bone("hand_left")

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _update_flashlight(delta: float, is_moving: bool) -> void:
	if not skeleton or left_hand_bone_idx == -1:
		return

	var bone_pose := skeleton.get_bone_global_pose(left_hand_bone_idx)
	var hand_global := skeleton.global_transform * bone_pose
	var tip_offset := hand_global.basis.y * 0.15

	# Cylinder mesh attached to hand
	if flashlight_mesh:
		var up_offset := hand_global.basis.z * 0.04
		var inward_offset := hand_global.basis.x * 0.05
		flashlight_mesh.global_transform.origin = hand_global.origin + tip_offset + up_offset + inward_offset
		var rotated_basis := hand_global.basis.rotated(hand_global.basis.x, deg_to_rad(90))
		rotated_basis = rotated_basis.rotated(hand_global.basis.y, deg_to_rad(-10))
		rotated_basis = rotated_basis.rotated(hand_global.basis.x, deg_to_rad(-30))
		flashlight_mesh.global_transform.basis = rotated_basis

	# Light follows hand position, stays horizontal with subtle bobbing
	if flashlight_light:
		flashlight_light.global_transform.origin = hand_global.origin + tip_offset
		var forward := model.global_transform.basis.z
		var right := model.global_transform.basis.x

		if is_moving:
			light_bob_time += delta * 8.0
			var bob := sin(light_bob_time) * 0.1
			var look_dir := (forward + right * bob).normalized()
			flashlight_light.global_transform.basis = Basis.looking_at(look_dir, Vector3.UP)
		else:
			light_bob_time = 0.0
			flashlight_light.global_transform.basis = Basis.looking_at(forward, Vector3.UP)

# Interaction

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

# Health and damage

func take_damage(amount: int) -> void:
	if invincible:
		return

	health -= amount
	invincible = true

	if model:
		var tween := create_tween()
		tween.tween_callback(func(): _set_model_visible(false))
		tween.tween_interval(0.1)
		tween.tween_callback(func(): _set_model_visible(true))
		tween.tween_interval(0.1)
		tween.set_loops(5)

	get_tree().create_timer(invincible_time).timeout.connect(func(): invincible = false)

	if health <= 0:
		_die()

func _set_model_visible(vis: bool) -> void:
	if model:
		for child in model.get_children():
			if child is MeshInstance3D or child.name == "rig":
				child.visible = vis

func _die() -> void:
	health = max_health
	global_position = Vector3(0, 1, 0)

func get_health() -> int:
	return health
