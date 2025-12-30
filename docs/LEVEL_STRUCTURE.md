# Level Structure & Node Hierarchy

This document explains the **anatomy of a level scene** and how each container serves a specific purpose.

## Standard Level Structure

Every level created from the template inherits this structure:

```
Level01 (Node2D)
├── Environment (Node2D)
├── SpawnPoints (Node2D)
├── Triggers (Node2D)
├── Navigation (Node2D)
├── Entities (Node2D)
├── Logic (Node) [has script: BaseLevelLogic]
└── Metadata (Node) [has metadata: level_info]
```

---

## Container Purposes

### Environment

**Purpose**: Static visual and collision elements.

**Typically contains**:
- Tilemap nodes (TileMap, TileMapLayer)
- Static bodies (StaticBody2D)
- Sprites for background layers
- Parallax backgrounds (ParallaxLayer)

**Rules**:
- No scripts in Environment
- No gameplay logic
- Can have collision shapes

**Example**:
```gdscript
Environment/
├── Ground (TileMapLayer)
├── Walls (TileMapLayer)
└── Background (ParallexLayer)
    └── Sky (Sprite2D)
```

---

### SpawnPoints

**Purpose**: Markers for spawning entities at runtime.

**Structure**:
```
SpawnPoints/
├── Spawn_Player (Node2D)
├── Spawn_Enemy_A (Node2D)
├── Spawn_Enemy_B (Node2D)
└── Spawn_Item_Health (Node2D)
```

**Naming Convention**: `Spawn_<Type>_<OptionalID>`

- `Spawn_Player` — single player spawn (no ID)
- `Spawn_Enemy_Boss` — boss enemy
- `Spawn_Item_Coin_01` — specific item pickup location

**Metadata Contract** (set via dialog or manually):

```gdscript
{
  "type": "player | enemy | item | npc",     # required
  "id": "",                                   # optional but stable
  "scene": "res://scenes/entities/...",       # path to spawn
  "tags": [],                                 # optional filters
}
```

**Validation**:
- Node must be `Node2D`
- Name must start with `Spawn_`
- Must have `spawn_info` metadata
- `spawn_info["type"]` must not be empty

**Auto-fix**:
- Adds empty `spawn_info` if missing

**Runtime Usage**:

```gdscript
# In your game logic
for spawn_point in level.get_node("SpawnPoints").get_children():
    var info = spawn_point.get_meta("spawn_info")
    if info["type"] == "player":
        var entity = load(info["scene"]).instantiate()
        entity.global_position = spawn_point.global_position
        level.get_node("Entities").add_child(entity)
```

---

### Triggers

**Purpose**: Areas that detect player/entity interaction and emit events.

**Structure**:
```
Triggers/
├── Trigger (Area2D)
│   └── CollisionShape2D
├── ExitZone (Area2D)
│   └── CollisionShape2D
└── BossArena (Area2D)
    └── CollisionShape2D
```

**Naming**: Descriptive name (no strict prefix).

**Metadata Contract**:

```gdscript
{
  "id": "exit_level_01",         # required, non-empty
  "event": "exit_level",         # required, non-empty
  "once": true,                  # required, bool
  "tags": [],                    # optional
}
```

**Validation**:
- Node must be `Area2D`
- Must have `trigger_info` metadata
- `trigger_info["id"]` must not be empty
- `trigger_info["event"]` must not be empty
- `trigger_info["once"]` must be a bool

**Auto-fix**:
- Adds empty `trigger_info` if missing

**Runtime Usage**:

```gdscript
# In your trigger logic script
for trigger in level.get_node("Triggers").get_children():
    var info = trigger.get_meta("trigger_info")
    trigger.area_entered.connect(func(body):
        Signals.emit_signal(info["event"], body)
    )
```

---

### Navigation

**Purpose**: Pathfinding and AI navigation data.

**Typically contains**:
- NavigationRegion2D nodes
- NavigationMesh/NavigationPolygon resources
- Waypoint markers (for custom pathfinding)

**Rules**:
- Navigation shapes define walkable areas
- Can have helper nodes for debugging
- No gameplay logic

**Example**:
```gdscript
Navigation/
├── Walkable (NavigationRegion2D)
└── WaypointsForAI (Node2D)  [debug/reference only]
    ├── Waypoint01 (Node2D)
    ├── Waypoint02 (Node2D)
    └── Waypoint03 (Node2D)
```

---

### Entities

**Purpose**: Container for entities spawned at runtime.

**Never manually populate this at edit-time** — it's for runtime spawns only.

**Typically empty in the scene editor**, populated by:
- Spawn manager
- Level logic scripts
- Enemy waves

**Runtime Example**:
```gdscript
# Level logic spawns enemies here
var enemy = enemy_scene.instantiate()
get_node("Entities").add_child(enemy)
```

---

### Logic

**Purpose**: Level-specific gameplay behavior.

**Requirements**:
- Must have a script (e.g., `BaseLevelLogic` or custom subclass)
- No visual representation in the scene
- Owns game state for this level (waves, objectives, etc.)

**Typical Responsibilities**:
- Enemy spawning logic
- Objective tracking
- Level progression checks
- Audio/music control
- Pause/resume handling

**Example Script**:

```gdscript
# res://scripts/levels/MyLevelLogic.gd
extends BaseLevelLogic

var _enemy_waves: Array = []
var _current_wave: int = 0

func _ready() -> void:
    _setup_level()
    Signals.player_died.connect(_on_player_died)

func _setup_level() -> void:
    # Populate _enemy_waves, configure music, etc.
    pass

func _on_player_died() -> void:
    print("Level failed!")
    get_tree().reload_current_scene()
```

---

### Metadata

**Purpose**: Level configuration and identity.

**Storage**: Node2D with no script, metadata stored as node metadata dictionary.

**Contents** (stored as `metadata.level_info`):

```gdscript
{
  "id": "level01",                           # unique identifier
  "display_name": "The Beginning",           # user-friendly name
  "order": 0,                                # sort order for menus
  "version": 1,                              # schema version
  "music": "res://assets/audio/level01.ogg", # music path (optional)
  "tags": ["tutorial", "beginner"],          # filter tags
}
```

**Set By**:
- `LevelCreateDialog` during creation
- `LevelSpec.autofix()` if missing

**Never Edit Manually** — use the creation dialog.

---

## Complete Level Example

```gdscript
# Example: res://scenes/levels/TutorialLevel.tscn

TutorialLevel (Node2D)
├── Environment (Node2D)
│   ├── Ground (TileMapLayer)
│   ├── Walls (TileMapLayer)
│   └── Background (ParallaxLayer)
│       └── Sky (Sprite2D)
│
├── SpawnPoints (Node2D)
│   ├── Spawn_Player (Node2D) @ (100, 100)
│   │   meta: {
│   │     "type": "player",
│   │     "id": "",
│   │     "scene": "res://scenes/entities/Player.tscn",
│   │     "tags": [],
│   │   }
│   └── Spawn_Enemy_A (Node2D) @ (500, 150)
│       meta: {
│         "type": "enemy",
│         "id": "tutorial_enemy",
│         "scene": "res://scenes/entities/Goblin.tscn",
│         "tags": ["tutorial"],
│       }
│
├── Triggers (Node2D)
│   └── ExitZone (Area2D) @ (800, 100)
│       meta: {
│         "id": "exit_tutorial",
│         "event": "exit_level",
│         "once": true,
│         "tags": [],
│       }
│       └── CollisionShape2D
│
├── Navigation (Node2D)
│   └── Walkable (NavigationRegion2D)
│
├── Entities (Node2D) [empty at edit-time]
│
├── Logic (Node)
│   script: res://scripts/levels/TutorialLevelLogic.gd
│
└── Metadata (Node)
    meta: {
      "level_info": {
        "id": "tutorial_level",
        "display_name": "Tutorial",
        "order": 0,
        "version": 1,
        "music": "res://assets/audio/tutorial.ogg",
        "tags": ["tutorial", "beginner"],
      }
    }
```

---

## Validation Rules

When you run `Projects → Tools → Scene Spec → Auto-fix + Validate All`:

### LevelSpec Checks
- ✅ Root node name matches filename
- ✅ All required children exist (Environment, SpawnPoints, Triggers, Navigation, Entities, Logic, Metadata)
- ✅ Logic node has a script
- ✅ Metadata node has `level_info` dictionary
- ✅ `level_info` contains all required keys
- ✅ No scripts on nodes except Logic

### SpawnPointSpec Checks
- ✅ SpawnPoints children are `Node2D`
- ✅ Names start with `Spawn_`
- ✅ Have `spawn_info` metadata
- ✅ `spawn_info["type"]` is not empty
- ✅ `spawn_info["scene"]` key exists
- ✅ `spawn_info["tags"]` is an array

### TriggerSpec Checks
- ✅ Triggers children are `Area2D`
- ✅ Have `trigger_info` metadata
- ✅ `trigger_info["id"]` is non-empty
- ✅ `trigger_info["event"]` is non-empty
- ✅ `trigger_info["once"]` is a bool
- ✅ `trigger_info["tags"]` is an array

---

## Best Practices

### Do's ✅
- Use the creation dialog to instantiate levels
- Run validation regularly (`Projects → Tools → Scene Spec → Auto-fix + Validate All`)
- Keep spawn point metadata accurate
- Use meaningful trigger IDs
- Store tags in triggers for runtime filtering
- Keep Logic node focused (spawn specific logic in Scripts, not the node tree)

### Don'ts ❌
- Manually add scripts to non-Logic nodes
- Rename the root node after creation
- Move SpawnPoints/Triggers to different parents
- Leave spawn_info or trigger_info empty
- Populate Entities manually (spawn at runtime)
- Add visual elements to the Logic node

---

## Next Steps

1. **Create a level**: `Projects → Tools → Scene Spec → Create Level From Template…`
2. **Add environment**: Populate Environment with TileMaps/StaticBodies
3. **Define spawn points**: Add Spawn_* nodes under SpawnPoints with metadata
4. **Define triggers**: Add Area2D nodes under Triggers with metadata
5. **Write Logic**: Create a script extending `BaseLevelLogic`
6. **Validate**: Run `Projects → Tools → Scene Spec → Auto-fix + Validate All`
7. **Generate registry**: `godot4 --headless --quit --script res://tools/generate_level_registry.gd`

See [LEVEL_ENTITY_CREATION.md](LEVEL_ENTITY_CREATION.md) for detailed workflows.

