extends Interactable
class_name FishingSpot

@export var reward_item: String = "key"
@export var fish_dialog: String = "¡Vaya! Una gema justo del tamaño del pedestal. ¡Esta es la mía!"

var has_been_fished: bool = false
var is_fishing: bool = false
var fishing_minigame: Node = null

func _ready() -> void:
	super._ready()
	interaction_prompt = "Pescar"

func interact() -> void:
	if has_been_fished or is_fishing:
		return

	if not Inventory.has_item("fishing_rod"):
		DialogManager.show_dialog("Aquí parece haber algo bajo el agua... pero sin caña no puedo hacer nada.", "intrigued")
		return

	_start_fishing()

func get_prompt() -> String:
	if has_been_fished:
		return ""
	if not Inventory.has_item("fishing_rod"):
		return "Pescar (necesitas caña)"
	return interaction_prompt

func _start_fishing() -> void:
	is_fishing = true

	# Create fishing minigame
	var minigame_scene = load("res://Scenes/fishing_minigame.tscn")
	fishing_minigame = minigame_scene.instantiate()
	get_tree().root.add_child(fishing_minigame)

	fishing_minigame.fishing_success.connect(_on_fishing_success)
	fishing_minigame.fishing_failed.connect(_on_fishing_failed)
	fishing_minigame.start_fishing()

func _on_fishing_success() -> void:
	has_been_fished = true

	if reward_item != "":
		Inventory.add_item(reward_item)

	DialogManager.show_dialog(fish_dialog, "surprised")

	if fishing_minigame:
		fishing_minigame.queue_free()
		fishing_minigame = null

func _on_fishing_failed() -> void:
	is_fishing = false
	DialogManager.show_dialog("¡Maldición! Se me ha escapado. Tendré que intentarlo otra vez.", "angry")

	if fishing_minigame:
		fishing_minigame.queue_free()
		fishing_minigame = null
