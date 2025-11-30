extends CanvasLayer

signal finished

@export var text_speed: float = 0.03
@export var chars_per_sound: int = 2

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var placeholder_box: ColorRect = $PlaceholderBox
@onready var placeholder_label: Label = $PlaceholderLabel
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var slides: Array[Dictionary] = []
var current_slide: int = 0
var can_advance: bool = false
var typewriter: Typewriter

func _ready() -> void:
	_set_elements_alpha(0.0)
	typewriter = Typewriter.new()
	typewriter.setup(get_tree(), text_speed, chars_per_sound)
	typewriter.character_typed.connect(_on_character_typed)
	typewriter.typing_finished.connect(_on_typing_finished)

func _process(_delta: float) -> void:
	if typewriter.is_typing():
		label.text = typewriter.get_current_text()

func setup(slide_data: Array[Dictionary]) -> void:
	slides = slide_data
	if slides.size() > 0:
		_show_slide(0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_advance()
	elif event is InputEventMouseButton and event.pressed:
		_handle_advance()

func _handle_advance() -> void:
	if typewriter.is_typing():
		label.text = typewriter.skip()
		audio_player.stop()
	elif can_advance:
		_next_slide()

func _show_slide(index: int) -> void:
	can_advance = false
	current_slide = index
	var slide = slides[index]

	await _fade_elements(0.0)

	if slide.has("image") and slide.image:
		texture_rect.texture = slide.image
	else:
		texture_rect.texture = null

	placeholder_label.text = "Placeholder " + str(index + 1)
	label.text = ""

	await _fade_elements(1.0)

	var text: String = slide.get("text", "")
	if text.length() > 0:
		typewriter.start(text)
	else:
		can_advance = true

func _next_slide() -> void:
	current_slide += 1
	if current_slide >= slides.size():
		_finish()
	else:
		_show_slide(current_slide)

func _finish() -> void:
	can_advance = false
	await _fade_elements(0.0)
	finished.emit()

func _set_elements_alpha(alpha: float) -> void:
	texture_rect.modulate.a = alpha
	label.modulate.a = alpha
	placeholder_box.modulate.a = alpha
	placeholder_label.modulate.a = alpha

func _fade_elements(target_alpha: float, duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(texture_rect, "modulate:a", target_alpha, duration)
	tween.parallel().tween_property(label, "modulate:a", target_alpha, duration)
	tween.parallel().tween_property(placeholder_box, "modulate:a", target_alpha, duration)
	tween.parallel().tween_property(placeholder_label, "modulate:a", target_alpha, duration)
	await tween.finished

func _on_character_typed(_char: String) -> void:
	audio_player.stop()
	audio_player.play()

func _on_typing_finished() -> void:
	can_advance = true
