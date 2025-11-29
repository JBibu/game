extends CanvasLayer

signal dialog_finished

@export var text_speed: float = 0.03
@export var chars_per_sound: int = 2
@export var continue_hint_delay: float = 2.0

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label
@onready var continue_label: Label = $Panel/ContinueLabel
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var full_text: String = ""
var current_char: int = 0
var char_count: int = 0
var is_active: bool = false
var can_advance: bool = false
var hint_timer: float = 0.0

func _ready() -> void:
	panel.visible = false
	label.text = ""
	continue_label.visible = false

func _process(delta: float) -> void:
	if can_advance and not continue_label.visible:
		hint_timer += delta
		if hint_timer >= continue_hint_delay:
			continue_label.visible = true

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if can_advance:
			hide_dialog()
		else:
			# Skip to end
			current_char = full_text.length()
			label.text = full_text
			can_advance = true
			audio_player.stop()

func show_dialog(text: String) -> void:
	full_text = text
	current_char = 0
	char_count = 0
	hint_timer = 0.0
	label.text = ""
	continue_label.visible = false
	panel.visible = true
	is_active = true
	can_advance = false
	_type_next_char()

func hide_dialog() -> void:
	panel.visible = false
	is_active = false
	can_advance = false
	continue_label.visible = false
	audio_player.stop()
	dialog_finished.emit()

func _type_next_char() -> void:
	if current_char >= full_text.length():
		can_advance = true
		return

	var c := full_text[current_char]
	label.text += c
	current_char += 1

	# Play sound every N non-space characters
	if c != " " and c != "\n":
		char_count += 1
		if char_count >= chars_per_sound:
			char_count = 0
			audio_player.stop()
			audio_player.play()

	# Schedule next character
	get_tree().create_timer(text_speed).timeout.connect(_type_next_char)
