extends Node
class_name DebugManager

var enabled := true

func toggle() -> void:
	enabled = !enabled

func log(msg: String) -> void:
	if enabled:
		print("[DEBUG] ", msg)
