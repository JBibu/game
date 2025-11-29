extends CanvasLayer

signal dialog_finished

@export var text_speed: float = 0.03
@export var chars_per_sound: int = 2

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var full_text: String = ""
var current_char: int = 0
var char_count: int = 0
var is_active: bool = false
var can_advance: bool = false

func _ready() -> void:
	panel.visible = false
	label.text = ""

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("ui_accept"):
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
	label.text = ""
	panel.visible = true
	is_active = true
	can_advance = false
	_type_next_char()

func hide_dialog() -> void:
	panel.visible = false
	is_active = false
	can_advance = false
	audio_player.stop()
	dialog_finished.emit()

func _type_next_char() -> void:
	if current_char >= full_text.length():
		can_advance = true
		return

	var char := full_text[current_char]
	label.text += char
	current_char += 1

	# Play sound every N non-space characters
	if char != " " and char != "\n":
		char_count += 1
		if char_count >= chars_per_sound:
			char_count = 0
			audio_player.stop()
			audio_player.play()

	# Schedule next character
	get_tree().create_timer(text_speed).timeout.connect(_type_next_char)
