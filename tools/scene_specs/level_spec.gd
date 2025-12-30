extends SceneSpec
class_name LevelSpec

const SceneSpecConstants := preload("res://tools/scene_specs/scene_spec_constants.gd")
const LEVELS_DIR := SceneSpecConstants.LEVELS_DIR
const REQUIRED_CHILDREN := SceneSpecConstants.LEVEL_REQUIRED_CHILDREN
const BASE_LEVEL_SCENE := SceneSpecConstants.BASE_LEVEL_SCENE
const BASE_LEVEL_LOGIC := SceneSpecConstants.BASE_LEVEL_LOGIC

# Metadata contract (stored on Metadata node as a script-less Node with exported dict elsewhere).
const REQUIRED_LEVEL_INFO_KEYS := SceneSpecConstants.LEVEL_METADATA_KEYS

func spec_name() -> String:
    return "LevelSpec"

func is_applicable(scene_path: String) -> bool:
    return scene_path.begins_with(LEVELS_DIR + "/") and scene_path.ends_with(".tscn") and scene_path.get_file() != "BaseLevel.tscn"

func validate(scene_path: String, root: Node) -> Array[String]:
    var errors: Array[String] = []

    # Root name must match file basename
    var expected := scene_path.get_file().get_basename()
    if root.name != expected:
        errors.append("Root name '%s' must match scene filename '%s'." % [root.name, expected])

    # Required children
    for name in REQUIRED_CHILDREN:
        if not root.has_node(name):
            errors.append("Missing required child node: %s" % name)

    # Logic must have a script
    if root.has_node("Logic"):
        var logic := root.get_node("Logic")
        if logic.get_script() == null:
            errors.append("Logic node has no script (expected BaseLevelLogic).")

    # Metadata should have level_info set as metadata (we store it as Node metadata to avoid script on Metadata)
    if root.has_node("Metadata"):
        var meta := root.get_node("Metadata")
        if not meta.has_meta("level_info"):
            errors.append("Metadata node missing meta 'level_info' Dictionary.")
        else:
            var info = meta.get_meta("level_info")
            if typeof(info) != TYPE_DICTIONARY:
                errors.append("Metadata meta 'level_info' must be a Dictionary.")
            else:
                for k in REQUIRED_LEVEL_INFO_KEYS:
                    if not info.has(k):
                        errors.append("Metadata level_info missing key: %s" % k)

    # Enforce “no scripts outside Logic” (strict, but worth it)
    _validate_no_scripts_outside_logic(root, errors)

    return errors

func autofix(scene_path: String, root: Node) -> Array[String]:
    var fixes: Array[String] = []

    # Add missing children
    for name in REQUIRED_CHILDREN:
        if not root.has_node(name):
            var node: Node
            match name:
                "Logic", "Metadata":
                    node = Node.new()
                _:
                    node = Node2D.new()
            node.name = name
            root.add_child(node)
            node.owner = root
            fixes.append("Added missing node '%s'." % name)

    # Fix Logic script if missing
    if root.has_node("Logic"):
        var logic := root.get_node("Logic")
        if logic.get_script() == null:
            var script := load(BASE_LEVEL_LOGIC)
            if script:
                logic.set_script(script)
                fixes.append("Assigned BaseLevelLogic script to Logic node.")

    # Ensure Metadata.level_info exists
    if root.has_node("Metadata"):
        var meta := root.get_node("Metadata")
        if not meta.has_meta("level_info") or typeof(meta.get_meta("level_info")) != TYPE_DICTIONARY:
            meta.set_meta("level_info", _default_level_info(scene_path))
            fixes.append("Created Metadata level_info Dictionary.")
        else:
            var info: Dictionary = meta.get_meta("level_info")
            var changed := false
            for k in REQUIRED_LEVEL_INFO_KEYS:
                if not info.has(k):
                    info[k] = _default_level_info(scene_path)[k]
                    changed = true
            if changed:
                meta.set_meta("level_info", info)
                fixes.append("Filled missing keys in Metadata level_info.")

    # Root rename is *not* auto-fixed (too risky)
    # But we can at least suggest it via validation error.

    return fixes

func _default_level_info(scene_path: String) -> Dictionary:
    var base := scene_path.get_file().get_basename()
    return {
        "id": base.to_snake_case(),
        "display_name": base,
        "order": SceneSpecConstants.LEVEL_DEFAULT_ORDER,
        "version": 1,
        "music": "",
        "tags": [],
    }

func _validate_no_scripts_outside_logic(root: Node, errors: Array[String]) -> void:
    # Root script is disallowed for levels
    if root.get_script() != null:
        errors.append("Root node must not have a script (use Logic node only).")

    var stack: Array[Node] = [root]
    while stack.size() > 0:
        var n := stack.pop_back()
        for c in n.get_children():
            if c is Node:
                # Allow script only on Logic
                if c.name != "Logic" and c.get_script() != null:
                    errors.append("Node '%s' has a script. Only Logic node may have a script." % c.get_path())
                stack.append(c)

