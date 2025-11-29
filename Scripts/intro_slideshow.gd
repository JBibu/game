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
var is_typing: bool = false
var full_text: String = ""
var current_char: int = 0
var char_count: int = 0

func _ready() -> void:
	_set_elements_alpha(0.0)

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
	if is_typing:
		_skip_typing()
	elif can_advance:
		_next_slide()

func _skip_typing() -> void:
	current_char = full_text.length()
	label.text = full_text
	is_typing = false
	can_advance = true
	audio_player.stop()

func _show_slide(index: int) -> void:
	can_advance = false
	is_typing = false
	current_slide = index
	var slide = slides[index]

	await _fade_elements(0.0)

	if slide.has("image") and slide.image:
		texture_rect.texture = slide.image
	else:
		texture_rect.texture = null

	placeholder_label.text = "Placeholder " + str(index + 1)
	label.text = ""
	full_text = slide.get("text", "")
	current_char = 0
	char_count = 0

	await _fade_elements(1.0)

	if full_text.length() > 0:
		is_typing = true
		_type_next_char()
	else:
		can_advance = true

func _type_next_char() -> void:
	if not is_typing:
		return

	if current_char >= full_text.length():
		is_typing = false
		can_advance = true
		return

	var c := full_text[current_char]
	label.text += c
	current_char += 1

	if c != " " and c != "\n":
		char_count += 1
		if char_count >= chars_per_sound:
			char_count = 0
			audio_player.stop()
			audio_player.play()

	get_tree().create_timer(text_speed).timeout.connect(_type_next_char)

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
