extends SceneTree

func _init() -> void:
    var runner := SceneSpecRunner.new()
    var level_dir := "res://scenes/levels"

    var dir := DirAccess.open(level_dir)
    if dir == null:
        print("Missing directory: %s" % level_dir)
        quit(1)
        return

    var failed := false
    dir.list_dir_begin()
    while true:
        var f := dir.get_next()
        if f == "":
            break
        if dir.current_is_dir():
            continue
        if not f.ends_with(".tscn") or f == "BaseLevel.tscn":
            continue

        var path := "%s/%s" % [level_dir, f]
        var res := runner.validate_scene(path)
        var errs: Array = res["errors"]
        if errs.size() > 0:
            failed = true
            for e in errs:
                print("%s: %s" % [path, e])
    dir.list_dir_end()

    quit(1 if failed else 0)

