extends Node3D

@export var camera_far_clip: float = 25.0

@onready var dialog_box = $DialogBox
@onready var maze = $Maze

func _ready() -> void:
	_setup_camera()
	_ensure_sword()
	# Wait for maze to build before positioning player
	await get_tree().process_frame
	await get_tree().process_frame
	_position_player()
	_setup_exit()
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

func _position_player() -> void:
	var player = $ThirdPersonCharacter
	if player and maze:
		player.global_position = maze.get_start_position()

func _setup_exit() -> void:
	if not maze:
		return

	var exit_pos: Vector3 = maze.get_end_position()

	# Create exit trigger
	var stair_scene: PackedScene = load("res://Scenes/stair_trigger.tscn")
	var exit_trigger: Node3D = stair_scene.instantiate()
	exit_trigger.position = exit_pos
	exit_trigger.target_scene = "res://Scenes/ending.tscn"
	exit_trigger.prompt_text = "Escapar"
	add_child(exit_trigger)

	# Add a glowing marker at exit
	var exit_light := OmniLight3D.new()
	exit_light.light_color = Color(0.2, 1.0, 0.3)
	exit_light.light_energy = 2.0
	exit_light.omni_range = 8.0
	exit_light.position = exit_pos + Vector3(0, 2, 0)
	add_child(exit_light)

func _start_intro_dialog() -> void:
	var dialogs: Array[Dictionary] = [
		{
			"text": "Un laberinto... Esto no pinta nada bien.",
			"emotion": "fear"
		},
		{
			"text": "Tengo que encontrar la salida. Rápido.",
			"emotion": "intrigued"
		},
	]

	dialog_box.start_dialog(dialogs, "Javi")
