extends Interactable
class_name Chest

@export var item_name: String = "key"
@export var dialog_text: String = "Has encontrado una llave!"

var is_opened: bool = false

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	super._ready()
	interaction_prompt = "Abrir cofre"

func interact() -> void:
	if is_opened:
		return
	_open_chest()

func get_prompt() -> String:
	if is_opened:
		return ""
	return interaction_prompt

func _open_chest() -> void:
	is_opened = true
	_give_item()
	_show_dialog()
	_open_animation()

func _give_item() -> void:
	if item_name == "key":
		Inventory.add_key()

func _show_dialog() -> void:
	DialogManager.show_dialog(dialog_text)

func _open_animation() -> void:
	var tween := create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.2, 0.3, 1.2), 0.2)
	tween.tween_property(mesh, "scale", Vector3(1, 0.5, 1), 0.1)
