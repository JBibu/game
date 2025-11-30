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
			"text": "Ugh... me duele la cabeza...",
			"emotion": "sad"
		},
		{
			"text": "¿Qué ha pasado? ¿Dónde estoy?",
			"emotion": "surprised"
		},
		{
			"text": "Esto no tiene pinta de ser Murcia... ni de lejos.",
			"emotion": "intrigued"
		},
		{
			"text": "Vale, creo que me pasé un poco con la fiesta del aniversario...",
			"emotion": "sad"
		},
		{
			"text": "Bueno, bastante. Me pasé bastante.",
			"emotion": "angry"
		},
		{
			"text": "Tengo que encontrar la manera de salir de aquí.",
			"emotion": "intrigued"
		},
	]

	dialog_box.start_dialog(dialogs, "Javi")
