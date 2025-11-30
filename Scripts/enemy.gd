extends CharacterBody3D
class_name Enemy

enum State { PATROL, CHASE, ATTACK, RETURN }

@export var move_speed: float = 2.0
@export var chase_speed: float = 3.5
@export var detection_range: float = 10.0
@export var lose_range: float = 14.0
@export var attack_range: float = 1.8
@export var damage: int = 30
@export var patrol_points: Array[Vector3] = []
@export var gravity: float = 9.8
@export var health: int = 50
@export var health_bar_visible_range: float = 10.0

var current_state: State = State.PATROL
var is_dead: bool = false
var current_patrol_index: int = 0
var player: CharacterBody3D = null
var start_position: Vector3
var is_attacking: bool = false

# Idle wandering
var wander_target: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0
var wander_wait_timer: float = 0.0
var is_wandering: bool = false
@export var wander_radius: float = 3.0
@export var wander_wait_min: float = 0.5
@export var wander_wait_max: float = 1.5

# Animation
@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var current_anim: String = ""

# Health bar
var max_health: int
var health_bar: Sprite3D
var health_bar_bg: Sprite3D

# Sound
var sfx_hit: AudioStreamPlayer3D
var sfx_attack: AudioStreamPlayer3D
var sfx_detect: AudioStreamPlayer3D
var sfx_death: AudioStreamPlayer3D

func _ready() -> void:
	start_position = global_position
	max_health = health
	if patrol_points.is_empty():
		patrol_points = [start_position]
	_setup_animations()
	_setup_health_bar()
	_apply_skeleton_texture()
	_setup_sounds()

func _setup_sounds() -> void:
	sfx_hit = Utils.create_audio_player(self, "res://Assets/Sounds/SFX/enemy_hit.wav", -10.0, true)
	sfx_attack = Utils.create_audio_player(self, "res://Assets/Sounds/SFX/enemy_attack.wav", -10.0, true)
	sfx_detect = Utils.create_audio_player(self, "res://Assets/Sounds/SFX/enemy_detect.wav", -10.0, true)
	sfx_death = Utils.create_audio_player(self, "res://Assets/Sounds/SFX/enemy_death.wav", 0.0, true)

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
			var is_moving := _patrol(delta)
			_check_player_detection()
			_play_anim("walk" if is_moving else "idle")
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
	_update_health_bar_visibility()

func _patrol(delta: float) -> bool:
	# If we have multiple patrol points, use them
	if patrol_points.size() > 1:
		var target := patrol_points[current_patrol_index]
		var direction := (target - global_position)
		direction.y = 0

		if direction.length() < 0.5:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
			return true
		else:
			direction = direction.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			_face_direction(direction, delta)
			return true

	# Random wandering when no patrol points or only one
	return _wander(delta)

func _wander(delta: float) -> bool:
	# If currently wandering to a target
	if is_wandering:
		var direction := (wander_target - global_position)
		direction.y = 0

		# Reached target or timer expired
		if direction.length() < 0.5 or wander_timer <= 0:
			is_wandering = false
			wander_wait_timer = randf_range(wander_wait_min, wander_wait_max)
			velocity.x = 0
			velocity.z = 0
			return false

		wander_timer -= delta
		direction = direction.normalized()
		velocity.x = direction.x * move_speed * 0.6  # Slower wandering
		velocity.z = direction.z * move_speed * 0.6
		_face_direction(direction, delta)
		return true
	else:
		# Waiting before next wander
		wander_wait_timer -= delta
		if wander_wait_timer <= 0:
			# Pick a new random target within wander radius
			var random_angle := randf() * TAU
			var random_dist := randf_range(1.0, wander_radius)
			wander_target = start_position + Vector3(
				cos(random_angle) * random_dist,
				0,
				sin(random_angle) * random_dist
			)
			is_wandering = true
			wander_timer = 5.0  # Max time to reach target

		velocity.x = 0
		velocity.z = 0
		return false

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
		if current_state != State.CHASE and sfx_detect:
			sfx_detect.play()
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

		# Brutes attack slower
		var is_brute: bool = has_meta("is_brute") and get_meta("is_brute")
		var attack_speed: float = 0.7 if is_brute else 1.0
		var damage_delay: float = 1.5 if is_brute else 1.0

		_play_anim("attack", attack_speed)
		if sfx_attack:
			sfx_attack.play()
		# Delay damage to match animation
		get_tree().create_timer(damage_delay).timeout.connect(_deal_damage)

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
		var source_player := Utils.find_anim_player(source_node)

		if source_player and source_player.get_animation_list().size() > 0:
			var orig_anim_name = source_player.get_animation_list()[0]
			var anim: Animation = source_player.get_animation(orig_anim_name).duplicate()

			var tracks_to_remove := []
			for i in range(anim.get_track_count()):
				var track_path := str(anim.track_get_path(i))
				var first_part := track_path.split("/")[0] if "/" in track_path else track_path

				# For walk/idle, remove root position tracks that cause drifting
				if anim_name != "attack":
					if track_path == first_part and not ":" in track_path:
						tracks_to_remove.append(i)
						continue

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

func _play_anim(anim_name: String, speed: float = 1.0) -> void:
	if is_attacking and anim_name != "attack":
		return
	var full_name := "anims/" + anim_name
	if current_anim != anim_name and anim_player.has_animation(full_name):
		anim_player.play(full_name, Utils.BLEND_TIME)
		anim_player.speed_scale = speed
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

	# Spawn hit particles
	_spawn_hit_particles()

	# Play hit sound
	if sfx_hit:
		sfx_hit.pitch_scale = randf_range(0.9, 1.1)
		sfx_hit.play()

	if health <= 0:
		_die()

func _spawn_hit_particles() -> void:
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.4
	particles.position = Vector3(0, 1.0, 0) + global_position
	particles.top_level = true

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 60.0
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, -10, 0)
	material.scale_min = 0.05
	material.scale_max = 0.1
	material.color = Color(0.8, 0.1, 0.1)
	particles.process_material = material

	# Simple mesh for particles
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	particles.draw_pass_1 = mesh

	# Add to scene root so it persists after enemy dies
	get_tree().current_scene.add_child(particles)

	# Clean up after particles finish
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)

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

	# Play death sound
	if sfx_death:
		sfx_death.play()

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

func _apply_skeleton_texture() -> void:
	var texture := load("res://Assets/Models/skeleton/skeleton_d.png") as Texture2D
	if not texture:
		return
	_apply_texture_to_node(model, texture)

func _apply_texture_to_node(node: Node, texture: Texture2D) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in range(mesh_instance.get_surface_override_material_count()):
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = texture
			mesh_instance.set_surface_override_material(i, mat)
		# Also check mesh materials if no override count
		if mesh_instance.get_surface_override_material_count() == 0 and mesh_instance.mesh:
			for i in range(mesh_instance.mesh.get_surface_count()):
				var mat := StandardMaterial3D.new()
				mat.albedo_texture = texture
				mesh_instance.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_texture_to_node(child, texture)

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
	health_bar.render_priority = 1
	health_bar.position = Vector3(0, bar_height, 0.01)

	var fg_image := Image.create(50, 6, false, Image.FORMAT_RGBA8)
	fg_image.fill(Color(0.8, 0.1, 0.1, 1.0))
	var fg_texture := ImageTexture.create_from_image(fg_image)
	health_bar.texture = fg_texture
	add_child(health_bar)

	# Start hidden
	health_bar.visible = false
	health_bar_bg.visible = false

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

func _update_health_bar_visibility() -> void:
	if not health_bar or not health_bar_bg or is_dead:
		return

	var should_show := false
	if player:
		var distance := global_position.distance_to(player.global_position)
		should_show = distance < health_bar_visible_range

	health_bar.visible = should_show
	health_bar_bg.visible = should_show
