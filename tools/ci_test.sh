#!/bin/bash

# CI validation script for Godot project
# Runs scene spec validation in headless mode

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Running Godot CI validation..."
echo "Project root: $PROJECT_ROOT"

# Run Godot in headless editor mode with validation script
cd "$PROJECT_ROOT"

godot --headless --editor --quit-after 5 --script res://addons/scene_spec_tools/ci_validate.gd

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "✓ CI validation passed"
    exit 0
else
    echo "✗ CI validation failed with exit code $exit_code"
    exit $exit_code
fi

