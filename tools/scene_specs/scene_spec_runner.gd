extends RefCounted
class_name SceneSpecRunner

var specs: Array[SceneSpec] = []

func _init() -> void:
    # Add specs here as you expand (EntitySpec, UISpec, etc.)
    specs = [
        LevelSpec.new(),
        SpawnPointSpec.new(),
        TriggerSpec.new(),
    ]

func validate_scene(scene_path: String) -> Dictionary:
    var result := {
        "scene_path": scene_path,
        "applicable_specs": [],
        "errors": [],
    }

    var scene := load(scene_path)
    if scene == null:
        result["errors"].append("Unable to load scene.")
        return result

    var root := scene.instantiate()

    for spec in specs:
        if spec.is_applicable(scene_path):
            result["applicable_specs"].append(spec.spec_name())
            result["errors"].append_array(spec.validate(scene_path, root))

    return result

func autofix_scene(scene_path: String) -> Dictionary:
    var result := {
        "scene_path": scene_path,
        "applicable_specs": [],
        "fixes": [],
        "saved": false,
        "errors": [],
    }

    var scene := load(scene_path)
    if scene == null:
        result["errors"].append("Unable to load scene.")
        return result

    var root := scene.instantiate()

    for spec in specs:
        if spec.is_applicable(scene_path):
            result["applicable_specs"].append(spec.spec_name())
            result["fixes"].append_array(spec.autofix(scene_path, root))

    # Save only if we applied fixes
    if result["fixes"].size() > 0:
        var ps := PackedScene.new()
        var ok := ps.pack(root)
        if not ok:
            result["errors"].append("Failed to pack scene after fixes.")
            return result
        var save_err := ResourceSaver.save(ps, scene_path)
        if save_err != OK:
            result["errors"].append("Failed to save scene (error %d)." % save_err)
            return result
        result["saved"] = true

    return result

