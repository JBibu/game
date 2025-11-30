extends Interactable
class_name StairTrigger

@export_file("*.tscn") var target_scene: String = ""
@export var fade_duration: float = 1.5
@export var prompt_text: String = "Subir"
@export var requires_sword: bool = false
@export var no_sword_dialog: String = "Ni loco sigo adelante sin algo con lo que defenderme. Tiene que haber algún arma por aquí..."

func _ready() -> void:
	super._ready()
	interaction_prompt = prompt_text
	interacted.connect(_on_interact)

func _on_interact() -> void:
	if target_scene.is_empty():
		push_warning("StairTrigger: No target scene set!")
		return

	if requires_sword and not Inventory.has_item("sword"):
		DialogManager.show_dialog(no_sword_dialog, "fear")
		return

	SceneTransition.change_scene(target_scene, fade_duration)
