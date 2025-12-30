extends Node
class_name InputManager

func movement_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

func aim_vector() -> Vector2:
	var v := Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)
	return v.normalized() if v.length() > 0.1 else Vector2.ZERO

func fire_pressed() -> bool:
	return Input.is_action_pressed("fire")

func fire_just_pressed() -> bool:
	return Input.is_action_just_pressed("fire")
