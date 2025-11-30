extends Node3D

@export var camera_far_clip: float = 40.0

@onready var dialog_box = $DialogBox

func _ready() -> void:
	_generate_environment_colliders()
	_setup_camera()
	_ensure_sword()

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
