# Level & Entity Creation System Design

## Overview

The creation system is **symmetric and template-driven**:
- Designers use **Templates** as blueprints (pre-built scenes with structure)
- Designers create **instances** via the Editor Tools menu (`Projects → Tools`)
- Each dialog collects **metadata** and **configuration** from the designer
- New scenes are saved with fully-validated structure

---

## Architecture

### Templates (Blueprint Scenes)

#### Entity Template
**Path**: `res://templates/scenes/BaseEntity.tscn`

```
BaseEntity (Node2D)
├── Visuals (Node2D)
├── Collision (Node2D)
├── Logic (Node) [has script: base_entity_logic.gd]
└── Metadata (Node)
```

**Role**: Defines the shape of every entity.

#### Level Template
**Path**: `res://templates/scenes/BaseLevel.tscn`

```
BaseLevel (Node2D)
├── Environment (Node2D)
├── SpawnPoints (Node2D)     ← Spawn markers live here
├── Triggers (Node2D)        ← Trigger areas live here
├── Navigation (Node2D)
├── Entities (Node2D)        ← Runtime spawned entities
├── Logic (Node) [has script: base_level_logic.gd]
└── Metadata (Node)          ← level_info dict stored as metadata
```

**Role**: Defines the structure that LevelSpec validates. All created levels inherit this shape.

---

### Creation Dialogs

#### EntityCreateDialog
**Path**: `addons/scene_spec_tools/entity_create_dialog.gd`

**Inputs**:
- Template (OptionButton) → scans `res://templates/scenes/` for `*.tscn`
- Entity Name (LineEdit) → becomes scene filename and root node name
- Category (LineEdit) → stored in `entity_info`
- Tags (LineEdit, comma-separated) → parsed into array

**Output**:
- Scene saved to: `res://scenes/entities/<Entity Name>.tscn`
- Root node name = `<Entity Name>`
- `Logic.entity_info` is set with all inputs

#### LevelCreateDialog
**Path**: `addons/scene_spec_tools/level_create_dialog.gd`

**Inputs**:
- Template (OptionButton) → scans `res://templates/scenes/` for `BaseLevel.tscn`
- Level Name (LineEdit) → becomes scene filename and root node name
- Display Name (LineEdit) → user-friendly name for menus (e.g., "Level 01")
- Order (SpinBox) → sort key for level registry and menus
- Music (LineEdit, optional) → path or ID for audio
- Tags (LineEdit, comma-separated) → parsed into array

**Output**:
- Scene saved to: `res://scenes/levels/<Level Name>.tscn`
- Root node name = `<Level Name>`
- `Metadata.level_info` is set with all inputs (stored as node metadata)

---

### Editor Integration (Plugin)

**File**: `addons/scene_spec_tools/scene_spec_tools.gd` (EditorPlugin)

**Menu Items** (under `Projects → Tools → Scene Spec/`):
1. `Validate All (Dry Run)` → runs all specs, no changes
2. `Auto-fix + Validate All` → runs specs + autofixes, saves scenes
3. `Create Entity From Template…` → opens EntityCreateDialog
4. `Create Level From Template…` → opens LevelCreateDialog (NEW)

---

## Workflow

### Creating an Entity

1. Go to `Projects → Tools → Scene Spec → Create Entity From Template…`
2. Select template (usually `BaseEntity.tscn`)
3. Enter entity name (e.g., `Player`)
4. Enter category (e.g., `protagonist`)
5. Enter tags (e.g., `hero,player`)
6. Click `Create`
7. New file: `res://scenes/entities/Player.tscn`
8. Open it in the editor and add visuals/collision to the appropriate containers

### Creating a Level

1. Go to `Projects → Tools → Scene Spec → Create Level From Template…`
2. Select template (should be `BaseLevel.tscn`)
3. Enter level name (e.g., `Level01`)
4. Enter display name (e.g., `The Beginning`)
5. Set order (e.g., `0` for first level)
6. Enter music (optional, e.g., `res://assets/audio/level01.ogg`)
7. Enter tags (optional, e.g., `tutorial,beginner`)
8. Click `Create`
9. New file: `res://scenes/levels/Level01.tscn`
10. Add SpawnPoint, Trigger, Environment nodes under the appropriate parents
11. Run validation to ensure structure is correct

---

## Validation System

### Scene Spec Runner
**File**: `tools/scene_specs/scene_spec_runner.gd`

Loads and runs **all applicable specs** for a scene:
- `LevelSpec` (levels only)
- `SpawnPointSpec` (levels with SpawnPoints)
- `TriggerSpec` (levels with Triggers)

Each spec:
- **Validates** structure (reports errors)
- **Autofixes** conservative issues (adds empty metadata, fills defaults)

### Specs in Play

| Spec | Applies To | Validates | Autofixes |
|------|------------|-----------|-----------|
| **LevelSpec** | `res://scenes/levels/*.tscn` (except BaseLevel) | Root name, required children, Logic script, Metadata.level_info structure | Adds missing nodes, Logic script, level_info defaults |
| **SpawnPointSpec** | Levels with `Level/SpawnPoints` | Node is `Node2D`, name starts with `Spawn_`, has `spawn_info` dict with `type`, `scene`, `tags` | Adds empty `spawn_info` |
| **TriggerSpec** | Levels with `Level/Triggers` | Node is `Area2D`, has `trigger_info` dict with non-empty `id`, `event`, bool `once`, array `tags` | Adds empty `trigger_info` |

---

## Constants (SceneSpecConstants)

**File**: `tools/scene_specs/scene_spec_constants.gd`

```gdscript
# Paths
ENTITY_SCENE_ROOT := "res://scenes/entities"
ENTITY_TEMPLATE_ROOT := "res://templates/scenes/"
LEVELS_DIR := "res://scenes/levels"

# Level metadata keys (enforced by LevelSpec)
LEVEL_METADATA_KEYS := ["id", "display_name", "order", "version", "music", "tags"]

# UI sizing
LEVEL_DIALOG_POPUP_SIZE := Vector2i(520, 260)
LEVEL_DIALOG_LABEL_WIDTH := 180
LEVEL_DIALOG_ORDER_MIN := -9999
LEVEL_DIALOG_ORDER_MAX := 9999
```

---

## Design Principles

### No Magic, No Scanning

- **Templates are explicit**: every level/entity inherits known structure
- **Metadata is stored**: `level_info` dict on Metadata node (not in script)
- **Validation is strict**: specs enforce discipline at creation + CI time
- **No runtime scanning**: [Registry generator](../generate_level_registry.gd) emits JSON artifact

### Composition Over Inheritance

- Templates define *containers* (Environment, SpawnPoints, Entities, etc.)
- Scripts are isolated to Logic node only
- Metadata node has no script (data-only)

### Designer Intent

- Dialogs ask for *what* designers want (name, order, tags)
- Autofixes never rename or remove nodes
- Validation catches wiring errors (missing children, wrong types)

---

## Next: Registry Generation

Once levels are created and validated:

1. **Run validation**: `Projects → Tools → Scene Spec → Auto-fix + Validate All`
2. **Generate registry**: `godot4 --headless --quit --script res://tools/generate_level_registry.gd`
   - Produces: `res://levels_registry.json`
   - Contains: ordered list of all levels with their metadata
3. **Use in menus**: Load JSON at runtime instead of scanning scenes

---

## Files Modified / Created

### New Files
- `addons/scene_spec_tools/level_create_dialog.gd` ← Dialog for level creation
- `tools/scene_specs/spawn_point_spec.gd` ← Validates spawn points
- `tools/scene_specs/trigger_spec.gd` ← Validates triggers
- `tools/generate_level_registry.gd` ← Generates JSON registry
- `scenes/levels/SpawnPoint.tscn` ← Template for designer reuse
- `scenes/levels/TriggerArea2D.tscn` ← Template for designer reuse

### Modified Files
- `addons/scene_spec_tools/scene_spec_tools.gd` ← Added level dialog + menu item
- `tools/scene_specs/scene_spec_runner.gd` ← Wired in SpawnPointSpec, TriggerSpec

---

## Summary

✅ **Symmetric creation** for entities and levels
✅ **Template-driven** (no copy-paste, consistent structure)
✅ **Validated** (specs catch wiring errors)
✅ **Composable** (containers + metadata, not inheritance)
✅ **No magic** (explicit paths, stored metadata, no scanning)

