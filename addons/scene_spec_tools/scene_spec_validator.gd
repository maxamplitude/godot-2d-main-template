@tool
extends RefCounted

# Configure where you keep entity scenes.
# You can set this to "res://scenes" or a narrower folder.
const ENTITY_SCENE_ROOT := "res://scenes/entities"

# Spec constants
const REQUIRED_CHILDREN := ["Visuals", "Collision", "Logic", "Metadata"]
const REQUIRED_GROUPS := ["entities"]

const DEFAULT_LOGIC_SCRIPT := "res://scripts/entities/base_entity_logic.gd"

class ResultItem:
	var path: String
	var errors: Array[String] = []
	var fixes: Array[String] = []

class Summary:
	var checked: int = 0
	var fixed: int = 0
	var errors_total: int = 0
	var items: Array = []

func validate_all_entities(do_fix: bool) -> Summary:
	var s := Summary.new()

	var scene_paths := _find_tscn_files_recursive(ENTITY_SCENE_ROOT)
	scene_paths.sort()

	for p in scene_paths:
		# Skip base template scene itself if you want:
		# if p == "res://scenes/entities/BaseEntity.tscn":
		# 	continue

		s.checked += 1
		var item := _validate_one(p, do_fix)
		s.items.append(item)
		s.errors_total += item.errors.size()
		if not item.fixes.is_empty():
			s.fixed += 1

	return s

func _validate_one(scene_path: String, do_fix: bool) -> ResultItem:
	var item := ResultItem.new()
	item.path = scene_path

	var ps: PackedScene = load(scene_path)
	if ps == null:
		item.errors.append("Could not load PackedScene.")
		return item

	var inst := ps.instantiate()
	if inst == null:
		item.errors.append("Could not instantiate scene.")
		return item

	# 1) Root type must be Node2D (2D-only for now)
	if not (inst is Node2D):
		item.errors.append("Root must be Node2D (found: %s)." % inst.get_class())
		# auto-fix can't safely change root type; bail early
		return item

	# 2) Root name must match file basename
	var want_name := scene_path.get_file().get_basename()
	if inst.name != want_name:
		item.errors.append("Root name '%s' must match scene name '%s'." % [inst.name, want_name])
		if do_fix:
			inst.name = want_name
			item.fixes.append("Renamed root to '%s'." % want_name)

	# 3) Required children
	for child_name in REQUIRED_CHILDREN:
		if not inst.has_node(child_name):
			item.errors.append("Missing required child node: %s" % child_name)
			if do_fix:
				var n := _make_required_child(child_name)
				inst.add_child(n)
				n.owner = inst
				item.fixes.append("Added missing node '%s' (%s)." % [child_name, n.get_class()])

	# Re-fetch nodes after possible creation
	var visuals := inst.get_node_or_null("Visuals")
	var collision := inst.get_node_or_null("Collision")
	var logic := inst.get_node_or_null("Logic")
	var metadata := inst.get_node_or_null("Metadata")

	# 4) Ensure child node types (soft enforcement)
	# Visuals/Collision should be Node2D; Metadata can be Node; Logic should be Node
	if visuals != null and not (visuals is Node2D):
		item.errors.append("Visuals should be Node2D (found: %s)." % visuals.get_class())

	if collision != null and not (collision is Node2D):
		item.errors.append("Collision should be Node2D (found: %s)." % collision.get_class())

	if logic != null and not (logic is Node):
		item.errors.append("Logic should be Node (found: %s)." % logic.get_class())

	# 5) Ensure groups on root
	for g in REQUIRED_GROUPS:
		if not inst.is_in_group(g):
			item.errors.append("Root missing group '%s'." % g)
			if do_fix:
				inst.add_to_group(g)
				item.fixes.append("Added root to group '%s'." % g)

	# 6) Logic must have a script (default to BaseEntityLogic if missing)
	if logic == null:
		item.errors.append("Logic node missing (unexpected after required node fix).")
	else:
		if logic.get_script() == null:
			item.errors.append("Logic node has no script.")
			if do_fix:
				var scr := load(DEFAULT_LOGIC_SCRIPT)
				if scr == null:
					item.errors.append("Cannot auto-fix: default logic script not found at %s" % DEFAULT_LOGIC_SCRIPT)
				else:
					logic.set_script(scr)
					item.fixes.append("Attached default logic script to Logic.")

	# 7) Optional: encourage category groups (not enforced here)
	# You can add: if entity_info["category"] == "enemy" -> group "enemies"

	# If we fixed anything, resave
	if do_fix and not item.fixes.is_empty():
		var new_ps := PackedScene.new()
		var ok := new_ps.pack(inst)
		if not ok:
			item.errors.append("Failed to pack scene after auto-fix.")
		else:
			var err := ResourceSaver.save(new_ps, scene_path)
			if err != OK:
				item.errors.append("Failed to save scene: %s" % error_string(err))
			else:
				item.fixes.append("Saved scene.")

	inst.queue_free()
	return item

func _make_required_child(name: String) -> Node:
	match name:
		"Visuals":
			var n := Node2D.new()
			n.name = "Visuals"
			return n
		"Collision":
			var n := Node2D.new()
			n.name = "Collision"
			return n
		"Logic":
			var n := Node.new()
			n.name = "Logic"
			return n
		"Metadata":
			var n := Node.new()
			n.name = "Metadata"
			return n
		_:
			var n := Node.new()
			n.name = name
			return n

func _find_tscn_files_recursive(root: String) -> Array[String]:
	var out: Array[String] = []
	_walk(root, out)
	return out

func _walk(dir_path: String, out: Array[String]) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return

	da.list_dir_begin()
	while true:
		var name := da.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue

		var full := dir_path.path_join(name)
		if da.current_is_dir():
			_walk(full, out)
		else:
			if name.ends_with(".tscn"):
				out.append(full)
	da.list_dir_end()
