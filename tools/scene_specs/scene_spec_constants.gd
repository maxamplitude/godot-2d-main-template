@tool
extends RefCounted

const ENTITY_SCENE_ROOT := "res://scenes/entities"
const ENTITY_TEMPLATE_ROOT := "res://templates/scenes"
const ENTITY_CONFIG_DIR := "res://config/entities"
const DEFAULT_ENTITY_VERSION := 1

const ENTITY_DIALOG_POPUP_SIZE := Vector2i(500, 300)
const ENTITY_DIALOG_LABEL_WIDTH := 120

const LEVEL_TEMPLATE_ROOT := "res://templates/scenes"
const LEVELS_DIR := "res://scenes/levels"
const LEVEL_REQUIRED_CHILDREN := [
    "Environment",
    "SpawnPoints",
    "Triggers",
    "Navigation",
    "Entities",
    "Logic",
    "Metadata",
]
const BASE_LEVEL_SCENE := "res://scenes/levels/BaseLevel.tscn"
const BASE_LEVEL_LOGIC := "res://scripts/levels/base_level_logic.gd"
const LEVEL_METADATA_KEYS := ["id", "display_name", "order", "version", "music", "tags"]

const LEVEL_DEFAULT_NAME := "Level01"
const LEVEL_DEFAULT_DISPLAY_NAME := "Level 01"
const LEVEL_DEFAULT_ID := "level01"
const LEVEL_DEFAULT_ORDER := 0

const LEVEL_DIALOG_POPUP_SIZE := Vector2i(520, 260)
const LEVEL_DIALOG_MIN_SIZE := Vector2(500, 220)
const LEVEL_DIALOG_LABEL_WIDTH := 180
const LEVEL_DIALOG_ORDER_MIN := -9999
const LEVEL_DIALOG_ORDER_MAX := 9999

const LEVEL_STATUS_MESSAGE := "Created level:"

