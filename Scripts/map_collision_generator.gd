extends Node3D

func _ready() -> void:
	_process_mesh_nodes(self)

func _process_mesh_nodes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			mesh_instance.create_trimesh_collision()

	for child in node.get_children():
		_process_mesh_nodes(child)
