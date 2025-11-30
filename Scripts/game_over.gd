extends CanvasLayer

@onready var label: Label = $Label
@onready var retry_label: Label = $RetryLabel

var can_continue: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_alpha(0.0)
	await _fade_in()

func _set_alpha(alpha: float) -> void:
	label.modulate.a = alpha
	retry_label.modulate.a = alpha

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	await tween.finished

	await get_tree().create_timer(0.5).timeout

	var tween2 := create_tween()
	tween2.tween_property(retry_label, "modulate:a", 1.0, 0.5)
	await tween2.finished

	can_continue = true

func _input(event: InputEvent) -> void:
	if not can_continue:
		return

	if event is InputEventKey and event.pressed:
		_restart()
	elif event is InputEventMouseButton and event.pressed:
		_restart()

func _restart() -> void:
	can_continue = false
	Inventory.clear()
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")
