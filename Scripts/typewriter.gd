class_name Typewriter
extends RefCounted

signal character_typed(char: String)
signal typing_finished

var text_speed: float = 0.03
var chars_per_sound: int = 2

var _full_text: String = ""
var _current_char: int = 0
var _char_count: int = 0
var _is_typing: bool = false
var _scene_tree: SceneTree

func setup(scene_tree: SceneTree, speed: float = 0.03, sound_interval: int = 2) -> void:
	_scene_tree = scene_tree
	text_speed = speed
	chars_per_sound = sound_interval

func start(text: String) -> void:
	_full_text = text
	_current_char = 0
	_char_count = 0
	_is_typing = true
	_type_next_char()

func skip() -> String:
	_is_typing = false
	_current_char = _full_text.length()
	typing_finished.emit()
	return _full_text

func is_typing() -> bool:
	return _is_typing

func get_current_text() -> String:
	return _full_text.substr(0, _current_char)

func _type_next_char() -> void:
	if not _is_typing:
		return

	if _current_char >= _full_text.length():
		_is_typing = false
		typing_finished.emit()
		return

	var c := _full_text[_current_char]
	_current_char += 1

	if c != " " and c != "\n":
		_char_count += 1
		if _char_count >= chars_per_sound:
			_char_count = 0
			character_typed.emit(c)

	_scene_tree.create_timer(text_speed).timeout.connect(_type_next_char)
