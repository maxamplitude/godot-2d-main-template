@tool
extends RefCounted

const SceneSpecConstants := preload("res://tools/scene_specs/scene_spec_constants.gd")

func create_from_json(json_path: String) -> String:
	var txt := FileAccess.get_file_as_string(json_path)
	var data := JSON.parse_string(txt)

	var tpl := data["template"]
	var name := data["name"]

	var scene_path := "%s/%s.tscn" % [
		SceneSpecConstants.ENTITY_SCENE_ROOT,
		name
	]

	var base := load(
		"%s/%s" % [SceneSpecConstants.ENTITY_TEMPLATE_ROOT, tpl]
	).instantiate()

	base.name = name

	var logic := base.get_node("Logic")
	logic.entity_info = {
		"id": name.to_snake_case(),
		"category": data.get("category", ""),
		"tags": data.get("tags", []),
		"version": SceneSpecConstants.DEFAULT_ENTITY_VERSION
	}

	# Optional overrides
	for k in data.get("overrides", {}).keys():
		if logic.has_variable(k):
			logic.set(k, data["overrides"][k])

	var ps := PackedScene.new()
	ps.pack(base)
	ResourceSaver.save(ps, scene_path)

	return scene_path
