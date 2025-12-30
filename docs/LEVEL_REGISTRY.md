# Level Registry & Runtime Level Selection

This document explains how to use the **Level Registry** system for runtime level loading and menu systems.

## Overview

The **Level Registry** is a **JSON artifact** generated at build/CI time that:
- Lists all valid levels in order
- Contains metadata (name, music, tags)
- Eliminates runtime scene scanning
- Enables deterministic level selection

---

## Registry Generation

### What Gets Generated

**File**: `res://levels_registry.json` (auto-generated)

```json
{
  "levels": [
    {
      "id": "level01",
      "scene": "res://scenes/levels/Level01.tscn",
      "display_name": "Level 01",
      "order": 0,
      "music": "res://assets/audio/level01.ogg",
      "tags": ["tutorial", "beginner"]
    },
    {
      "id": "level02",
      "scene": "res://scenes/levels/Level02.tscn",
      "display_name": "Forest Escape",
      "order": 1,
      "music": "res://assets/audio/forest.ogg",
      "tags": ["action", "intermediate"]
    }
  ]
}
```

### How to Generate

#### Manual Generation (Development)

```bash
cd /path/to/project
godot4 --headless --quit --script res://tools/generate_level_registry.gd
```

Output:
```
Generated res://levels_registry.json (2 levels)
```

#### CI/CD Integration

Add to your build pipeline:

```bash
# After running validation
godot4 --headless --quit --script res://tools/validate_levels_headless.gd

# Generate registry (only if validation passed)
godot4 --headless --quit --script res://tools/generate_level_registry.gd

# Optionally: commit or upload as artifact
git add res://levels_registry.json
git commit -m "chore: update level registry"
```

**GitHub Actions Example**:

```yaml
- name: Validate Levels
  run: |
    godot4 --headless --quit --script res://tools/validate_levels_headless.gd

- name: Generate Level Registry
  run: |
    godot4 --headless --quit --script res://tools/generate_level_registry.gd

- name: Commit Registry
  if: github.ref == 'refs/heads/main'
  run: |
    git add res://levels_registry.json
    git diff --quiet && git diff --staged --quiet || (
      git config user.email "ci@example.com"
      git config user.name "CI"
      git commit -m "chore: update level registry [skip ci]"
      git push
    )
```

---

## Registry Generator Script

**File**: `tools/generate_level_registry.gd`

```gdscript
extends SceneTree

const LEVELS_DIR := "res://scenes/levels"
const OUTPUT_PATH := "res://levels_registry.json"
const BASE_LEVEL_SCENE := "BaseLevel.tscn"

func _init() -> void:
    var levels: Array[Dictionary] = []

    var dir := DirAccess.open(LEVELS_DIR)
    if dir == null:
        push_error("Missing levels directory: %s" % LEVELS_DIR)
        quit(1)
        return

    # Scan directory for all .tscn files
    dir.list_dir_begin()
    while true:
        var f := dir.get_next()
        if f == "":
            break
        if dir.current_is_dir() or not f.ends_with(".tscn") or f == BASE_LEVEL_SCENE:
            continue

        var path := "%s/%s" % [LEVELS_DIR, f]
        var scene := load(path)
        if scene == null:
            continue

        # Instantiate and extract metadata
        var root := scene.instantiate()
        var meta := root.get_node_or_null("Metadata")
        if meta == null or not meta.has_meta("level_info"):
            continue

        var info := meta.get_meta("level_info")
        if typeof(info) != TYPE_DICTIONARY:
            continue
        if not info.has("id") or not info.has("display_name") or not info.has("order"):
            continue

        # Build registry entry
        levels.append({
            "id": info["id"],
            "scene": path,
            "display_name": info["display_name"],
            "order": info["order"],
            "music": info.get("music", ""),
            "tags": info.get("tags", []),
        })

    dir.list_dir_end()

    # Sort by order
    levels.sort_custom(self, "_compare_level_order")

    # Write JSON
    var data := { "levels": levels }
    var json := JSON.stringify(data, "\t")

    var f := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    if f == null:
        push_error("Failed to write registry at %s." % OUTPUT_PATH)
        quit(1)
        return

    f.store_string(json)
    f.close()

    print("Generated %s (%d levels)" % [OUTPUT_PATH, levels.size()])
    quit(0)

func _compare_level_order(a: Dictionary, b: Dictionary) -> int:
    return int(a.get("order", 0) - b.get("order", 0))
```

**Key Points**:
- Scans `res://scenes/levels/` for valid levels
- Loads each scene and extracts `Metadata.level_info`
- Requires: `id`, `display_name`, `order` (all others optional)
- Sorts by `order` field
- Writes to `res://levels_registry.json`
- Exit code 0 = success, 1 = error

---

## Runtime Usage

### Load Registry

```gdscript
# Singleton approach
var registry: Dictionary = {}

func _ready() -> void:
    var json_path := "res://levels_registry.json"
    var file = FileAccess.open(json_path, FileAccess.READ)
    if file == null:
        push_error("Failed to load level registry")
        return

    var json = JSON.new()
    if json.parse(file.get_as_text()) != OK:
        push_error("Failed to parse level registry")
        return

    registry = json.data
```

### Get All Levels

```gdscript
func get_all_levels() -> Array:
    return registry.get("levels", [])
```

### Get Level by ID

```gdscript
func get_level_by_id(level_id: String) -> Dictionary:
    for level in get_all_levels():
        if level["id"] == level_id:
            return level
    return {}
```

### Get Next Level (for progression)

```gdscript
func get_next_level(current_level_id: String) -> Dictionary:
    var all_levels = get_all_levels()
    var current_index = -1

    for i in range(all_levels.size()):
        if all_levels[i]["id"] == current_level_id:
            current_index = i
            break

    if current_index >= 0 and current_index < all_levels.size() - 1:
        return all_levels[current_index + 1]

    return {}
```

### Filter by Tag

```gdscript
func get_levels_by_tag(tag: String) -> Array:
    var filtered: Array = []
    for level in get_all_levels():
        if tag in level.get("tags", []):
            filtered.append(level)
    return filtered

# Usage
var tutorial_levels = get_levels_by_tag("tutorial")
var combat_levels = get_levels_by_tag("action")
```

---

## Level Selection Menu Example

```gdscript
# res://scenes/ui/LevelSelectMenu.gd
extends Control

@onready var level_list: ItemList = $VBoxContainer/LevelList

var registry: Dictionary = {}
var levels: Array = []

func _ready() -> void:
    _load_registry()
    _populate_level_list()

func _load_registry() -> void:
    var file = FileAccess.open("res://levels_registry.json", FileAccess.READ)
    if file == null:
        print("No registry found. Run registry generator.")
        return

    var json = JSON.new()
    if json.parse(file.get_as_text()) == OK:
        registry = json.data
        levels = registry.get("levels", [])
    else:
        print("Failed to parse registry")

func _populate_level_list() -> void:
    level_list.clear()

    for level in levels:
        var display_name = level.get("display_name", "Unknown")
        var tags = level.get("tags", [])
        var text = display_name

        if not tags.is_empty():
            text += " [%s]" % ", ".join(tags)

        level_list.add_item(text)

    level_list.item_selected.connect(_on_level_selected)

func _on_level_selected(index: int) -> void:
    if index < 0 or index >= levels.size():
        return

    var level = levels[index]
    App.load_level(level["scene"])
```

---

## Level Progression Example

```gdscript
# res://scripts/autoload/LevelManager.gd
extends Node

var registry: Dictionary = {}
var levels: Array = []
var current_level_index: int = -1

func _ready() -> void:
    _load_registry()

func _load_registry() -> void:
    var file = FileAccess.open("res://levels_registry.json", FileAccess.READ)
    if file != null:
        var json = JSON.new()
        if json.parse(file.get_as_text()) == OK:
            registry = json.data
            levels = registry.get("levels", [])

func set_current_level(level_id: String) -> void:
    for i in range(levels.size()):
        if levels[i]["id"] == level_id:
            current_level_index = i
            return

func get_current_level() -> Dictionary:
    if current_level_index >= 0 and current_level_index < levels.size():
        return levels[current_level_index]
    return {}

func advance_to_next_level() -> bool:
    if current_level_index + 1 < levels.size():
        current_level_index += 1
        var next_level = get_current_level()
        App.load_level(next_level["scene"])
        return true
    return false

func restart_current_level() -> void:
    var current = get_current_level()
    if not current.is_empty():
        App.load_level(current["scene"])

func is_last_level() -> bool:
    return current_level_index == levels.size() - 1

func get_total_levels() -> int:
    return levels.size()

func get_level_progress() -> String:
    return "%d / %d" % [current_level_index + 1, levels.size()]
```

---

## JSON Schema

### Registry Structure

```
{
  "levels": [
    {
      "id": string,              # Unique identifier (required)
      "scene": string,           # Path to scene file (required)
      "display_name": string,    # User-friendly name (required)
      "order": int,              # Sort order (required)
      "music": string,           # Path to music file (optional)
      "tags": [string]           # Array of tags (optional)
    }
  ]
}
```

### Metadata on Level Scene

The registry is built from `Metadata.level_info`:

```gdscript
{
  "id": "level01",              # Unique identifier
  "display_name": "Level 01",   # User-friendly name
  "order": 0,                   # Sort order
  "version": 1,                 # Schema version
  "music": "res://assets/audio/level01.ogg",  # Optional
  "tags": ["tutorial"],         # Optional
}
```

---

## Best Practices

### Do's ✅
- Generate registry after every level creation
- Commit `levels_registry.json` to version control
- Use registry in menus instead of scanning scenes
- Filter levels by tag for difficulty/progression
- Keep `order` values sequential

### Don'ts ❌
- Manually edit `levels_registry.json` (regenerate instead)
- Scan `res://scenes/levels/` at runtime (use registry)
- Store scene paths in separate config files (they're in registry)
- Load levels without checking registry validity
- Skip registry generation in CI

---

## Troubleshooting

### Registry is empty

1. Check that levels exist in `res://scenes/levels/`
2. Check that each level has `Metadata.level_info` metadata
3. Check that `level_info` has all required keys: `id`, `display_name`, `order`
4. Run `Projects → Tools → Scene Spec → Auto-fix + Validate All` to auto-populate

### Registry not updating

1. Run the registry generator manually:
   ```bash
   godot4 --headless --quit --script res://tools/generate_level_registry.gd
   ```
2. Check that the script didn't error (look for output in console)
3. Check that `res://levels_registry.json` exists and is readable

### Menu shows wrong level names

1. Check that `level_info["display_name"]` is set correctly in each level
2. Regenerate the registry:
   ```bash
   godot4 --headless --quit --script res://tools/generate_level_registry.gd
   ```
3. Verify JSON was written correctly (open `res://levels_registry.json` in editor)

---

## Next Steps

See:
- [LEVEL_ENTITY_CREATION.md](LEVEL_ENTITY_CREATION.md) — How to create levels
- [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md) — Level structure and metadata
- [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md) — Validation system

