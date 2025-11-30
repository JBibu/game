extends Node3D
class_name MazeGenerator

@export var cell_size: float = 6.0
@export var wall_height: float = 8.0
@export var maze_width: int = 8
@export var maze_height: int = 8

var _start_pos: Vector3
var _end_pos: Vector3
var _grid: Array = []  # 2D array: true = passage, false = wall

var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _ceiling_mat: StandardMaterial3D

@export var num_enemies: int = 4

func _ready() -> void:
	randomize()
	_setup_materials()
	_generate_maze()
	_build_maze()
	_place_torches()
	_spawn_enemies()

func _setup_materials() -> void:
	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.8, 0.8, 0.8)
	_wall_mat.roughness = 1.0
	if ResourceLoader.exists("res://Assets/Models/environment/Castles_and_Forts_Walls.png"):
		_wall_mat.albedo_texture = load("res://Assets/Models/environment/Castles_and_Forts_Walls.png")
		_wall_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_wall_mat.uv1_scale = Vector3(1, 1, 1)
		_wall_mat.uv1_triplanar = true
		_wall_mat.uv1_world_triplanar = true

	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = Color(0.7, 0.7, 0.7)
	_floor_mat.roughness = 1.0
	if ResourceLoader.exists("res://Assets/Models/environment/Walls.png"):
		_floor_mat.albedo_texture = load("res://Assets/Models/environment/Walls.png")
		_floor_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_floor_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
		_floor_mat.uv1_triplanar = true
		_floor_mat.uv1_world_triplanar = true

	_ceiling_mat = StandardMaterial3D.new()
	_ceiling_mat.albedo_color = Color(0.4, 0.4, 0.4)
	_ceiling_mat.roughness = 1.0
	if ResourceLoader.exists("res://Assets/Models/environment/Castles_and_Forts_Walls.png"):
		_ceiling_mat.albedo_texture = load("res://Assets/Models/environment/Castles_and_Forts_Walls.png")
		_ceiling_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_ceiling_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
		_ceiling_mat.uv1_triplanar = true
		_ceiling_mat.uv1_world_triplanar = true

func _generate_maze() -> void:
	# Grid is (2*width+1) x (2*height+1) to include walls between cells
	var grid_w: int = maze_width * 2 + 1
	var grid_h: int = maze_height * 2 + 1

	# Initialize grid - all walls
	_grid = []
	for y in range(grid_h):
		var row: Array = []
		for x in range(grid_w):
			row.append(false)
		_grid.append(row)

	# Recursive backtracker maze generation
	# Start from the end cell to ensure it's a dead-end
	var stack: Array[Vector2i] = []
	var end_cell := Vector2i(maze_width - 1, maze_height - 1)
	_set_cell(end_cell, true)
	stack.append(end_cell)

	while stack.size() > 0:
		var current: Vector2i = stack[stack.size() - 1]
		var neighbors: Array[Vector2i] = _get_unvisited_neighbors(current)

		if neighbors.size() > 0:
			var next: Vector2i = neighbors[randi() % neighbors.size()]
			# Remove wall between current and next
			var wall_x: int = current.x + next.x + 1
			var wall_y: int = current.y + next.y + 1
			_grid[wall_y][wall_x] = true
			_set_cell(next, true)
			stack.append(next)
		else:
			stack.pop_back()

	# Set start and end positions (cell centers)
	# Start cell is (0,0) -> grid position (1,1)
	_start_pos = Vector3(cell_size + cell_size / 2.0, 1, cell_size + cell_size / 2.0)
	# End cell is (maze_width-1, maze_height-1) -> grid position (maze_width*2-1, maze_height*2-1)
	var end_gx: int = (maze_width - 1) * 2 + 1
	var end_gy: int = (maze_height - 1) * 2 + 1
	_end_pos = Vector3(end_gx * cell_size + cell_size / 2.0, 1, end_gy * cell_size + cell_size / 2.0)

func _set_cell(cell: Vector2i, value: bool) -> void:
	var gx: int = cell.x * 2 + 1
	var gy: int = cell.y * 2 + 1
	_grid[gy][gx] = value

func _is_cell_visited(cell: Vector2i) -> bool:
	var gx: int = cell.x * 2 + 1
	var gy: int = cell.y * 2 + 1
	return _grid[gy][gx]

func _get_unvisited_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for dir in directions:
		var next: Vector2i = cell + dir
		if next.x >= 0 and next.x < maze_width and next.y >= 0 and next.y < maze_height:
			if not _is_cell_visited(next):
				neighbors.append(next)

	return neighbors

func _build_maze() -> void:
	var grid_w: int = maze_width * 2 + 1
	var grid_h: int = maze_height * 2 + 1

	# Build floor and ceiling for entire maze
	var total_w: float = grid_w * cell_size
	var total_h: float = grid_h * cell_size

	var floor_box := CSGBox3D.new()
	floor_box.size = Vector3(total_w, 1.0, total_h)
	floor_box.position = Vector3(total_w / 2.0, -0.5, total_h / 2.0)
	floor_box.material = _floor_mat
	floor_box.use_collision = true
	add_child(floor_box)

	var ceil_box := CSGBox3D.new()
	ceil_box.size = Vector3(total_w, 1.0, total_h)
	ceil_box.position = Vector3(total_w / 2.0, wall_height + 0.5, total_h / 2.0)
	ceil_box.material = _ceiling_mat
	ceil_box.use_collision = true
	add_child(ceil_box)

	# Build walls where grid is false
	for gy in range(grid_h):
		for gx in range(grid_w):
			if not _grid[gy][gx]:
				_add_wall_block(gx, gy)

func _add_wall_block(gx: int, gy: int) -> void:
	var wall := CSGBox3D.new()
	wall.size = Vector3(cell_size, wall_height, cell_size)
	wall.position = Vector3(
		gx * cell_size + cell_size / 2.0,
		wall_height / 2.0,
		gy * cell_size + cell_size / 2.0
	)
	wall.material = _wall_mat
	wall.use_collision = true
	add_child(wall)

func _place_torches() -> void:
	var torch_scn: PackedScene = null
	if ResourceLoader.exists("res://Scenes/torch.tscn"):
		torch_scn = load("res://Scenes/torch.tscn")
	if not torch_scn:
		return

	var grid_w: int = maze_width * 2 + 1
	var grid_h: int = maze_height * 2 + 1
	var torch_count: int = 0

	# Place torches only in cell centers (odd coordinates), not corridors
	for cy in range(maze_height):
		for cx in range(maze_width):
			var gx: int = cx * 2 + 1
			var gy: int = cy * 2 + 1

			# Skip some cells to not have too many torches
			if (cx + cy) % 2 != 0:
				continue

			# Find a wall adjacent to this cell to place torch on
			var placed := false
			for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var wx: int = gx + dir.x
				var wy: int = gy + dir.y
				if wx >= 0 and wx < grid_w and wy >= 0 and wy < grid_h:
					if not _grid[wy][wx]:  # This is a wall
						_add_torch(torch_scn, gx, gy, dir.x, dir.y)
						placed = true
						break

func _add_torch(torch_scn: PackedScene, gx: int, gy: int, dx: int, dy: int) -> void:
	var torch := torch_scn.instantiate()

	# Position in the passage cell, offset toward the wall
	var pos := Vector3(
		gx * cell_size + cell_size / 2.0 + dx * (cell_size / 2.0 - 0.15),
		2.2,
		gy * cell_size + cell_size / 2.0 + dy * (cell_size / 2.0 - 0.15)
	)
	torch.position = pos

	# Torch is vertical by default, tilt it slightly away from wall (about 20 degrees)
	var tilt: float = deg_to_rad(20)
	if dx == -1:  # Wall on left
		torch.rotation = Vector3(0, 0, -tilt)
	elif dx == 1:  # Wall on right
		torch.rotation = Vector3(0, 0, tilt)
	elif dy == -1:  # Wall behind
		torch.rotation = Vector3(tilt, 0, 0)
	elif dy == 1:  # Wall in front
		torch.rotation = Vector3(-tilt, 0, 0)

	add_child(torch)
	_make_purple(torch)

func _make_purple(torch: Node3D) -> void:
	var light := torch.get_node_or_null("TorchLight")
	if light:
		light.light_color = Color(0.8, 0.6, 1.0)

	var particles := torch.get_node_or_null("FireParticles")
	if particles and particles is GPUParticles3D:
		var mat := ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = 0.03
		mat.direction = Vector3(0, 1, 0)
		mat.spread = 15.0
		mat.initial_velocity_min = 0.3
		mat.initial_velocity_max = 0.6
		mat.gravity = Vector3(0, 0.5, 0)
		mat.scale_min = 0.5
		mat.scale_max = 1.2
		mat.color = Color(0.8, 0.5, 1.0)
		particles.process_material = mat

		var vis_mat := StandardMaterial3D.new()
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vis_mat.albedo_color = Color(0.8, 0.5, 1.0)
		vis_mat.emission_enabled = true
		vis_mat.emission = Color(0.7, 0.3, 1.0)
		vis_mat.emission_energy_multiplier = 3.0
		vis_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		particles.material_override = vis_mat

func _spawn_enemies() -> void:
	var enemy_scn: PackedScene = null
	if ResourceLoader.exists("res://Scenes/enemy.tscn"):
		enemy_scn = load("res://Scenes/enemy.tscn")
	if not enemy_scn:
		return

	# Collect all valid cell positions (not start or end)
	var valid_cells: Array[Vector2i] = []
	for cy in range(maze_height):
		for cx in range(maze_width):
			# Skip start cell (0,0) and end cell
			if cx == 0 and cy == 0:
				continue
			if cx == maze_width - 1 and cy == maze_height - 1:
				continue
			valid_cells.append(Vector2i(cx, cy))

	# Shuffle and pick cells for enemies
	valid_cells.shuffle()
	var enemies_to_spawn: int = min(num_enemies, valid_cells.size())

	for i in range(enemies_to_spawn):
		var cell: Vector2i = valid_cells[i]
		var gx: int = cell.x * 2 + 1
		var gy: int = cell.y * 2 + 1

		var enemy := enemy_scn.instantiate()
		enemy.position = Vector3(
			gx * cell_size + cell_size / 2.0,
			0,
			gy * cell_size + cell_size / 2.0
		)
		add_child(enemy)

func get_start_position() -> Vector3:
	return _start_pos

func get_end_position() -> Vector3:
	return _end_pos
