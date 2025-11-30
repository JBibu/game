extends Interactable
class_name FishingRodPickup

@export var item_name: String = "fishing_rod"

func _ready() -> void:
	super._ready()
	interaction_prompt = "Recoger Caña de Pescar"
	interacted.connect(_on_interact)

func _on_interact() -> void:
	Inventory.add_item(item_name)
	DialogManager.show_dialog("¡Una caña de pescar! Vete tú a saber cómo ha llegado aquí. Igual puedo sacarle partido en algún estanque.")
	queue_free()
