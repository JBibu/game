extends Area3D
class_name Interactable

signal interacted

@export var interaction_prompt: String = "Interact"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(2, true)  # Layer 2 for interactables

func interact() -> void:
	interacted.emit()

func get_prompt() -> String:
	return interaction_prompt
