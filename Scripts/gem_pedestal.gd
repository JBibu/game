extends Interactable
class_name GemPedestal

@export var required_gem: String = "gem"
@export var no_gem_dialog: String = "Hay una hendidura con forma extraña... Parece que falta algo aquí."
@export var place_gem_dialog: String = "La gema encaja a la perfección. Un estruendo retumba mientras el muro comienza a descender..."
@export var wall_node_path: NodePath

var gem_placed: bool = false
var gem_mesh: MeshInstance3D = null

func _ready() -> void:
	super._ready()
	interaction_prompt = "Colocar gema"
	_create_pedestal_mesh()

func _create_pedestal_mesh() -> void:
	# Pedestal base
	var pedestal := CSGCylinder3D.new()
	pedestal.radius = 0.4
	pedestal.height = 1.0
	pedestal.sides = 8
	var pedestal_mat := StandardMaterial3D.new()
	pedestal_mat.albedo_color = Color(0.3, 0.25, 0.2)
	pedestal.material = pedestal_mat
	add_child(pedestal)

	# Top plate
	var top := CSGCylinder3D.new()
	top.radius = 0.5
	top.height = 0.1
	top.sides = 8
	top.position.y = 0.55
	top.material = pedestal_mat
	add_child(top)

	# Gem slot (dark indent)
	var slot := CSGCylinder3D.new()
	slot.radius = 0.15
	slot.height = 0.1
	slot.sides = 6
	slot.position.y = 0.61
	var slot_mat := StandardMaterial3D.new()
	slot_mat.albedo_color = Color(0.1, 0.1, 0.1)
	slot.material = slot_mat
	add_child(slot)

func interact() -> void:
	if gem_placed:
		return

	if not Inventory.has_item(required_gem):
		DialogManager.show_dialog(no_gem_dialog)
		return

	_place_gem()

func get_prompt() -> String:
	if gem_placed:
		return ""
	if not Inventory.has_item(required_gem):
		return "Colocar gema (no tienes)"
	return interaction_prompt

func _place_gem() -> void:
	Inventory.remove_item(required_gem)
	gem_placed = true

	# Create visible gem
	gem_mesh = MeshInstance3D.new()
	var gem_shape := PrismMesh.new()
	gem_shape.size = Vector3(0.25, 0.3, 0.25)
	gem_mesh.mesh = gem_shape
	gem_mesh.position.y = 0.75

	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.2, 0.8, 0.4)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.1, 0.5, 0.2)
	gem_mat.emission_energy_multiplier = 2.0
	gem_mesh.set_surface_override_material(0, gem_mat)
	add_child(gem_mesh)

	# Add light
	var gem_light := OmniLight3D.new()
	gem_light.light_color = Color(0.2, 0.9, 0.4)
	gem_light.light_energy = 1.5
	gem_light.omni_range = 4.0
	gem_light.position.y = 0.8
	add_child(gem_light)

	DialogManager.show_dialog(place_gem_dialog)

	# Open the wall/passage
	_open_wall()

var shake_tween: Tween = null

func _open_wall() -> void:
	if wall_node_path.is_empty():
		return

	var wall = get_node_or_null(wall_node_path)
	if wall:
		# Start screen shake
		_start_screen_shake()

		# Slow wall descent
		var tween := create_tween()
		tween.tween_property(wall, "position:y", wall.position.y - 5, 4.0).set_ease(Tween.EASE_IN_OUT)

		await tween.finished
		_stop_screen_shake()

func _start_screen_shake() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	shake_tween = create_tween()
	shake_tween.set_loops(0)  # Infinite loops

	var intensity = 0.03
	shake_tween.tween_property(camera, "h_offset", intensity, 0.025)
	shake_tween.tween_property(camera, "h_offset", -intensity, 0.025)
	shake_tween.tween_property(camera, "v_offset", intensity, 0.025)
	shake_tween.tween_property(camera, "v_offset", -intensity, 0.025)

func _stop_screen_shake() -> void:
	if shake_tween:
		shake_tween.kill()
		shake_tween = null

	var camera = get_viewport().get_camera_3d()
	if camera:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
