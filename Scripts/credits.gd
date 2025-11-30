extends CanvasLayer

signal finished

func _ready() -> void:
	finished.connect(_on_finished)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		finished.emit()
	elif event is InputEventMouseButton and event.pressed:
		finished.emit()

func _on_finished() -> void:
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")
