extends Interactable
class_name StairTrigger

@export_file("*.tscn") var target_scene: String = ""
@export var fade_duration: float = 1.5

func _ready() -> void:
	super._ready()
	interaction_prompt = "Subir"
	interacted.connect(_on_interact)

func _on_interact() -> void:
	if target_scene.is_empty():
		push_warning("StairTrigger: No target scene set!")
		return
	SceneTransition.change_scene(target_scene, fade_duration)
