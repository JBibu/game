extends CanvasLayer

signal dialog_finished

@export var text_speed: float = 0.03
@export var chars_per_sound: int = 2
@export var continue_hint_delay: float = 2.0

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label
@onready var continue_label: Label = $Panel/ContinueLabel
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var typewriter: Typewriter
var is_active: bool = false
var can_advance: bool = false
var hint_timer: float = 0.0

func _ready() -> void:
	panel.visible = false
	label.text = ""
	continue_label.visible = false
	typewriter = Typewriter.new()
	typewriter.setup(get_tree(), text_speed, chars_per_sound)
	typewriter.character_typed.connect(_on_character_typed)
	typewriter.typing_finished.connect(_on_typing_finished)

func _process(delta: float) -> void:
	if is_active and typewriter.is_typing():
		label.text = typewriter.get_current_text()

	if can_advance and not continue_label.visible:
		hint_timer += delta
		if hint_timer >= continue_hint_delay:
			continue_label.visible = true

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		get_viewport().set_input_as_handled()
		if can_advance:
			hide_dialog()
		else:
			label.text = typewriter.skip()
			audio_player.stop()

func show_dialog(text: String) -> void:
	hint_timer = 0.0
	label.text = ""
	continue_label.visible = false
	panel.visible = true
	is_active = true
	can_advance = false
	typewriter.start(text)

func hide_dialog() -> void:
	panel.visible = false
	is_active = false
	can_advance = false
	continue_label.visible = false
	audio_player.stop()
	dialog_finished.emit()

func _on_character_typed(_char: String) -> void:
	audio_player.stop()
	audio_player.play()

func _on_typing_finished() -> void:
	can_advance = true
