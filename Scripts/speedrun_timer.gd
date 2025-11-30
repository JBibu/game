extends Node

var start_time: int = 0
var end_time: int = 0
var is_running: bool = false

func start_timer() -> void:
	start_time = Time.get_ticks_msec()
	is_running = true

func stop_timer() -> void:
	end_time = Time.get_ticks_msec()
	is_running = false

func get_elapsed_ms() -> int:
	if is_running:
		return Time.get_ticks_msec() - start_time
	return end_time - start_time

func get_formatted_time() -> String:
	var elapsed := get_elapsed_ms()
	var minutes := elapsed / 60000
	var seconds := (elapsed % 60000) / 1000
	var milliseconds := elapsed % 1000
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

func reset() -> void:
	start_time = 0
	end_time = 0
	is_running = false
