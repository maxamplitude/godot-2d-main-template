extends RefCounted
class_name SceneSpec

func spec_name() -> String:
    return "SceneSpec"

func is_applicable(_scene_path: String) -> bool:
    return false

func validate(_scene_path: String, _root: Node) -> Array[String]:
    return []

func autofix(_scene_path: String, _root: Node) -> Array[String]:
    # Return list of fixes applied (human readable)
    return []

