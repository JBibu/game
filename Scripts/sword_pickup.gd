extends Interactable
class_name SwordPickup

@export var item_name: String = "sword"

func _ready() -> void:
	super._ready()
	interaction_prompt = "Recoger Espada"
	interacted.connect(_on_interact)

func _on_interact() -> void:
	Inventory.add_item(item_name)
	queue_free()
