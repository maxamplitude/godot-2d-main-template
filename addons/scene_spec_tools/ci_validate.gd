extends SceneTree

const Validator := preload("scene_spec_validator.gd")

func _ready() -> void:
	var v := Validator.new()
	var res := v.validate_all_entities(false)

	if res.errors_total > 0:
		push_error("Scene spec validation failed (%d errors)" % res.errors_total)
		for item in res.items:
			for e in item.errors:
				print("%s: %s" % [item.path, e])
		quit(1)
		return

	print("Scene spec validation passed")
	quit(0)
