extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
var tween: Tween

func _ready() -> void:
	color_rect.color = Color(0, 0, 0, 1)
	fade_in()

func fade_in(duration: float = 1.5) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)

func fade_out(duration: float = 1.5) -> Signal:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	return tween.finished

func change_scene(scene_path: String, fade_duration: float = 1.5) -> void:
	await fade_out(fade_duration)
	get_tree().change_scene_to_file(scene_path)
	fade_in(fade_duration)
