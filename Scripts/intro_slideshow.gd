extends CanvasLayer

signal finished

@export var text_speed: float = 0.03
@export var chars_per_sound: int = 2

@onready var label: Label = $Label
@onready var slide_image: TextureRect = $SlideImage
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
	var slide = slides[index]

	var new_image = slide.image if slide.has("image") else null
	var old_image = slide_image.texture
	var image_changed = (index == 0) or (new_image != old_image)

	current_slide = index

	if image_changed:
		await _fade_elements(0.0)
	else:
		await _fade_text(0.0)

	if slide.has("image") and slide.image:
		slide_image.texture = slide.image
	else:
		slide_image.texture = null

	label.text = ""

	if image_changed:
		await _fade_elements(1.0)
	else:
		await _fade_text(1.0)

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
	label.modulate.a = alpha
	slide_image.modulate.a = alpha

func _fade_elements(target_alpha: float, duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", target_alpha, duration)
	tween.parallel().tween_property(slide_image, "modulate:a", target_alpha, duration)
	await tween.finished

func _fade_text(target_alpha: float, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", target_alpha, duration)
	await tween.finished

func _on_character_typed(_char: String) -> void:
	audio_player.stop()
	audio_player.play()

func _on_typing_finished() -> void:
	can_advance = true
