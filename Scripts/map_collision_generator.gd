extends Node3D

@export var uv_scale: Vector3 = Vector3(10, 10, 1)

func _ready() -> void:
	_process_mesh_nodes(self)

func _process_mesh_nodes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			mesh_instance.create_trimesh_collision()
			_apply_texture_tiling(mesh_instance)

	for child in node.get_children():
		_process_mesh_nodes(child)

func _apply_texture_tiling(mesh_instance: MeshInstance3D) -> void:
	for i in range(mesh_instance.get_surface_override_material_count()):
		var original_mat = mesh_instance.mesh.surface_get_material(i)
		if original_mat and original_mat is StandardMaterial3D:
			var new_mat = original_mat.duplicate() as StandardMaterial3D
			new_mat.uv1_scale = uv_scale
			mesh_instance.set_surface_override_material(i, new_mat)
