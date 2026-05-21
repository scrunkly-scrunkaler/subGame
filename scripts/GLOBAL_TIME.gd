extends Node

const ROLLOVER_SECONDS: float = 3600.0
var time: float = 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(delta: float) -> void:
	time = fmod(time + delta, ROLLOVER_SECONDS)
