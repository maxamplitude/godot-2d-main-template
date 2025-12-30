# Level System - Quick Start Guide

This is a **quick reference** for common level workflows. For detailed docs, see the other guides.

---

## 5-Minute Setup

### 1. Create a Level

**Path**: `Projects → Tools → Scene Spec → Create Level From Template…`

**Fill in**:
- Level Name: `MyLevel`
- Display Name: `My Level`
- Order: `1` (sort order in menus)
- Music: (optional, path to audio file)
- Tags: (optional, comma-separated)

**Result**: `res://scenes/levels/MyLevel.tscn` with valid structure

### 2. Add Level Content

Open `res://scenes/levels/MyLevel.tscn` and add:

- **Environment**: TileMaps, sprites, parallax backgrounds
- **SpawnPoints**: Nodes named `Spawn_*` for entity spawning
- **Triggers**: Area2D nodes for events (exit, waves, etc.)
- **Navigation**: NavigationRegion2D for AI pathfinding
- **Logic**: Script with level-specific gameplay

### 3. Add Spawn Points

Under `SpawnPoints/`, add nodes:

```
SpawnPoints/
├── Spawn_Player (Node2D)
└── Spawn_Enemy_Goblin (Node2D)
```

Right-click each node → **Attach Node** → **Node2D** (if auto-creating).

Set metadata via Inspector:
- Add custom property → `spawn_info` (Dictionary)
- Fill with:
  ```
  {
    "type": "player",
    "scene": "res://scenes/entities/Player.tscn",
    "tags": []
  }
  ```

**Or** use autofix:
1. Leave spawn_info empty
2. Run `Projects → Tools → Scene Spec → Auto-fix + Validate All`
3. Autofix adds empty `spawn_info`

### 4. Add Triggers

Under `Triggers/`, add Area2D nodes:

```
Triggers/
└── ExitZone (Area2D)
    └── CollisionShape2D
```

Set metadata:
```
{
  "id": "exit_level",
  "event": "exit_level",
  "once": true,
  "tags": []
}
```

### 5. Validate

Run `Projects → Tools → Scene Spec → Auto-fix + Validate All`

Should report **0 errors**.

### 6. Generate Registry

```bash
godot4 --headless --quit --script res://tools/generate_level_registry.gd
```

---

## Common Tasks

### Create an Entity

**Path**: `Projects → Tools → Scene Spec → Create Entity From Template…`

**Fill in**:
- Entity Name: `Player`
- Category: `protagonist`
- Tags: `hero,player`

**Result**: `res://scenes/entities/Player.tscn`

Add sprites/collision, then save.

### Spawn an Entity at Runtime

```gdscript
# In level logic
var spawn_point = get_node("SpawnPoints/Spawn_Player")
var info = spawn_point.get_meta("spawn_info")
var entity = load(info["scene"]).instantiate()
entity.global_position = spawn_point.global_position
get_node("Entities").add_child(entity)
```

### Handle Trigger Events

```gdscript
# In level logic
for trigger in get_node("Triggers").get_children():
    var info = trigger.get_meta("trigger_info")
    trigger.area_entered.connect(func(body):
        Signals.emit_signal(info["event"], body)
    )
```

### Load Levels in a Menu

```gdscript
# In menu script
var file = FileAccess.open("res://levels_registry.json", FileAccess.READ)
var json = JSON.new()
json.parse(file.get_as_text())
var registry = json.data

for level in registry["levels"]:
    level_list.add_item(level["display_name"])
```

### Get Next Level

```gdscript
# In progression script
var all_levels = registry["levels"]
var current_index = 0  # Track this

if current_index < all_levels.size() - 1:
    current_index += 1
    var next_level = all_levels[current_index]
    App.load_level(next_level["scene"])
```

---

## Folder Structure

```
res://
├── scenes/
│   ├── entities/
│   │   ├── Player.tscn
│   │   └── Enemy.tscn
│   └── levels/
│       ├── BaseLevel.tscn (template, never edit)
│       ├── Level01.tscn
│       └── Level02.tscn
│
├── templates/scenes/
│   ├── BaseEntity.tscn (template)
│   └── BaseLevel.tscn (template)
│
├── scripts/
│   ├── levels/
│   │   ├── base_level_logic.gd
│   │   └── Level01Logic.gd
│   └── entities/
│       ├── base_entity_logic.gd
│       └── Player.gd
│
├── tools/
│   └── scene_specs/
│       ├── scene_spec_constants.gd
│       ├── scene_spec.gd
│       ├── scene_spec_runner.gd
│       ├── level_spec.gd
│       ├── spawn_point_spec.gd
│       └── trigger_spec.gd
│
├── addons/scene_spec_tools/
│   ├── scene_spec_tools.gd (plugin)
│   ├── entity_create_dialog.gd
│   ├── level_create_dialog.gd
│   └── scene_spec_validator.gd
│
├── docs/
│   ├── LEVEL_ENTITY_CREATION.md
│   ├── LEVEL_STRUCTURE.md
│   ├── SCENE_SPEC_SYSTEM.md
│   ├── LEVEL_REGISTRY.md
│   └── LEVEL_QUICKSTART.md (this file)
│
└── levels_registry.json (auto-generated)
```

---

## Validation Checklist

Before shipping a level, make sure:

- ✅ Level created via dialog (`Create Level From Template…`)
- ✅ All required children exist (Environment, SpawnPoints, Triggers, etc.)
- ✅ Root node name matches filename
- ✅ Logic node has a script
- ✅ Metadata.level_info is populated
- ✅ SpawnPoints have `spawn_info` metadata
- ✅ Triggers have `trigger_info` metadata
- ✅ No scripts on non-Logic nodes
- ✅ `Projects → Tools → Scene Spec → Validate All (Dry Run)` reports 0 errors
- ✅ Registry generated: `godot4 --headless --quit --script res://tools/generate_level_registry.gd`

---

## Troubleshooting

**Q: Validation fails with "missing spawn_info"**
- A: Run `Projects → Tools → Scene Spec → Auto-fix + Validate All` to add empty metadata

**Q: Level doesn't load in menu**
- A: Check that `levels_registry.json` exists. Run registry generator if missing.

**Q: Spawn points aren't showing in game**
- A: Check that `spawn_info["scene"]` path is correct. Use autofix + validate to populate.

**Q: "Level01 must match scene filename"**
- A: Root node name must match filename. Rename root to `Level01` if file is `Level01.tscn`.

---

## Next Steps

- See **LEVEL_ENTITY_CREATION.md** for detailed creation workflows
- See **LEVEL_STRUCTURE.md** for node hierarchy details
- See **SCENE_SPEC_SYSTEM.md** for validation internals
- See **LEVEL_REGISTRY.md** for runtime level loading

