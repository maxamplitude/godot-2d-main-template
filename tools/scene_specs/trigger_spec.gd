extends SceneSpec
class_name TriggerSpec

const LEVELS_DIR := "res://scenes/levels"
const BASE_LEVEL := "BaseLevel.tscn"

func spec_name() -> String:
	return "TriggerSpec"

func is_applicable(scene_path: String) -> bool:
	return scene_path.begins_with(LEVELS_DIR + "/") and not scene_path.ends_with(BASE_LEVEL)

func validate(scene_path: String, root: Node) -> Array[String]:
	var errors: Array[String] = []

	if not root.has_node("Triggers"):
		return errors

	for t in root.get_node("Triggers").get_children():
		if not (t is Area2D):
			errors.append("Trigger '%s' must be Area2D." % t.name)
			continue

		if not t.has_meta("trigger_info"):
			errors.append("Trigger '%s' missing meta 'trigger_info'." % t.name)
			continue

		var info := t.get_meta("trigger_info")
		if typeof(info) != TYPE_DICTIONARY:
			errors.append("Trigger '%s' trigger_info must be Dictionary." % t.name)
			continue

		if not info.has("id") or info["id"] == "":
			errors.append("Trigger '%s' must have non-empty 'id'." % t.name)

		if not info.has("event") or info["event"] == "":
			errors.append("Trigger '%s' must have non-empty 'event'." % t.name)

		if not info.has("once") or typeof(info["once"]) != TYPE_BOOL:
			errors.append("Trigger '%s' trigger_info must declare bool 'once'." % t.name)

		if not info.has("tags") or typeof(info["tags"]) != TYPE_ARRAY:
			errors.append("Trigger '%s' trigger_info tags must be Array." % t.name)

	return errors

func autofix(scene_path: String, root: Node) -> Array[String]:
	var fixes: Array[String] = []

	if not root.has_node("Triggers"):
		return fixes

	for t in root.get_node("Triggers").get_children():
		if not t.has_meta("trigger_info"):
			t.set_meta("trigger_info", {
				"id": "",
				"event": "",
				"once": true,
				"tags": [],
			})
			fixes.append("Added trigger_info to '%s'." % t.name)

	return fixes

