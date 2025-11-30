extends Control

@onready var logo: TextureRect = $CenterContainer/Logo

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_play_intro()

func _play_intro() -> void:
	# Fade in logo
	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 1.0)

	# Hold
	tween.tween_interval(2.0)

	# Fade out logo
	tween.tween_property(logo, "modulate:a", 0.0, 1.0)

	# Go to main menu
	tween.tween_callback(_go_to_menu)

func _go_to_menu() -> void:
	SceneTransition.change_scene("res://Scenes/main_menu.tscn", 0.5)

func _input(event: InputEvent) -> void:
	# Allow skipping with any key or click
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_go_to_menu()
