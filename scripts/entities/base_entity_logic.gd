extends Node
class_name BaseEntityLogic

signal entity_ready
signal entity_destroyed
signal entity_damaged(amount: float)

@export var entity_info := {
	"id": "",
	"category": "",
	"tags": [],
	"version": 1,
}

func _ready() -> void:
	# Root is the entity instance; Logic is a child.
	# Make sure entity emits a consistent "ready" signal.
	entity_ready.emit()

func damage(amount: float) -> void:
	entity_damaged.emit(amount)

func destroy() -> void:
	entity_destroyed.emit()
	(get_parent() as Node).queue_free()
