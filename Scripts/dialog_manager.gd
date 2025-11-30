extends Node

var dialog_box: Node = null

func register_dialog_box(box: Node) -> void:
	dialog_box = box

func show_dialog(text: String, emotion: String = "") -> void:
	if dialog_box and dialog_box.has_method("show_dialog"):
		dialog_box.show_dialog(text, emotion)

func start_dialog(dialog_array: Array[Dictionary], character_name: String = "") -> void:
	if dialog_box and dialog_box.has_method("start_dialog"):
		dialog_box.start_dialog(dialog_array, character_name)

func is_active() -> bool:
	if dialog_box and dialog_box.has_method("is_dialog_active"):
		return dialog_box.is_dialog_active()
	return false
