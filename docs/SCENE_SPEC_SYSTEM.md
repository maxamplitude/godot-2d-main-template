# Scene Specification & Validation System

This document explains how the **Scene Spec** system validates scenes and enforces architectural discipline at creation and CI time.

## Overview

The Scene Spec system is a **declarative validation framework** that:
- Defines **contracts** for each scene type (levels, entities, spawn points, triggers)
- **Validates** scenes against contracts
- **Auto-fixes** conservative issues (adds missing metadata, default values)
- **Integrates into CI/CD** for deterministic validation

---

## Architecture

### Base Class: SceneSpec

**File**: `tools/scene_specs/scene_spec.gd`

```gdscript
extends RefCounted
class_name SceneSpec

func spec_name() -> String:
    # Human-readable spec name
    return "BaseSpec"

func is_applicable(scene_path: String) -> bool:
    # Return true if this spec should validate this scene
    return false

func validate(scene_path: String, root: Node) -> Array[String]:
    # Return array of error strings
    # Return empty array if valid
    return []

func autofix(scene_path: String, root: Node) -> Array[String]:
    # Apply conservative fixes
    # Return array of fix descriptions
    return []
```

**Contract**:
- `is_applicable()` determines scope (e.g., "all .tscn files in res://scenes/levels/")
- `validate()` checks structure and reports errors
- `autofix()` fixes conservative issues only (never renames, deletes, or moves)

---

### Scene Spec Runner

**File**: `tools/scene_specs/scene_spec_runner.gd`

Orchestrates all specs:

```gdscript
var specs: Array[SceneSpec] = [
    LevelSpec.new(),
    SpawnPointSpec.new(),
    TriggerSpec.new(),
]

func validate_scene(scene_path: String) -> Dictionary:
    # Returns {
    #   "scene_path": String,
    #   "applicable_specs": [String],
    #   "errors": [String],
    # }

func autofix_scene(scene_path: String) -> Dictionary:
    # Returns {
    #   "scene_path": String,
    #   "applicable_specs": [String],
    #   "fixes": [String],
    #   "saved": bool,
    #   "errors": [String],
    # }
```

**Flow**:
1. Load scene from disk
2. Instantiate root node
3. Iterate specs that are `is_applicable()` for this scene
4. Call `validate()` on each spec
5. Collect all errors
6. If `autofix=true`, call `autofix()` on each spec
7. If fixes applied, re-pack and save scene

---

## Specifications

### LevelSpec

**File**: `tools/scene_specs/level_spec.gd`

**Applies To**: `res://scenes/levels/*.tscn` (excluding `BaseLevel.tscn`)

**Validates**:
- Root node name matches filename
- Required children exist (Environment, SpawnPoints, Triggers, Navigation, Entities, Logic, Metadata)
- Logic node has a script
- Metadata node has `level_info` dictionary
- `level_info` contains all required keys: `["id", "display_name", "order", "version", "music", "tags"]`
- No scripts on nodes except Logic

**Autofixes**:
- Adds missing children (as empty Node or Node2D)
- Assigns `BaseLevelLogic` script to Logic if missing
- Creates `level_info` metadata with defaults
- Fills missing keys in existing `level_info`

**Example Errors**:
```
Root name 'MyLevel' must match scene filename 'MyLevelScene'.
Missing required child node: SpawnPoints
Logic node has no script (expected BaseLevelLogic).
Metadata node missing meta 'level_info' Dictionary.
Metadata level_info missing key: display_name
```

---

### SpawnPointSpec

**File**: `tools/scene_specs/spawn_point_spec.gd`

**Applies To**: Levels with `Level/SpawnPoints` container

**Validates**:
- SpawnPoints children are `Node2D`
- Names start with `Spawn_`
- Have `spawn_info` metadata (Dictionary)
- `spawn_info["type"]` is not empty
- `spawn_info["scene"]` key exists
- `spawn_info["tags"]` is an Array

**Autofixes**:
- Adds empty `spawn_info` if missing

**Example Errors**:
```
SpawnPoints child 'Player' must be Node2D.
SpawnPoint 'enemy_marker' must start with 'Spawn_'.
SpawnPoint 'Spawn_Enemy' missing meta 'spawn_info'.
SpawnPoint 'Spawn_Item' spawn_info must be Dictionary.
SpawnPoint 'Spawn_Enemy' spawn_info missing 'type'.
SpawnPoint 'Spawn_Item' spawn_info tags must be Array.
```

---

### TriggerSpec

**File**: `tools/scene_specs/trigger_spec.gd`

**Applies To**: Levels with `Level/Triggers` container

**Validates**:
- Triggers children are `Area2D`
- Have `trigger_info` metadata (Dictionary)
- `trigger_info["id"]` is non-empty
- `trigger_info["event"]` is non-empty
- `trigger_info["once"]` is a bool
- `trigger_info["tags"]` is an Array

**Autofixes**:
- Adds empty `trigger_info` if missing

**Example Errors**:
```
Trigger 'ExitZone' must be Area2D.
Trigger 'TriggerMarker' missing meta 'trigger_info'.
Trigger 'ExitZone' trigger_info must be Dictionary.
Trigger 'BossArena' must have non-empty 'id'.
Trigger 'BossArena' must have non-empty 'event'.
Trigger 'WaveStart' trigger_info must declare bool 'once'.
Trigger 'WaveStart' trigger_info tags must be Array.
```

---

## Constants

**File**: `tools/scene_specs/scene_spec_constants.gd`

Central configuration for paths, UI sizing, and validation constants:

```gdscript
# Entity creation
const ENTITY_SCENE_ROOT := "res://scenes/entities"
const ENTITY_TEMPLATE_ROOT := "res://templates/scenes"
const ENTITY_CONFIG_DIR := "res://config/entities"
const DEFAULT_ENTITY_VERSION := 1
const ENTITY_DIALOG_POPUP_SIZE := Vector2i(500, 300)
const ENTITY_DIALOG_LABEL_WIDTH := 120

# Level creation
const LEVEL_TEMPLATE_ROOT := "res://templates/scenes"
const LEVELS_DIR := "res://scenes/levels"
const LEVEL_REQUIRED_CHILDREN := [
    "Environment", "SpawnPoints", "Triggers",
    "Navigation", "Entities", "Logic", "Metadata",
]
const BASE_LEVEL_SCENE := "res://scenes/levels/BaseLevel.tscn"
const BASE_LEVEL_LOGIC := "res://scripts/levels/base_level_logic.gd"
const LEVEL_METADATA_KEYS := ["id", "display_name", "order", "version", "music", "tags"]

# Level creation dialog sizing
const LEVEL_DIALOG_POPUP_SIZE := Vector2i(520, 260)
const LEVEL_DIALOG_LABEL_WIDTH := 180
const LEVEL_DIALOG_ORDER_MIN := -9999
const LEVEL_DIALOG_ORDER_MAX := 9999
```

**Purpose**: Single source of truth for all validation rules, UI sizes, and paths. Change here, not in individual specs.

---

## Usage

### Manual Validation (Editor)

1. Go to `Projects → Tools → Scene Spec/`
2. Choose:
   - `Validate All (Dry Run)` — checks without changing anything
   - `Auto-fix + Validate All` — applies fixes and saves scenes
3. Read report in popup dialog

### Programmatic Validation (Scripts/CI)

```gdscript
var runner := SceneSpecRunner.new()

# Validate a single scene
var result := runner.validate_scene("res://scenes/levels/Level01.tscn")
print("Errors:", result["errors"])

# Auto-fix a single scene
var result := runner.autofix_scene("res://scenes/levels/Level01.tscn")
print("Saved:", result["saved"])
print("Fixes:", result["fixes"])
```

### Headless Validation (CI)

```bash
# Validate all levels without changes
godot4 --headless --quit --script res://tools/validate_levels_headless.gd

# Run with exit code for CI:
# Exit 0 = all valid
# Exit 1 = errors found
```

**File**: `tools/validate_levels_headless.gd`

```gdscript
extends SceneTree

func _init() -> void:
    var runner := SceneSpecRunner.new()
    var level_dir := "res://scenes/levels"

    # Scan directory
    var dir := DirAccess.open(level_dir)
    var failed := false

    dir.list_dir_begin()
    while true:
        var f := dir.get_next()
        if f == "":
            break
        if not f.ends_with(".tscn") or f == "BaseLevel.tscn":
            continue

        var path := "%s/%s" % [level_dir, f]
        var res := runner.validate_scene(path)

        if res["errors"].size() > 0:
            failed = true
            for e in res["errors"]:
                print("%s: %s" % [path, e])

    dir.list_dir_end()
    quit(1 if failed else 0)
```

---

## Extending Specs

To add validation for a new scene type:

### 1. Create a new spec class

```gdscript
# res://tools/scene_specs/enemy_spec.gd
extends SceneSpec
class_name EnemySpec

func spec_name() -> String:
    return "EnemySpec"

func is_applicable(scene_path: String) -> bool:
    return scene_path.begins_with("res://scenes/enemies/")

func validate(scene_path: String, root: Node) -> Array[String]:
    var errors: Array[String] = []

    if not root.has_node("Logic"):
        errors.append("Root must have Logic node")

    return errors

func autofix(scene_path: String, root: Node) -> Array[String]:
    var fixes: Array[String] = []

    if not root.has_node("Logic"):
        var logic = Node.new()
        logic.name = "Logic"
        root.add_child(logic)
        root.owner = root  # Important for packing
        fixes.append("Added Logic node")

    return fixes
```

### 2. Register in SceneSpecRunner

```gdscript
# tools/scene_specs/scene_spec_runner.gd
func _init() -> void:
    specs = [
        LevelSpec.new(),
        SpawnPointSpec.new(),
        TriggerSpec.new(),
        EnemySpec.new(),  # ← Add here
    ]
```

### 3. Add constants to SceneSpecConstants

```gdscript
# tools/scene_specs/scene_spec_constants.gd
const ENEMY_SCENE_ROOT := "res://scenes/enemies"
const ENEMY_TEMPLATE_ROOT := "res://templates/scenes"
```

---

## Design Philosophy

### Conservative Autofixes

Autofixes **never**:
- Rename nodes
- Delete nodes
- Move nodes
- Change script behavior
- Guess scene paths

Autofixes **only**:
- Add missing metadata dictionaries
- Fill missing dictionary keys with defaults
- Assign known scripts to empty Logic nodes
- Add missing required child nodes

**Rationale**: Designer intent is sacred. We catch structural errors, not design errors.

### Composition Over Inheritance

Specs validate **structure**, not inheritance:
- Check for required children ✅
- Check metadata dictionaries ✅
- Don't enforce script inheritance ❌
- Don't require specific node types ❌

**Rationale**: Enables flexibility. Different Logic scripts can work with the same structure.

### Early & Consistent Validation

Validation happens at:
1. **Creation** — LevelCreateDialog validates before saving
2. **Edit-time** — `Projects → Tools → Scene Spec/` validates manually
3. **Build-time** — CI runs headless validation before deploy

**Rationale**: Catch wiring errors early and consistently.

---

## Best Practices

### Do's ✅
- Run validation regularly during development
- Use the creation dialogs (they populate metadata correctly)
- Keep specs focused (one responsibility per spec)
- Test specs with edge cases
- Document spec contracts in comments

### Don'ts ❌
- Add logic to `validate()` beyond structure checks
- Hard-code paths in specs (use SceneSpecConstants)
- Forget to register new specs in SceneSpecRunner
- Add autofixes that guess designer intent
- Skip validation before committing

---

## Troubleshooting

### "Scene fails validation but looks correct"

1. Check that **all required children exist** (use autofix if in doubt)
2. Check that **metadata dictionaries have all required keys**
3. Check that **Logic node has a script assigned** (not just a class name)
4. Run `Projects → Tools → Scene Spec → Auto-fix + Validate All` to auto-fix conservative issues

### "Autofix didn't save the scene"

The autofix only saves if it **applied fixes**. If no fixes are needed, the scene is considered valid and not saved.

### "Spec is not validating my custom scene type"

1. Check `is_applicable()` — does it match your scene path?
2. Check that the spec is registered in `SceneSpecRunner._init()`
3. Run validation on the scene manually to see applied specs

---

## Next Steps

See:
- [LEVEL_ENTITY_CREATION.md](LEVEL_ENTITY_CREATION.md) — Creation workflows
- [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md) — Level node hierarchy and metadata
- `tools/scene_specs/` — Spec implementations

