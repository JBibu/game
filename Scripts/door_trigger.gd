extends Interactable

@export var requires_key: bool = true
@export var locked_dialog: String = "Esta puerta esta cerrada. Necesito una llave."
@export var unlock_dialog: String = "La llave funciona! La puerta se ha abierto."
@export var door_node_path: NodePath

var is_unlocked: bool = false

func _ready() -> void:
	super._ready()
	interaction_prompt = "Abrir puerta"

func interact() -> void:
	if is_unlocked:
		return
	_try_open_door()

func get_prompt() -> String:
	if is_unlocked:
		return ""
	return interaction_prompt

func _try_open_door() -> void:
	if requires_key:
		if Inventory.has_key():
			Inventory.use_key()
			is_unlocked = true
			DialogManager.show_dialog(unlock_dialog)
			_open_door()
		else:
			DialogManager.show_dialog(locked_dialog)
	else:
		is_unlocked = true
		_open_door()

func _open_door() -> void:
	if door_node_path:
		var door = get_node_or_null(door_node_path)
		if door:
			var tween := create_tween()
			tween.tween_property(door, "rotation_degrees:y", door.rotation_degrees.y + 90, 0.5)
