extends Node3D

@onready var dialog_box = $DialogBox

func _ready() -> void:
	_generate_environment_colliders()
	# Wait a moment before starting dialog
	await get_tree().create_timer(1.0).timeout
	_start_intro_dialog()

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
			"text": "Aagh... madre mía, qué dolor de cabeza...",
			"emotion": "sad"
		},
		{
			"text": "¿Pero qué...? ¿Dónde me he metido?",
			"emotion": "surprised"
		},
		{
			"text": "Esto desde luego no es el bar. Ni por asomo.",
			"emotion": "intrigued"
		},
		{
			"text": "A ver, igual me he pasado un pelín de rosca...",
			"emotion": "sad"
		},
		{
			"text": "Bueno, vale, bastante más que un pelín.",
			"emotion": "angry"
		},
		{
			"text": "En fin. Lo primero es lo primero: tengo que encontrar la forma de salir de este agujero.",
			"emotion": "intrigued"
		},
	]

	dialog_box.start_dialog(dialogs, "Javi")
