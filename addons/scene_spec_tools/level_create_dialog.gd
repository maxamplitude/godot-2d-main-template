@tool
extends AcceptDialog

const SceneSpecConstants := preload("res://tools/scene_specs/scene_spec_constants.gd")

signal level_created(path: String)

var _template_list: OptionButton
var _name_edit: LineEdit
var _display_name_edit: LineEdit
var _order_spinbox: SpinBox
var _music_edit: LineEdit
var _tags_edit: LineEdit

func _ready() -> void:
	title = "Create Level From Template"
	size = SceneSpecConstants.LEVEL_DIALOG_POPUP_SIZE

	var v := VBoxContainer.new()
	add_child(v)

	_template_list = OptionButton.new()
	v.add_child(_labeled("Template", _template_list))

	_name_edit = LineEdit.new()
	v.add_child(_labeled("Level Name", _name_edit))

	_display_name_edit = LineEdit.new()
	v.add_child(_labeled("Display Name", _display_name_edit))

	_order_spinbox = SpinBox.new()
	_order_spinbox.min_value = SceneSpecConstants.LEVEL_DIALOG_ORDER_MIN
	_order_spinbox.max_value = SceneSpecConstants.LEVEL_DIALOG_ORDER_MAX
	_order_spinbox.value = SceneSpecConstants.LEVEL_DEFAULT_ORDER
	v.add_child(_labeled("Order", _order_spinbox))

	_music_edit = LineEdit.new()
	_music_edit.placeholder_text = "(optional)"
	v.add_child(_labeled("Music", _music_edit))

	_tags_edit = LineEdit.new()
	_tags_edit.placeholder_text = "comma,separated,tags"
	v.add_child(_labeled("Tags", _tags_edit))

	get_ok_button().text = "Create"
	_refresh_templates()

func _labeled(label: String, node: Control) -> Control:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = SceneSpecConstants.LEVEL_DIALOG_LABEL_WIDTH
	h.add_child(l)
	h.add_child(node)
	return h

func _refresh_templates() -> void:
	_template_list.clear()
	var da := DirAccess.open(SceneSpecConstants.LEVEL_TEMPLATE_ROOT)
	if da == null:
		return

	da.list_dir_begin()
	while true:
		var f := da.get_next()
		if f.is_empty():
			break
		if f == "BaseLevel.tscn":
			_template_list.add_item(f)
	da.list_dir_end()

func _confirmed() -> void:
	if _name_edit.text.is_empty():
		push_error("Level name required")
		return

	var tpl := _template_list.get_item_text(_template_list.selected)
	var dst := "%s/%s.tscn" % [
		SceneSpecConstants.LEVELS_DIR,
		_name_edit.text
	]

	_create_level(tpl, dst)

func _create_level(template_name: String, dst_path: String) -> void:
	var tpl_path := "%s/%s" % [
		SceneSpecConstants.ENTITY_TEMPLATE_ROOT,
		template_name
	]

	var scene := PackedScene.new()
	var base: Node = load(tpl_path).instantiate()
	base.name = dst_path.get_file().get_basename()

	# Fill metadata on Metadata node
	var metadata: Node = base.get_node("Metadata")
	var info := {
		"id": base.name.to_snake_case(),
		"display_name": _display_name_edit.text if not _display_name_edit.text.is_empty() else base.name,
		"order": int(_order_spinbox.value),
		"version": 1,
		"music": _music_edit.text,
		"tags": _tags_edit.text.split(",", false),
	}
	metadata.set_meta("level_info", info)

	scene.pack(base)
	ResourceSaver.save(scene, dst_path)

	level_created.emit(dst_path)
	hide()

