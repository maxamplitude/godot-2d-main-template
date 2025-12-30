@tool
extends AcceptDialog

const SceneSpecConstants := preload("res://tools/scene_specs/scene_spec_constants.gd")

signal entity_created(path: String)

var _template_list: OptionButton
var _name_edit: LineEdit
var _category_edit: LineEdit
var _tags_edit: LineEdit

func _ready() -> void:
	title = "Create Entity From Template"
	size = SceneSpecConstants.ENTITY_DIALOG_POPUP_SIZE

	var v := VBoxContainer.new()
	add_child(v)

	_template_list = OptionButton.new()
	v.add_child(_labeled("Template", _template_list))

	_name_edit = LineEdit.new()
	v.add_child(_labeled("Entity Name", _name_edit))

	_category_edit = LineEdit.new()
	v.add_child(_labeled("Category", _category_edit))

	_tags_edit = LineEdit.new()
	_tags_edit.placeholder_text = "comma,separated,tags"
	v.add_child(_labeled("Tags", _tags_edit))

	get_ok_button().text = "Create"
	_refresh_templates()

func _labeled(label: String, node: Control) -> Control:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = SceneSpecConstants.ENTITY_CREATE_DIALOG_LABEL_WIDTH
	h.add_child(l)
	h.add_child(node)
	return h

func _refresh_templates() -> void:
	_template_list.clear()
	var da := DirAccess.open(SceneSpecConstants.ENTITY_TEMPLATE_ROOT)
	if da == null:
		return

	da.list_dir_begin()
	while true:
		var f := da.get_next()
		if f.is_empty():
			break
		if f.ends_with(".tscn"):
			_template_list.add_item(f)
	da.list_dir_end()

func _confirmed() -> void:
	if _name_edit.text.is_empty():
		push_error("Entity name required")
		return

	var tpl := _template_list.get_item_text(_template_list.selected)
	var dst := "%s/%s.tscn" % [
		SceneSpecConstants.ENTITY_SCENE_ROOT,
		_name_edit.text
	]

	_create_entity(tpl, dst)

func _create_entity(template_name: String, dst_path: String) -> void:
	var tpl_path := "%s/%s" % [
		SceneSpecConstants.ENTITY_TEMPLATE_ROOT,
		template_name
	]

	var scene := PackedScene.new()
	var base: Node = load(tpl_path).instantiate()
	base.name = dst_path.get_file().get_basename()

	# Fill metadata
	var logic: Node = base.get_node("Logic")
	var info := {
		"id": base.name.to_snake_case(),
		"category": _category_edit.text,
		"tags": _tags_edit.text.split(",", false),
		"version": SceneSpecConstants.DEFAULT_ENTITY_VERSION
	}
	logic.entity_info = info

	scene.pack(base)
	ResourceSaver.save(scene, dst_path)

	entity_created.emit(dst_path)
	hide()
