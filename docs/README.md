# Level Templating System - Documentation Index

Complete documentation for the **level and entity templating system**.

---

## Quick Navigation

### 🚀 **I just want to create a level**

→ **[LEVEL_QUICKSTART.md](LEVEL_QUICKSTART.md)**

5-minute guide with copy-paste workflows. Start here.

---

### 🏗️ **I want to understand the architecture**

1. **[LEVEL_SYSTEM_ARCHITECTURE.md](LEVEL_SYSTEM_ARCHITECTURE.md)** — Big picture overview
2. **[LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md)** — Node hierarchy and metadata contracts
3. **[SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md)** — Validation system internals
4. **[LEVEL_REGISTRY.md](LEVEL_REGISTRY.md)** — Runtime level loading

---

### 📝 **I need to look up a specific concept**

| Concept | Document |
|---------|----------|
| Creating a level | [LEVEL_QUICKSTART.md](LEVEL_QUICKSTART.md#5-minute-setup) |
| Level structure (node hierarchy) | [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md) |
| SpawnPoints (data + validation) | [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md#spawnpoints) |
| Triggers (data + validation) | [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md#triggers) |
| Validation system | [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md) |
| Specs (LevelSpec, SpawnPointSpec, TriggerSpec) | [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md#specifications) |
| Registry generation | [LEVEL_REGISTRY.md](LEVEL_REGISTRY.md) |
| Runtime level loading in menus | [LEVEL_REGISTRY.md](LEVEL_REGISTRY.md#runtime-usage) |
| Level progression | [LEVEL_REGISTRY.md](LEVEL_REGISTRY.md#level-progression-example) |
| Full architecture overview | [LEVEL_SYSTEM_ARCHITECTURE.md](LEVEL_SYSTEM_ARCHITECTURE.md) |

---

## Documentation Summary

### [LEVEL_QUICKSTART.md](LEVEL_QUICKSTART.md)
**For**: Designers and developers creating levels

**Contains**:
- 5-minute setup checklist
- Common tasks with code examples
- Folder structure reference
- Validation checklist
- Troubleshooting

**Read this first if**: You just want to create a level and get to work.

---

### [LEVEL_SYSTEM_ARCHITECTURE.md](LEVEL_SYSTEM_ARCHITECTURE.md)
**For**: System architects and developers extending the system

**Contains**:
- Bird's-eye view of all components
- System goals and design philosophy
- Component responsibilities
- System workflows (creation, development, CI, runtime)
- Data flow diagrams
- Extension points
- Performance characteristics

**Read this if**: You want to understand how everything fits together.

---

### [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md)
**For**: Level designers and level logic programmers

**Contains**:
- Standard level node hierarchy
- Purpose of each container (Environment, SpawnPoints, Triggers, etc.)
- SpawnPoint naming convention + metadata contract
- Trigger metadata contract
- Validation rules
- Best practices
- Complete level example
- Runtime usage patterns

**Read this if**: You need to understand what goes where in a level scene.

---

### [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md)
**For**: Developers extending validation or adding new specs

**Contains**:
- Base SceneSpec class interface
- SceneSpecRunner orchestration
- LevelSpec validation rules
- SpawnPointSpec validation rules
- TriggerSpec validation rules
- SceneSpecConstants reference
- Manual validation (editor)
- Programmatic validation (scripts)
- Headless validation (CI)
- How to extend with new specs
- Design philosophy
- Troubleshooting

**Read this if**: You need to understand validation or add custom specs.

---

### [LEVEL_REGISTRY.md](LEVEL_REGISTRY.md)
**For**: Menu programmers and runtime system developers

**Contains**:
- Registry generation process
- Registry JSON schema
- How to generate (manual + CI/CD)
- Registry generator script walkthrough
- Runtime API (load registry, get levels, filter by tag)
- Level selection menu example
- Level progression example
- Troubleshooting

**Read this if**: You're implementing menus or progression logic.

---

### [LEVEL_ENTITY_CREATION.md](LEVEL_ENTITY_CREATION.md)
**For**: Overview of the entire creation system (entities + levels)

**Contains**:
- System overview
- Architecture (templates, dialogs, plugin)
- Creation workflows (entity + level)
- Validation system summary
- Constants reference
- Design principles
- File manifest

**Read this if**: You want a high-level view that covers both entities and levels.

---

## File Locations

### Scenes
```
res://templates/scenes/
├── BaseEntity.tscn       (entity template)
└── BaseLevel.tscn        (level template)

res://scenes/entities/
└── [user-created entities]

res://scenes/levels/
├── BaseLevel.tscn        (never edit; use template)
└── [user-created levels]

res://scenes/levels/
├── SpawnPoint.tscn       (template for designers)
└── TriggerArea2D.tscn    (template for designers)
```

### Tools & Scripts
```
res://tools/
└── scene_specs/
    ├── scene_spec.gd              (base class)
    ├── scene_spec_runner.gd       (orchestrator)
    ├── scene_spec_constants.gd    (config)
    ├── level_spec.gd              (level validator)
    ├── spawn_point_spec.gd        (spawn point validator)
    └── trigger_spec.gd            (trigger validator)

res://tools/
├── validate_levels_headless.gd    (CI validation)
└── generate_level_registry.gd     (registry generator)

res://addons/scene_spec_tools/
├── scene_spec_tools.gd            (plugin + menu)
├── entity_create_dialog.gd        (entity creation)
├── level_create_dialog.gd         (level creation)
└── scene_spec_validator.gd        (validation reporter)
```

### Documentation (This Folder)
```
docs/
├── README.md (this file)
├── LEVEL_QUICKSTART.md
├── LEVEL_SYSTEM_ARCHITECTURE.md
├── LEVEL_STRUCTURE.md
├── SCENE_SPEC_SYSTEM.md
├── LEVEL_REGISTRY.md
└── LEVEL_ENTITY_CREATION.md
```

### Generated
```
res://levels_registry.json         (auto-generated, commit to repo)
```

---

## Quick Reference

### Creating a Level
```bash
Projects → Tools → Scene Spec → Create Level From Template…
```

### Creating an Entity
```bash
Projects → Tools → Scene Spec → Create Entity From Template…
```

### Validating All Scenes
```bash
Projects → Tools → Scene Spec → Validate All (Dry Run)
# or
Projects → Tools → Scene Spec → Auto-fix + Validate All
```

### Generating Registry
```bash
godot4 --headless --quit --script res://tools/generate_level_registry.gd
```

### Headless CI Validation
```bash
godot4 --headless --quit --script res://tools/validate_levels_headless.gd
```

---

## System Components at a Glance

| Component | File | Purpose |
|-----------|------|---------|
| **Template (Level)** | `res://templates/scenes/BaseLevel.tscn` | Blueprint for all levels |
| **Template (Entity)** | `res://templates/scenes/BaseEntity.tscn` | Blueprint for all entities |
| **Creation Dialog (Level)** | `addons/scene_spec_tools/level_create_dialog.gd` | UI to create new levels |
| **Creation Dialog (Entity)** | `addons/scene_spec_tools/entity_create_dialog.gd` | UI to create new entities |
| **Plugin** | `addons/scene_spec_tools/scene_spec_tools.gd` | EditorPlugin, menu items, dialogs |
| **Base Spec** | `tools/scene_specs/scene_spec.gd` | Abstract validator base |
| **Spec Runner** | `tools/scene_specs/scene_spec_runner.gd` | Orchestrates all specs |
| **Level Spec** | `tools/scene_specs/level_spec.gd` | Validates level structure |
| **SpawnPoint Spec** | `tools/scene_specs/spawn_point_spec.gd` | Validates spawn points |
| **Trigger Spec** | `tools/scene_specs/trigger_spec.gd` | Validates triggers |
| **Constants** | `tools/scene_specs/scene_spec_constants.gd` | Config, paths, UI sizing |
| **Registry Generator** | `tools/generate_level_registry.gd` | Builds `levels_registry.json` |
| **CI Validator** | `tools/validate_levels_headless.gd` | Headless validation for CI/CD |

---

## Design Philosophy

### No Magic
- Every rule is explicit
- Validation is declarative (specs)
- Metadata is stored, not inferred
- Registry is generated, not computed at runtime

### No Scanning
- Registry eliminates runtime reflection
- Levels are loaded on-demand, not enumerated
- Menus read JSON, not filesystem

### Composition Over Inheritance
- Containers define structure (Environment, SpawnPoints, etc.)
- Scripts are isolated to Logic node only
- Metadata node is data-only

### Conservative Validation
- Autofixes never rename, delete, or guess
- Catch wiring errors (real bugs), not design choices
- Designer intent is respected

### Early Discipline
- Validation at creation (dialogs)
- Validation during development (editor UI)
- Validation at build time (CI/CD)

---

## Workflow Summary

```
1. Designer creates level via dialog
   → Level has valid structure + metadata

2. Designer edits level in scene editor
   → Adds environment, spawn points, triggers

3. Developer validates (manual or CI)
   → Specs check structure
   → Autofixes add missing metadata

4. CI generates registry
   → levels_registry.json created

5. Game starts → Menu loads registry
   → Player selects level
   → App loads level scene
   → Level logic spawns entities from SpawnPoints
   → Triggers emit events
   → Next level advances via registry
```

---

## Getting Started

**New to this system?**
1. Read [LEVEL_QUICKSTART.md](LEVEL_QUICKSTART.md) (5 min)
2. Create a test level via `Projects → Tools → Scene Spec → Create Level From Template…`
3. Add some spawn points and triggers
4. Run validation: `Projects → Tools → Scene Spec → Auto-fix + Validate All`
5. See [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md) for details on what goes where

**Want to understand the architecture?**
1. Read [LEVEL_SYSTEM_ARCHITECTURE.md](LEVEL_SYSTEM_ARCHITECTURE.md) (15 min)
2. Skim [LEVEL_STRUCTURE.md](LEVEL_STRUCTURE.md) for node hierarchy
3. Skim [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md) for validation
4. Skim [LEVEL_REGISTRY.md](LEVEL_REGISTRY.md) for runtime loading

**Extending the system?**
1. Read [SCENE_SPEC_SYSTEM.md](SCENE_SPEC_SYSTEM.md) (understand specs)
2. Create a new spec class extending `SceneSpec`
3. Register in `SceneSpecRunner._init()`
4. Test with `Projects → Tools → Scene Spec → Validate All`

---

## Troubleshooting Index

| Problem | Solution |
|---------|----------|
| Level creation dialog is slow | First-time load of addon takes time; subsequent opens are fast |
| Validation reports missing metadata | Run `Auto-fix + Validate All` to auto-populate |
| Registry is empty | Check that levels have `Metadata.level_info` with `id`, `display_name`, `order` |
| Menu doesn't show levels | Regenerate registry: `godot4 --headless --quit --script res://tools/generate_level_registry.gd` |
| Spawn points aren't working | Check `spawn_info["scene"]` path and instantiation in Logic script |
| Triggers don't fire | Check `trigger_info["event"]` and ensure trigger detection in Logic script |
| Root name validation fails | Root node name must match filename exactly (case-sensitive) |

See individual docs for deeper troubleshooting.

---

## Contributing

To improve this system:
1. Add new specs for new scene types
2. Extend dialogs for additional metadata
3. Improve validation error messages
4. Add registry features (categories, difficulty, etc.)

All changes should follow:
- **No magic**: Explicit rules only
- **Conservative**: Never guess designer intent
- **Documented**: Comments and docs before code

---

## License

Same as project license. See LICENSE file.

---

Last updated: 2024-12-29
System version: 1.0
Godot version: 4.x

