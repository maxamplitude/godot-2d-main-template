extends Node
class_name BaseLevelLogic

# The Level root is the owner scene’s root node.
@onready var level_root: Node = get_owner()

func _ready() -> void:
    # Intentionally minimal. Levels orchestrate; entities behave.
    # You can standardize signals here later if you want.
    pass

