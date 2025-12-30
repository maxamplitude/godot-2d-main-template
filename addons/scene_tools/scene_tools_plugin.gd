@tool
extends EditorPlugin

const SceneSpecConstants := preload("res://tools/scene_specs/scene_spec_constants.gd")

var _dialog: AcceptDialog
var _name_edit: LineEdit
var _display_name_edit: LineEdit
var _id_edit: LineEdit
var _order_spin: SpinBox

func _enter_tree() -> void:
    add_tool_menu_item("Scene Tools / New Level…", _on_new_level)
    add_tool_menu_item("Scene Tools / Validate Levels", _on_validate_levels)
    add_tool_menu_item("Scene Tools / Auto-fix Levels", _on_autofix_levels)

func _exit_tree() -> void:
    remove_tool_menu_item("Scene Tools / New Level…")
    remove_tool_menu_item("Scene Tools / Validate Levels")
    remove_tool_menu_item("Scene Tools / Auto-fix Levels")
    if _dialog:
        _dialog.queue_free()

func _on_new_level() -> void:
    _ensure_dialog()
    _name_edit.text = SceneSpecConstants.LEVEL_DEFAULT_NAME
    _display_name_edit.text = SceneSpecConstants.LEVEL_DEFAULT_DISPLAY_NAME
    _id_edit.text = SceneSpecConstants.LEVEL_DEFAULT_ID
    _order_spin.value = SceneSpecConstants.LEVEL_DEFAULT_ORDER
    _dialog.popup_centered(SceneSpecConstants.LEVEL_DIALOG_POPUP_SIZE)

func _ensure_dialog() -> void:
    if _dialog:
        return

    _dialog = AcceptDialog.new()
    _dialog.title = "Create New Level"
    _dialog.ok_button_text = "Create"
    _dialog.connect("confirmed", _create_level_confirmed)

    var root := VBoxContainer.new()
    root.custom_minimum_size = SceneSpecConstants.LEVEL_DIALOG_MIN_SIZE

    root.add_child(_row("Scene Name (must match root)", func() -> Control:
        _name_edit = LineEdit.new()
        _name_edit.placeholder_text = "e.g., Level01"
        _name_edit.text_changed.connect(_sync_fields_from_name)
        return _name_edit
    ))

    root.add_child(_row("Display Name", func() -> Control:
        _display_name_edit = LineEdit.new()
        _display_name_edit.placeholder_text = "e.g., The Docks"
        return _display_name_edit
    ))

    root.add_child(_row("Level ID (stable)", func() -> Control:
        _id_edit = LineEdit.new()
        _id_edit.placeholder_text = "e.g., level01"
        return _id_edit
    ))

    root.add_child(_row("Order", func() -> Control:
        _order_spin = SpinBox.new()
        _order_spin.min_value = SceneSpecConstants.LEVEL_DIALOG_ORDER_MIN
        _order_spin.max_value = SceneSpecConstants.LEVEL_DIALOG_ORDER_MAX
        _order_spin.step = 1
        return _order_spin
    ))

    _dialog.add_child(root)
    add_child(_dialog)

func _row(label_text: String, make_control: Callable) -> HBoxContainer:
    var row := HBoxContainer.new()
    var lbl := Label.new()
    lbl.text = label_text
    lbl.custom_minimum_size = Vector2(SceneSpecConstants.LEVEL_DIALOG_LABEL_WIDTH, 0)
    row.add_child(lbl)
    row.add_child(make_control.call())
    return row

func _sync_fields_from_name(_t: String) -> void:
    var name := _name_edit.text.strip_edges()
    if name.is_empty():
        return
    # Keep it helpful, not bossy.
    if _id_edit.text.strip_edges().is_empty() or _id_edit.text == _id_edit.placeholder_text:
        _id_edit.text = name.to_snake_case()
    if _display_name_edit.text.strip_edges().is_empty():
        _display_name_edit.text = name

func _create_level_confirmed() -> void:
    var name := _name_edit.text.strip_edges()
    if name.is_empty():
        push_error("Level name cannot be empty.")
        return

    var dst_path := "%s/%s.tscn" % [SceneSpecConstants.LEVELS_DIR, name]
    if ResourceLoader.exists(dst_path):
        push_error("Level already exists: %s" % dst_path)
        return

    # Create inherited scene from BaseLevel
    var base := load(SceneSpecConstants.BASE_LEVEL_SCENE)
    if base == null:
        push_error("Missing BaseLevel scene at %s" % BASE_LEVEL_SCENE)
        return

    var inst := base.instantiate()
    inst.name = name  # root rename

    # Fill metadata contract using Node metadata
    var meta := inst.get_node_or_null("Metadata")
    if meta:
        meta.set_meta("level_info", {
            "id": _id_edit.text.strip_edges(),
            "display_name": _display_name_edit.text.strip_edges(),
            "order": int(_order_spin.value),
            "version": 1,
            "music": "",
            "tags": [],
        })

    var ps := PackedScene.new()
    if not ps.pack(inst):
        push_error("Failed to pack new level scene.")
        return

    var err := ResourceSaver.save(ps, dst_path)
    if err != OK:
        push_error("Failed to save level scene %s (error %d)." % [dst_path, err])
        return

    # Refresh editor and select the new scene
    EditorInterface.get_resource_filesystem().scan()
    print("Created level: %s" % dst_path)

func _on_validate_levels() -> void:
    var runner := SceneSpecRunner.new()
    var bad := false

    for path in _list_level_scenes():
        var res := runner.validate_scene(path)
        var errs: Array = res["errors"]
        if errs.size() > 0:
            bad = true
            for e in errs:
                push_error("%s: %s" % [path, e])

    if not bad:
        print("All levels valid.")

func _on_autofix_levels() -> void:
    var runner := SceneSpecRunner.new()
    var any := false

    for path in _list_level_scenes():
        var res := runner.autofix_scene(path)
        var errs: Array = res["errors"]
        if errs.size() > 0:
            for e in errs:
                push_error("%s: %s" % [path, e])
            continue

        var fixes: Array = res["fixes"]
        if fixes.size() > 0:
            any = true
            for f in fixes:
                print("%s: %s" % [path, f])

    if any:
        EditorInterface.get_resource_filesystem().scan()
        print("Auto-fix completed.")
    else:
        print("No fixes needed.")

func _list_level_scenes() -> Array[String]:
    var out: Array[String] = []
    var dir := DirAccess.open(SceneSpecConstants.LEVELS_DIR)
    if dir == null:
        return out
    dir.list_dir_begin()
    while true:
        var f := dir.get_next()
        if f == "":
            break
        if dir.current_is_dir():
            continue
        if f.ends_with(".tscn") and f != "BaseLevel.tscn":
            out.append("%s/%s" % [SceneSpecConstants.LEVELS_DIR, f])
    dir.list_dir_end()
    return out

