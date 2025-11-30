extends Control

@onready var main_container: VBoxContainer = $MainContainer
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var volume_slider: HSlider = $OptionsContainer/VolumeRow/VolumeSlider
@onready var fullscreen_button: Button = $OptionsContainer/FullscreenButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$MainContainer/StartButton.pressed.connect(_start_game)
	$MainContainer/OptionsButton.pressed.connect(_show_options)
	$MainContainer/QuitButton.pressed.connect(get_tree().quit)
	$OptionsContainer/BackButton.pressed.connect(_show_main)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	volume_slider.value_changed.connect(_set_volume)
	_update_fullscreen_text()

func _start_game() -> void:
	SceneTransition.change_scene("res://Scenes/intro.tscn")

func _show_options() -> void:
	main_container.visible = false
	options_container.visible = true

func _show_main() -> void:
	main_container.visible = true
	options_container.visible = false

func _set_volume(value: float) -> void:
	# Convert 0-100 to dB (0 = -40dB, 100 = 0dB) with curve for smoother feel
	var db: float
	if value <= 0:
		db = -80.0  # Essentially mute
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)

func _toggle_fullscreen() -> void:
	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_text()

func _update_fullscreen_text() -> void:
	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_button.text = "Pantalla completa: " + ("Sí" if is_fullscreen else "No")
