extends SceneSpec
class_name SpawnPointSpec

const LEVELS_DIR := "res://scenes/levels"
const BASE_LEVEL := "BaseLevel.tscn"

func spec_name() -> String:
	return "SpawnPointSpec"

func is_applicable(scene_path: String) -> bool:
	return scene_path.begins_with(LEVELS_DIR + "/") and not scene_path.ends_with(BASE_LEVEL)

func validate(scene_path: String, root: Node) -> Array[String]:
	var errors: Array[String] = []

	if not root.has_node("SpawnPoints"):
		return errors

	var sp_root := root.get_node("SpawnPoints")
	for child in sp_root.get_children():
		if not (child is Node2D):
			errors.append("SpawnPoints child '%s' must be Node2D." % child.name)
			continue

		if not child.name.begins_with("Spawn_"):
			errors.append("SpawnPoint '%s' must start with 'Spawn_'." % child.name)

		if not child.has_meta("spawn_info"):
			errors.append("SpawnPoint '%s' missing meta 'spawn_info'." % child.name)
			continue

		var info := child.get_meta("spawn_info")
		if typeof(info) != TYPE_DICTIONARY:
			errors.append("SpawnPoint '%s' spawn_info must be Dictionary." % child.name)
			continue

		if not info.has("type") or info["type"] == "":
			errors.append("SpawnPoint '%s' spawn_info missing 'type'." % child.name)

		if not info.has("scene"):
			errors.append("SpawnPoint '%s' spawn_info missing 'scene'." % child.name)

		if not info.has("tags") or typeof(info["tags"]) != TYPE_ARRAY:
			errors.append("SpawnPoint '%s' spawn_info tags must be Array." % child.name)

	return errors

func autofix(scene_path: String, root: Node) -> Array[String]:
	var fixes: Array[String] = []

	if not root.has_node("SpawnPoints"):
		return fixes

	for sp in root.get_node("SpawnPoints").get_children():
		if not sp.has_meta("spawn_info"):
			sp.set_meta("spawn_info", {
				"type": "",
				"id": "",
				"scene": "",
				"tags": [],
			})
			fixes.append("Added spawn_info to '%s'." % sp.name)

	return fixes

