@tool
extends EditorPlugin

const Validator := preload("res://addons/scene_spec_tools/scene_spec_validator.gd")
const EntityCreateDialog := preload("res://addons/scene_spec_tools/entity_create_dialog.gd")
const LevelCreateDialog := preload("res://addons/scene_spec_tools/level_create_dialog.gd")

var _entity_create_dialog: AcceptDialog
var _level_create_dialog: AcceptDialog
var _dialog: AcceptDialog
var _output: RichTextLabel

func _enter_tree() -> void:
	_dialog = AcceptDialog.new()
	_dialog.title = "Scene Spec Tools"
	_dialog.size = Vector2i(900, 600)

	_output = RichTextLabel.new()
	_output.fit_content = true
	_output.scroll_active = true
	_output.bbcode_enabled = true
	_output.custom_minimum_size = Vector2(860, 520)
	_dialog.add_child(_output)

	get_editor_interface().get_base_control().add_child(_dialog)

	add_tool_menu_item("Scene Spec/Validate All (Dry Run)", _on_validate_all)
	add_tool_menu_item("Scene Spec/Auto-fix + Validate All", _on_fix_and_validate_all)
	add_tool_menu_item("Scene Spec/Create Entity From Template…", _open_entity_create_dialog)
	add_tool_menu_item("Scene Spec/Create Level From Template…", _open_level_create_dialog)

	_entity_create_dialog = EntityCreateDialog.new()
	get_editor_interface().get_base_control().add_child(_entity_create_dialog)

	_level_create_dialog = LevelCreateDialog.new()
	get_editor_interface().get_base_control().add_child(_level_create_dialog)

func _open_entity_create_dialog():
	_entity_create_dialog.popup_centered()

func _open_level_create_dialog():
	_level_create_dialog.popup_centered()

func _exit_tree() -> void:
	remove_tool_menu_item("Scene Spec/Validate All (Dry Run)")
	remove_tool_menu_item("Scene Spec/Auto-fix + Validate All")

	if is_instance_valid(_dialog):
		_dialog.queue_free()
	if is_instance_valid(_entity_create_dialog):
		_entity_create_dialog.queue_free()
	if is_instance_valid(_level_create_dialog):
		_level_create_dialog.queue_free()

func _on_validate_all() -> void:
	_run(false)

func _on_fix_and_validate_all() -> void:
	_run(true)

func _run(do_fix: bool) -> void:
	var v := Validator.new()
	var res := v.validate_all_entities(do_fix)

	_output.clear()
	_output.append_text("[b]Entity Scene Spec Report[/b]\n")
	_output.append_text("Mode: %s\n" % ("AUTO-FIX + VALIDATE" if do_fix else "VALIDATE (DRY RUN)"))
	_output.append_text("Checked: %d scenes\n" % res.checked)
	_output.append_text("Fixed: %d scenes\n" % res.fixed)
	_output.append_text("Errors: %d\n\n" % res.errors_total)

	for item in res.items:
		var path: String = item.path
		var errs: Array = item.errors
		var fixes: Array = item.fixes

		if errs.is_empty() and fixes.is_empty():
			continue

		_output.append_text("[b]%s[/b]\n" % path)

		if not fixes.is_empty():
			_output.append_text("  [color=green]Fixes:[/color]\n")
			for f in fixes:
				_output.append_text("    - %s\n" % f)

		if not errs.is_empty():
			_output.append_text("  [color=red]Errors:[/color]\n")
			for e in errs:
				_output.append_text("    - %s\n" % e)

		_output.append_text("\n")

	_dialog.popup_centered()
