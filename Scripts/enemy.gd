extends CharacterBody3D
class_name Enemy

enum State { PATROL, CHASE, ATTACK, RETURN }

@export var move_speed: float = 1.5
@export var chase_speed: float = 2.5
@export var detection_range: float = 8.0
@export var lose_range: float = 12.0
@export var attack_range: float = 1.5
@export var damage: int = 10
@export var patrol_points: Array[Vector3] = []
@export var gravity: float = 9.8
@export var health: int = 50

var current_state: State = State.PATROL
var is_dead: bool = false
var current_patrol_index: int = 0
var player: CharacterBody3D = null
var start_position: Vector3
var is_attacking: bool = false

# Animation
@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var current_anim: String = ""
const BLEND_TIME := 0.15


# Health bar
var max_health: int
var health_bar: Sprite3D
var health_bar_bg: Sprite3D

func _ready() -> void:
	start_position = global_position
	max_health = health
	if patrol_points.is_empty():
		patrol_points = [start_position]
	_setup_animations()
	_setup_health_bar()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Find player
	if not player:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	# State machine
	match current_state:
		State.PATROL:
			_patrol(delta)
			_check_player_detection()
			_play_anim("walk")
		State.CHASE:
			_chase(delta)
			_check_player_lost()
			_check_attack_range()
			_play_anim("walk")
		State.ATTACK:
			_attack(delta)
		State.RETURN:
			_return_to_patrol(delta)
			_play_anim("walk")

	move_and_slide()

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

func _check_attack_range() -> void:
	if not player or is_attacking:
		return

	var distance := global_position.distance_to(player.global_position)
	if distance < attack_range:
		current_state = State.ATTACK
		is_attacking = true
		current_anim = ""  # Reset so animation can play
		_play_anim("attack")
		# Delay damage to match animation
		get_tree().create_timer(1.0).timeout.connect(_deal_damage)

func _attack(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

	if player:
		var direction := (player.global_position - global_position)
		direction.y = 0
		_face_direction(direction.normalized(), delta)

	# Check if attack animation finished
	if not anim_player.is_playing():
		is_attacking = false
		current_state = State.CHASE

func _deal_damage() -> void:
	if not player:
		return

	var distance := global_position.distance_to(player.global_position)
	if distance < attack_range * 2.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)

# Animation setup

func _setup_animations() -> void:
	var library := AnimationLibrary.new()
	var sources := {
		"idle": $IdleAnim,
		"walk": $WalkAnim,
		"attack": $AttackAnim,
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
				var first_part := track_path.split("/")[0] if "/" in track_path else track_path

				# Remove root-only tracks
				if track_path == first_part and not ":" in track_path:
					tracks_to_remove.append(i)
				else:
					# Remap to Model node
					var new_path := "Model/" + track_path
					anim.track_set_path(i, NodePath(new_path))

			tracks_to_remove.reverse()
			for i in tracks_to_remove:
				anim.remove_track(i)

			if anim_name == "attack":
				anim.loop_mode = Animation.LOOP_NONE
			else:
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
	if is_attacking and anim_name != "attack":
		return
	var full_name := "anims/" + anim_name
	if current_anim != anim_name and anim_player.has_animation(full_name):
		anim_player.play(full_name, BLEND_TIME)
		current_anim = anim_name

# Damage and death

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	_update_health_bar()

	# Flash red when hit
	if model:
		_flash_damage()

	if health <= 0:
		_die()

func _flash_damage() -> void:
	var tween := create_tween()
	_set_model_color(Color(1, 0.3, 0.3))
	tween.tween_interval(0.1)
	tween.tween_callback(func(): _set_model_color(Color.WHITE))

func _set_model_color(color: Color) -> void:
	if not model:
		return
	for child in model.get_children():
		if child is MeshInstance3D:
			var mesh_child := child as MeshInstance3D
			var mat: Material = mesh_child.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				var std_mat := mat as StandardMaterial3D
				std_mat.albedo_color = color

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO

	# Hide health bar
	if health_bar:
		health_bar.visible = false
	if health_bar_bg:
		health_bar_bg.visible = false

	# Death animation - fall over and fade
	var tween := create_tween()
	tween.tween_property(self, "rotation:x", deg_to_rad(-90), 0.3)
	tween.parallel().tween_property(self, "position:y", position.y - 0.5, 0.3)
	tween.tween_interval(0.5)
	tween.tween_callback(queue_free)

# Health bar

func _setup_health_bar() -> void:
	var bar_height := 2.2

	# Background (dark)
	health_bar_bg = Sprite3D.new()
	health_bar_bg.pixel_size = 0.01
	health_bar_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_bg.no_depth_test = true
	health_bar_bg.position = Vector3(0, bar_height, 0)

	var bg_image := Image.create(52, 8, false, Image.FORMAT_RGBA8)
	bg_image.fill(Color(0.2, 0.2, 0.2, 0.8))
	var bg_texture := ImageTexture.create_from_image(bg_image)
	health_bar_bg.texture = bg_texture
	add_child(health_bar_bg)

	# Foreground (health - red)
	health_bar = Sprite3D.new()
	health_bar.pixel_size = 0.01
	health_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar.no_depth_test = true
	health_bar.position = Vector3(0, bar_height, 0)

	var fg_image := Image.create(50, 6, false, Image.FORMAT_RGBA8)
	fg_image.fill(Color(0.8, 0.1, 0.1, 1.0))
	var fg_texture := ImageTexture.create_from_image(fg_image)
	health_bar.texture = fg_texture
	add_child(health_bar)

func _update_health_bar() -> void:
	if not health_bar:
		return

	var health_percent := float(health) / float(max_health)
	health_percent = clamp(health_percent, 0.0, 1.0)

	# Scale the bar width based on health
	health_bar.scale.x = health_percent

	# Offset to keep bar left-aligned
	var bar_width := 0.5  # approximate width in world units
	health_bar.position.x = -bar_width * (1.0 - health_percent) * 0.5
