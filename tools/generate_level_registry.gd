extends SceneTree

const LEVELS_DIR := "res://scenes/levels"
const OUTPUT_PATH := "res://levels_registry.json"
const BASE_LEVEL_SCENE := "BaseLevel.tscn"

func _init() -> void:
	var levels: Array[Dictionary] = []

	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_error("Missing levels directory: %s" % LEVELS_DIR)
		quit(1)
		return

	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if dir.current_is_dir():
			continue
		if not f.ends_with(".tscn") or f == BASE_LEVEL_SCENE:
			continue

		var path := "%s/%s" % [LEVELS_DIR, f]
		var scene := load(path)
		if scene == null:
			continue

		var root := scene.instantiate()
		var meta := root.get_node_or_null("Metadata")
		if meta == null or not meta.has_meta("level_info"):
			continue

		var info := meta.get_meta("level_info")
		if typeof(info) != TYPE_DICTIONARY:
			continue
		if not info.has("id") or not info.has("display_name") or not info.has("order"):
			continue

		levels.append({
			"id": info["id"],
			"scene": path,
			"display_name": info["display_name"],
			"order": info["order"],
			"music": info.get("music", ""),
			"tags": info.get("tags", []),
		})

	dir.list_dir_end()

	levels.sort_custom(self, "_compare_level_order")

	var data := { "levels": levels }
	var json := JSON.stringify(data, "\t")

	var f := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Failed to write registry at %s." % OUTPUT_PATH)
		quit(1)
		return

	f.store_string(json)
	f.close()

	print("Generated %s (%d levels)" % [OUTPUT_PATH, levels.size()])
	quit(0)

func _compare_level_order(a: Dictionary, b: Dictionary) -> int:
	return int(a.get("order", 0) - b.get("order", 0))

