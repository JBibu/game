extends CanvasLayer

signal fishing_success
signal fishing_failed

# Fish behavior
@export var fish_speed: float = 150.0
@export var fish_erratic: float = 3.0

# Catch bar (green zone player controls)
@export var bar_gravity: float = 400.0
@export var bar_lift: float = 600.0
@export var bar_height: float = 80.0

# Progress
@export var catch_rate: float = 0.4
@export var lose_rate: float = 0.3

# UI
var background: ColorRect
var frame: ColorRect
var track: ColorRect
var catch_bar: ColorRect
var fish_icon: ColorRect
var progress_bg: ColorRect
var progress_fill: ColorRect
var instruction: Label

const TRACK_HEIGHT: float = 300.0
const TRACK_WIDTH: float = 40.0
const FISH_SIZE: float = 20.0

var is_active: bool = false
var fish_pos: float = 150.0
var fish_target: float = 150.0
var fish_timer: float = 0.0
var bar_pos: float = 100.0
var bar_velocity: float = 0.0
var progress: float = 0.5
var holding: bool = false

func _ready() -> void:
	_create_ui()
	visible = false

func _create_ui() -> void:
	# Dark overlay
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Main container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	center.add_child(vbox)

	# Instruction
	instruction = Label.new()
	instruction.text = "¡Mantén pulsado para elevar la barra verde!"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font = load("res://Assets/Fonts/CormorantGaramond.ttf")
	if font:
		instruction.add_theme_font_override("font", font)
	instruction.add_theme_font_size_override("font_size", 20)
	vbox.add_child(instruction)

	# Game area container
	var game_area = HBoxContainer.new()
	game_area.add_theme_constant_override("separation", 20)
	game_area.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(game_area)

	# Fishing track (vertical bar)
	var track_container = Control.new()
	track_container.custom_minimum_size = Vector2(TRACK_WIDTH + 10, TRACK_HEIGHT + 10)
	game_area.add_child(track_container)

	# Frame
	frame = ColorRect.new()
	frame.color = Color(0.4, 0.3, 0.2, 1)
	frame.size = Vector2(TRACK_WIDTH + 10, TRACK_HEIGHT + 10)
	track_container.add_child(frame)

	# Track background (water)
	track = ColorRect.new()
	track.color = Color(0.1, 0.2, 0.4, 1)
	track.size = Vector2(TRACK_WIDTH, TRACK_HEIGHT)
	track.position = Vector2(5, 5)
	track_container.add_child(track)

	# Catch bar (green, player controlled)
	catch_bar = ColorRect.new()
	catch_bar.color = Color(0.2, 0.7, 0.3, 0.8)
	catch_bar.size = Vector2(TRACK_WIDTH, bar_height)
	catch_bar.position = Vector2(5, 5 + TRACK_HEIGHT - bar_height - bar_pos)
	track_container.add_child(catch_bar)

	# Fish icon
	fish_icon = ColorRect.new()
	fish_icon.color = Color(1, 0.6, 0.2, 1)
	fish_icon.size = Vector2(TRACK_WIDTH - 8, FISH_SIZE)
	fish_icon.position = Vector2(9, 5 + TRACK_HEIGHT - FISH_SIZE - fish_pos)
	track_container.add_child(fish_icon)

	# Progress bar container
	var progress_container = Control.new()
	progress_container.custom_minimum_size = Vector2(20, TRACK_HEIGHT + 10)
	game_area.add_child(progress_container)

	# Progress background
	progress_bg = ColorRect.new()
	progress_bg.color = Color(0.2, 0.2, 0.2, 1)
	progress_bg.size = Vector2(20, TRACK_HEIGHT + 10)
	progress_container.add_child(progress_bg)

	# Progress fill
	progress_fill = ColorRect.new()
	progress_fill.color = Color(0.3, 0.8, 0.4, 1)
	progress_fill.size = Vector2(20, (TRACK_HEIGHT + 10) * 0.5)
	progress_fill.position.y = (TRACK_HEIGHT + 10) * 0.5
	progress_container.add_child(progress_fill)

func _process(delta: float) -> void:
	if not is_active:
		return

	# Check input
	holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	# Move catch bar (physics-like)
	if holding:
		bar_velocity += bar_lift * delta
	else:
		bar_velocity -= bar_gravity * delta

	bar_pos += bar_velocity * delta
	bar_pos = clamp(bar_pos, 0, TRACK_HEIGHT - bar_height)

	# Bounce off edges
	if bar_pos <= 0 or bar_pos >= TRACK_HEIGHT - bar_height:
		bar_velocity *= -0.3

	# Move fish (erratic movement)
	fish_timer -= delta
	if fish_timer <= 0:
		fish_timer = randf_range(0.5, 2.0)
		fish_target = randf_range(20, TRACK_HEIGHT - FISH_SIZE - 20)

	var fish_dir = sign(fish_target - fish_pos)
	fish_pos += fish_dir * fish_speed * delta
	fish_pos += sin(Time.get_ticks_msec() * 0.01) * fish_erratic * delta * 10
	fish_pos = clamp(fish_pos, 0, TRACK_HEIGHT - FISH_SIZE)

	# Check if fish is in catch bar
	var fish_center = fish_pos + FISH_SIZE / 2.0
	var bar_top = bar_pos
	var bar_bottom = bar_pos + bar_height
	var fish_in_bar = fish_center >= bar_top and fish_center <= bar_bottom

	# Update progress
	if fish_in_bar:
		progress += catch_rate * delta
		catch_bar.color = Color(0.3, 0.9, 0.4, 0.9)
	else:
		progress -= lose_rate * delta
		catch_bar.color = Color(0.2, 0.7, 0.3, 0.8)

	progress = clamp(progress, 0, 1)

	# Update UI positions (inverted Y for visual)
	catch_bar.position.y = 5 + TRACK_HEIGHT - bar_height - bar_pos
	fish_icon.position.y = 5 + TRACK_HEIGHT - FISH_SIZE - fish_pos

	# Update progress bar (fills from bottom)
	var fill_height = (TRACK_HEIGHT + 10) * progress
	progress_fill.size.y = fill_height
	progress_fill.position.y = TRACK_HEIGHT + 10 - fill_height

	# Color progress bar based on progress
	if progress > 0.7:
		progress_fill.color = Color(0.3, 0.9, 0.4, 1)
	elif progress > 0.3:
		progress_fill.color = Color(0.9, 0.8, 0.2, 1)
	else:
		progress_fill.color = Color(0.9, 0.3, 0.2, 1)

	# Check win/lose
	if progress >= 1.0:
		_win()
	elif progress <= 0.0:
		_lose()

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()

func start_fishing() -> void:
	progress = 0.5
	bar_pos = TRACK_HEIGHT - bar_height
	bar_velocity = 0.0
	fish_pos = 150.0
	fish_target = 150.0
	fish_timer = 0.0
	holding = false

	# Connect to player damage
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_signal("damaged") and not player.damaged.is_connected(_on_player_hit):
			player.damaged.connect(_on_player_hit)

	_update_positions()
	visible = true
	is_active = true
	instruction.text = "¡Mantén pulsado para elevar la barra verde!"

func _update_positions() -> void:
	catch_bar.position.y = 5 + TRACK_HEIGHT - bar_height - bar_pos
	fish_icon.position.y = 5 + TRACK_HEIGHT - FISH_SIZE - fish_pos
	var fill_height = (TRACK_HEIGHT + 10) * progress
	progress_fill.size.y = fill_height
	progress_fill.position.y = TRACK_HEIGHT + 10 - fill_height

func _win() -> void:
	is_active = false
	instruction.text = "¡Pez al canto!"
	progress_fill.color = Color(0.3, 1.0, 0.5, 1)
	await get_tree().create_timer(1.0).timeout
	visible = false
	fishing_success.emit()

func _lose() -> void:
	is_active = false
	instruction.text = "Se ha escapado..."
	progress_fill.color = Color(1.0, 0.2, 0.2, 1)
	await get_tree().create_timer(1.0).timeout
	visible = false
	fishing_failed.emit()

func _on_player_hit() -> void:
	if is_active:
		_lose()
