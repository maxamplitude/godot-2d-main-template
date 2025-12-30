# Level Templating System - Architecture Overview

This document provides a **bird's-eye view** of the level templating system, how all components fit together, and the design philosophy behind them.

---

## System Goal

Transform level creation from **"hope and pray it works"** to **"validated, deterministic, composable scenes."**

Core principles:
- **No magic**: Every rule is explicit and documented
- **No scanning**: Registry generation replaces runtime reflection
- **Composition over inheritance**: Containers + metadata, not class hierarchies
- **Early validation**: Catch wiring errors at creation, not at runtime

---

## System Components

### 1. Templates (Blueprints)

**What**: Pre-built scenes that define structure.

**Where**:
- `res://templates/scenes/BaseLevel.tscn`
- `res://templates/scenes/BaseEntity.tscn`

**Why**: Single source of truth. All created levels inherit known structure.

**Relationship**: Template → Instance relationship (copies, not inheritance)

```
Template (BaseLevel.tscn)
    ↓ (copy via dialog)
Instance (Level01.tscn)
    ↓ (instance in game)
Runtime Level Object
```

---

### 2. Creation Dialogs

**What**: UI tools to instantiate templates with metadata.

**Where**:
- `addons/scene_spec_tools/entity_create_dialog.gd`
- `addons/scene_spec_tools/level_create_dialog.gd`

**Why**: Enforce that new scenes have valid structure + metadata from day one.

**Flow**:
```
Designer clicks "Create Level From Template"
    ↓
Dialog collects: name, display_name, order, music, tags
    ↓
Dialog instantiates BaseLevel.tscn
    ↓
Dialog populates Metadata.level_info with inputs
    ↓
Dialog saves as Level01.tscn
    ↓
Level is ready for editing
```

---

### 3. Validation System (Specs)

**What**: Declarative validators that enforce contracts.

**Where**: `tools/scene_specs/`
- `scene_spec.gd` — Base class
- `scene_spec_runner.gd` — Orchestrator
- `level_spec.gd` — Levels
- `spawn_point_spec.gd` — Spawn points
- `trigger_spec.gd` — Triggers

**Why**: Catch wiring errors before they cause runtime bugs.

**Each spec defines**:
- **Scope**: Which scenes this spec applies to (e.g., "all .tscn files in res://scenes/levels/")
- **Contract**: What the scene must have (required children, metadata keys, etc.)
- **Errors**: What to report if contract is violated
- **Autofixes**: Conservative fixes (add metadata, fill defaults)

**Integration**:
- Manual: `Projects → Tools → Scene Spec → Validate All`
- Automatic: `Projects → Tools → Scene Spec → Auto-fix + Validate All` (saves scenes)
- CI/CD: `godot4 --headless --quit --script res://tools/validate_levels_headless.gd`

---

### 4. Registry Generation

**What**: A JSON file listing all valid levels in order.

**Where**: `res://levels_registry.json` (auto-generated)

**Why**: Eliminates runtime scene scanning. Deterministic, cacheable, auditable.

**Generator**: `tools/generate_level_registry.gd`

**Process**:
```
Scan res://scenes/levels/
    ↓ (for each .tscn file)
Load scene instantiate root
    ↓
Extract Metadata.level_info
    ↓
Verify all required keys (id, display_name, order)
    ↓
Collect into array
    ↓
Sort by "order" field
    ↓
Write levels_registry.json
```

**JSON Structure**:
```json
{
  "levels": [
    {
      "id": "level01",
      "scene": "res://scenes/levels/Level01.tscn",
      "display_name": "Level 01",
      "order": 0,
      "music": "res://assets/audio/level01.ogg",
      "tags": ["tutorial"]
    }
  ]
}
```

---

## System Workflows

### 1. Level Creation Workflow

```
Designer opens Godot editor
    ↓
Projects → Tools → Scene Spec → Create Level From Template…
    ↓
Dialog.popup_centered()
    ↓
Designer fills in:
  - Level Name: "Level01"
  - Display Name: "The Beginning"
  - Order: 0
  - Music: "res://assets/audio/level01.ogg"
  - Tags: "tutorial"
    ↓
Dialog instantiates BaseLevel.tscn
    ↓
Dialog sets root.name = "Level01"
    ↓
Dialog sets Metadata.level_info = { id, display_name, order, music, tags }
    ↓
Dialog calls scene.pack(root) + ResourceSaver.save()
    ↓
New file: res://scenes/levels/Level01.tscn
    ↓
Dialog emits level_created(path) signal
    ↓
Dialog closes
    ↓
Designer can now edit the level in the scene editor
```

### 2. Development Workflow

```
Designer edits level (adds nodes, content)
    ↓
Designer adds spawn points:
  - Spawn_Player (Node2D)
  - Spawn_Enemy_Goblin (Node2D)
    ↓
Designer adds triggers:
  - ExitZone (Area2D)
    ↓
Designer is uncertain about structure
    ↓
Projects → Tools → Scene Spec → Auto-fix + Validate All
    ↓
Runner scans directory for all .tscn scenes
    ↓
For each applicable scene:
  - Run LevelSpec (checks structure)
  - Run SpawnPointSpec (checks spawn points)
  - Run TriggerSpec (checks triggers)
    ↓
Runner collects errors and fixes
    ↓
Runner applies fixes:
  - Add missing spawn_info metadata
  - Add missing trigger_info metadata
  - Fill level_info defaults
    ↓
Runner saves all modified scenes
    ↓
Report window shows:
  - Checked: 1
  - Fixed: 1
  - Errors: 0
    ↓
Level is now fully validated
```

### 3. Build/CI Workflow

```
Developer pushes code to repo
    ↓
CI pipeline starts
    ↓
Step 1: Validate Levels
  godot4 --headless --quit --script res://tools/validate_levels_headless.gd
    ↓
  Scans all levels
  Runs validation (dry-run, no changes)
  Exit code 0 = all valid
  Exit code 1 = errors found (block deploy)
    ↓
Step 2: Generate Level Registry
  godot4 --headless --quit --script res://tools/generate_level_registry.gd
    ↓
  Scans all levels
  Extracts metadata
  Sorts by order
  Writes res://levels_registry.json
    ↓
Step 3: Optional - Commit Registry
  git add res://levels_registry.json
  git commit -m "chore: update level registry"
  git push
    ↓
Step 4: Build Game
  (Continue with normal build steps)
    ↓
Artifacts include:
  - Game executable
  - levels_registry.json (committed to repo)
```

### 4. Runtime Workflow

```
Game starts
    ↓
MainMenu._ready()
    ↓
Load levels_registry.json
  var file = FileAccess.open("res://levels_registry.json")
  var json = JSON.new()
  json.parse(file.get_as_text())
  var registry = json.data
    ↓
Populate level list UI
  for level in registry["levels"]:
    level_list.add_item(level["display_name"])
    ↓
User selects "Level 01"
    ↓
Menu calls App.load_level(registry["levels"][0]["scene"])
    ↓
App loads res://scenes/levels/Level01.tscn
    ↓
Level opens, Logic.entity_spawner reads SpawnPoints
    ↓
Spawner instantiates entities from spawn_info["scene"]
    ↓
Triggers detect player, emit events from trigger_info["event"]
    ↓
Level ends, next level advances via registry
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    DESIGN TIME                              │
│                                                             │
│  BaseLevel.tscn (Template)                                 │
│  ├── Environment                                            │
│  ├── SpawnPoints                                            │
│  ├── Triggers                                               │
│  ├── Navigation                                             │
│  ├── Entities                                               │
│  ├── Logic                                                  │
│  └── Metadata                                               │
│         │                                                    │
│         └─ [LevelCreateDialog instantiates]                │
│                                                             │
│  Level01.tscn (Instance)                                   │
│  ├── Environment (populated by designer)                   │
│  ├── SpawnPoints                                            │
│  │   ├── Spawn_Player → spawn_info = { type, scene, ... } │
│  │   └── Spawn_Enemy → spawn_info = { type, scene, ... }  │
│  ├── Triggers                                               │
│  │   └── ExitZone → trigger_info = { id, event, ... }     │
│  ├── Navigation                                             │
│  ├── Entities (empty at design time)                       │
│  ├── Logic → BaseLevelLogic script                         │
│  └── Metadata                                               │
│         └── level_info = { id, display_name, order, ... }  │
│                                                             │
│  [Validation]                                               │
│  ├── LevelSpec checks structure                            │
│  ├── SpawnPointSpec validates spawn_info                   │
│  └── TriggerSpec validates trigger_info                    │
│         │                                                    │
│         └─ [Registry Generator collects metadata]          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    BUILD TIME (CI)                          │
│                                                             │
│  levels_registry.json (Generated Artifact)                 │
│  {                                                          │
│    "levels": [                                              │
│      {                                                      │
│        "id": "level01",                                    │
│        "scene": "res://scenes/levels/Level01.tscn",        │
│        "display_name": "Level 01",                         │
│        "order": 0,                                          │
│        "music": "res://assets/audio/level01.ogg",          │
│        "tags": ["tutorial"]                                │
│      }                                                      │
│    ]                                                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    RUNTIME                                  │
│                                                             │
│  MainMenu                                                   │
│  ├─ Load levels_registry.json                             │
│  └─ Populate UI from registry["levels"]                   │
│         │                                                    │
│         └─ User clicks "Level 01"                          │
│                                                             │
│  App.load_level("res://scenes/levels/Level01.tscn")       │
│         │                                                    │
│         └─ Instantiate Level01                            │
│            ├─ Logic._ready() calls spawner               │
│            │  └─ Reads SpawnPoints[*].spawn_info         │
│            │     └─ Instantiates entities from scenes    │
│            │                                              │
│            └─ Triggers listen for events                 │
│               └─ Read trigger_info[*].event              │
│                  └─ Emit signals → App.advance_level()  │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

| Decision | Rationale | Consequence |
|----------|-----------|------------|
| **Templates** | Single source of truth | No copy-paste errors, consistent structure |
| **Creation dialogs** | Force metadata at creation | No empty/missing metadata bugs |
| **Metadata on Metadata node** | Data-only, no script creep | Explicit storage, designer-friendly |
| **Conservative autofixes** | Never guess designer intent | Validation catches real errors |
| **JSON registry** | Deterministic, auditable, cacheable | No runtime scene scanning, fast menus |
| **Explicit specs** | Clear contracts | Easy to extend, validate, test |
| **No inheritance** | Composition over hierarchy | Flexible, reusable containers |

---

## Extension Points

### Adding a New Spec

```gdscript
# res://tools/scene_specs/enemy_spawn_spec.gd
extends SceneSpec
class_name EnemySpawnSpec

func spec_name() -> String:
    return "EnemySpawnSpec"

func is_applicable(scene_path: String) -> bool:
    return scene_path.begins_with("res://scenes/enemies/")

func validate(scene_path: String, root: Node) -> Array[String]:
    # Your validation logic
    return []

func autofix(scene_path: String, root: Node) -> Array[String]:
    # Your autofix logic
    return []
```

Then register in `SceneSpecRunner._init()`.

### Adding a New Metadata Field

1. Add constant to `SceneSpecConstants`
2. Update dialog to collect input
3. Update spec to validate field
4. Update registry generator to include field

---

## Best Practices Summary

### Validation
- ✅ Run validation early and often
- ✅ Use autofixes for conservative issues
- ✅ Commit `levels_registry.json` to version control
- ✅ Include validation in CI/CD

### Level Design
- ✅ Use creation dialogs (never copy-paste scenes)
- ✅ Keep SpawnPoints/Triggers metadata accurate
- ✅ Keep Logic focused (one responsibility)
- ✅ Use tags for filtering at runtime

### Composition
- ✅ Treat containers (Environment, SpawnPoints, etc.) as immutable structure
- ✅ Populate Entities at runtime, not edit-time
- ✅ Keep all logic in Logic node only
- ✅ Use signals for inter-system communication

---

## Performance Characteristics

### Level Creation
- Time: ~100ms (instantiate + save)
- Overhead: Negligible

### Validation (dry-run)
- Time: ~50-100ms per level (load + instantiate + check)
- Scales linearly with level count

### Registry Generation
- Time: ~200-500ms (scan + extract + write)
- One-time per build, not per frame

### Runtime
- Menu load: ~10ms (parse JSON)
- Level spawn: No overhead (metadata pre-computed)

---

## Troubleshooting

**Q: Why JSON registry instead of scanning scenes at runtime?**
- A: Deterministic, fast, auditable, and doesn't require loading all scenes

**Q: Why composition instead of inheritance?**
- A: Flexibility. Different Logic scripts work with same container structure

**Q: Why autofixes are conservative?**
- A: Catch wiring errors (real bugs), not design errors (designer's choice)

**Q: Can I modify templates after creating instances?**
- A: Yes, but instances won't auto-update. They're copies, not linked

---

## Next Steps

Start here based on your role:

- **Designers**: Read [LEVEL_QUICKSTART.md](LEVEL_QUICKSTART.md)
- **Developers implementing features**: Read [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md)
- **System architects extending specs**: Read [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md)
- **Menu/UI programmers**: Read [LEVEL_REGISTRY.md](LEVEL_REGISTRY.md)
- **CI/CD integrators**: See generate_level_registry.gd and validate_levels_headless.gd

