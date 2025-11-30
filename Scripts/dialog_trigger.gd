extends Area3D

@export var dialog_texts: Array[Dictionary] = []
@export var character_name: String = ""
@export var one_shot: bool = true

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if triggered and one_shot:
		return

	if body.is_in_group("player"):
		triggered = true
		DialogManager.start_dialog(dialog_texts, character_name)
