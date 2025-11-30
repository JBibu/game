extends Node3D

@export var camera_far_clip: float = 40.0

@onready var dialog_box = $DialogBox

func _ready() -> void:
	_generate_environment_colliders()
	_setup_camera()
	_ensure_sword()
	await get_tree().create_timer(1.0).timeout
	_start_intro_dialog()

func _setup_camera() -> void:
	var camera = $ThirdPersonCharacter/CameraPivot/Camera3D
	if camera:
		camera.far = camera_far_clip

func _ensure_sword() -> void:
	if not Inventory.has_item("sword"):
		Inventory.add_item("sword")
		Inventory.equip_sword()

func _generate_environment_colliders() -> void:
	# Generate colliders for all direct MeshInstance3D children (environment props)
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			if mesh_instance.mesh:
				mesh_instance.create_trimesh_collision()

func _start_intro_dialog() -> void:
	var dialogs: Array[Dictionary] = [
		{
			"text": "Madre mía, qué humedad hay aquí...",
			"emotion": "sad"
		},
		{
			"text": "Pero creo que veo algo de luz más adelante. ¡Ya queda menos!",
			"emotion": "intrigued"
		},
	]

	dialog_box.start_dialog(dialogs, "Adán")
