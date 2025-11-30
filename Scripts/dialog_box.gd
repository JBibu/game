extends CanvasLayer

signal dialog_finished

@export var text_speed: float = 0.03
@export var chars_per_sound: int = 2
@export var continue_hint_delay: float = 1.5
@export var letterbox_anim_speed: float = 8.0

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/HBoxContainer/VBoxContainer/MarginContainer/VBox/Label
@onready var continue_label: Label = $Panel/ContinueIndicator/ContinueLabel
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var portrait: TextureRect = $Panel/HBoxContainer/Portrait
@onready var name_label: Label = $Panel/HBoxContainer/VBoxContainer/MarginContainer/VBox/NameLabel
@onready var top_bar: ColorRect = $TopBar
@onready var bottom_bar: ColorRect = $BottomBar

var typewriter: Typewriter
var is_active: bool = false
var can_advance: bool = false
var hint_timer: float = 0.0
var indicator_bob_time: float = 0.0

var dialogs: Array[Dictionary] = []
var current_dialog_index: int = 0
var current_character: String = ""

var emotion_textures: Dictionary = {}

var letterbox_target: float = 0.0
var letterbox_current: float = 0.0
var panel_alpha_target: float = 0.0
var is_closing: bool = false

func _ready() -> void:
	panel.visible = false
	panel.modulate.a = 0.0
	label.text = ""
	continue_label.visible = false
	if portrait:
		portrait.visible = false
	if name_label:
		name_label.visible = false
	if top_bar:
		top_bar.offset_bottom = 0.0
	if bottom_bar:
		bottom_bar.offset_top = 0.0
	typewriter = Typewriter.new()
	typewriter.setup(get_tree(), text_speed, chars_per_sound)
	typewriter.character_typed.connect(_on_character_typed)
	typewriter.typing_finished.connect(_on_typing_finished)
	_load_emotion_textures()

func _load_emotion_textures() -> void:
	var emotions = ["angry", "fear", "happy", "idle", "intrigued", "sad", "surprised"]
	for emotion in emotions:
		var path = "res://Assets/Sprites/javi_sprites_1/" + emotion + ".png"
		if ResourceLoader.exists(path):
			emotion_textures[emotion] = load(path)

func _process(delta: float) -> void:
	if is_active and typewriter.is_typing():
		label.text = typewriter.get_current_text()

	if can_advance and not continue_label.visible:
		hint_timer += delta
		if hint_timer >= continue_hint_delay:
			continue_label.visible = true

	if continue_label.visible:
		indicator_bob_time += delta * 3.0
		continue_label.position.y = sin(indicator_bob_time) * 3.0

	letterbox_current = lerp(letterbox_current, letterbox_target, delta * letterbox_anim_speed)
	if top_bar:
		top_bar.offset_bottom = letterbox_current
	if bottom_bar:
		bottom_bar.offset_top = -letterbox_current

	panel.modulate.a = lerp(panel.modulate.a, panel_alpha_target, delta * letterbox_anim_speed)

	if is_closing and panel.modulate.a < 0.01:
		panel.visible = false
		panel.modulate.a = 0.0
		is_closing = false

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	var should_advance = false

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		should_advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		should_advance = true

	if should_advance:
		get_viewport().set_input_as_handled()
		if can_advance:
			_advance_dialog()
		else:
			label.text = typewriter.skip()
			audio_player.stop()

func start_dialog(dialog_array: Array[Dictionary], character_name: String = "") -> void:
	dialogs = dialog_array
	current_dialog_index = 0
	current_character = character_name

	if dialogs.size() > 0:
		_show_current_dialog()

func show_dialog(text: String) -> void:
	dialogs = [{"text": text}]
	current_dialog_index = 0
	current_character = ""
	_show_current_dialog()

func _show_current_dialog() -> void:
	if current_dialog_index >= dialogs.size():
		hide_dialog()
		return

	var dialog = dialogs[current_dialog_index]
	var text = dialog.get("text", "")
	var emotion = dialog.get("emotion", "idle")

	hint_timer = 0.0
	indicator_bob_time = 0.0
	label.text = ""
	continue_label.visible = false
	continue_label.position.y = 0.0
	panel.visible = true
	is_active = true
	is_closing = false
	can_advance = false
	letterbox_target = 60.0
	panel_alpha_target = 1.0

	if portrait and emotion_textures.has(emotion):
		portrait.texture = emotion_textures[emotion]
		portrait.visible = true
	elif portrait:
		portrait.visible = false

	if name_label and current_character != "":
		name_label.text = current_character
		name_label.visible = true
	elif name_label:
		name_label.visible = false

	typewriter.start(text)

func _advance_dialog() -> void:
	current_dialog_index += 1
	if current_dialog_index >= dialogs.size():
		hide_dialog()
	else:
		_show_current_dialog()

func hide_dialog() -> void:
	is_active = false
	is_closing = true
	can_advance = false
	continue_label.visible = false
	letterbox_target = 0.0
	panel_alpha_target = 0.0
	audio_player.stop()
	dialogs = []
	current_dialog_index = 0
	dialog_finished.emit()

func _on_character_typed(_char: String) -> void:
	audio_player.stop()
	audio_player.play()

func _on_typing_finished() -> void:
	can_advance = true
