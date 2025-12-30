# Game lifecycle, scene switching

extends Node
class_name App

enum GameState {
	BOOT,
	MENU,
	PLAYING,
	PAUSED
}

var state: GameState = GameState.BOOT
var current_scene: Node = null

func _ready() -> void:
	change_scene("res://scenes/bootstrap.tscn")

func change_scene(path: String) -> void:
	if current_scene:
		current_scene.queue_free()

	var scene_res := load(path)
	assert(scene_res, "Failed to load scene: %s" % path)

	current_scene = scene_res.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
