# godot-2d-main-template

A general template for 2D games - this should be extended for different game genres

## Overview

This template provides a foundational engine layer with reusable systems for 2D game development in Godot. It emphasizes composition, clarity, and determinism over quick prototyping.

## Features

### Scene Spec Tools (Addon)

The `scene_spec_tools` addon provides automated validation and management of entity scene structure:

- **Scene Spec Validation**: Validates that all entity scenes conform to the required structure
- **Auto-fix**: Automatically corrects common scene structure issues
- **Entity Templates**: Standardized templates for creating new entities
- **Integration**: Accessible via the Godot editor Tools menu and CI/CD pipelines

#### Using the Addon

**In the Editor:**
- `Tools > Scene Spec / Validate All (Dry Run)` - Check all entities without making changes
- `Tools > Scene Spec / Auto-fix + Validate All` - Automatically fix issues and validate

**In CI/CD:**
- See the CI Testing section below

### Project Structure

```
├── scripts/
│   ├── autoload/          # Global singletons (App, InputManager, etc.)
│   ├── core/              # Core systems (GameState, Config)
│   ├── entities/          # Entity logic and behaviors
│   ├── gameplay/          # Gameplay-specific systems
│   └── systems/           # Reusable systems (audio, camera, input, physics, UI)
├── scenes/
│   ├── base/              # Base entity scene
│   ├── levels/            # Level scenes
│   └── ui/                # UI scenes
├── templates/
│   └── scene_templates/   # Scene templates for entity creation
├── addons/
│   └── scene_spec_tools/  # Scene validation and management addon
├── assets/                # Art, audio, fonts
└── tools/                 # Build and CI scripts
```

## CI Testing

A CI test script is provided to validate scene structure in automated pipelines:

```bash
./tools/ci_test.sh
```

This script runs Godot in headless editor mode with the scene spec validator. It will:
1. Validate all entity scenes against the spec
2. Report any structural errors
3. Exit with code 0 on success, non-zero on failure

**Integration with CI/CD:**

```yaml
# Example GitHub Actions
- name: Validate Scene Structure
  run: ./tools/ci_test.sh
```

```yaml
# Example GitLab CI
validate_scenes:
  script:
    - ./tools/ci_test.sh
```

## Architecture Principles

- **Composition over Inheritance**: Keep inheritance hierarchies shallow
- **Autoload Usage**: Only use autoloads for App, Signals, InputManager, DebugManager, and AudioManager
- **Signals for Events**: Use signals at state boundaries; never embed UI logic in gameplay
- **Type Safety**: Use typed variables and return types where practical
- **Physics & Timing**: Use `_physics_process()` for physics-based gameplay
- **No Magic Numbers**: Use constants and configuration values

## Development Workflow

1. **Create Entity**: Use the editor dialog (`Tools > Scene Spec / Create Entity`) or add scenes to `scenes/entities/`
2. **Validate**: Run `Tools > Scene Spec / Validate All (Dry Run)` to check structure
3. **Auto-fix**: If issues found, run `Tools > Scene Spec / Auto-fix + Validate All` to fix them
4. **CI Check**: Before committing, run `./tools/ci_test.sh` to ensure all scenes are valid
