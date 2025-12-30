extends SceneTree

const EntityFromJson := preload("res://addons/scene_spec_tools/entity_from_json.gd")
const SceneSpecConstants := preload("res://tools/scene_specs/scene_spec_constants.gd")

func _ready() -> void:
	var imported: Array[String] = []
	var errors: Array[String] = []
	
	# Look for JSON config files in the configured directory
	var config_dir := SceneSpecConstants.ENTITY_CONFIG_DIR
	var da := DirAccess.open(config_dir)
	
	if da == null:
		push_error("Failed to open config directory: %s" % config_dir)
		quit(1)
		return
	
	da.list_dir_begin()
	while true:
		var file := da.get_next()
		if file.is_empty():
			break
		
		# Only process JSON files (excluding example files)
		if file.ends_with(".json") and not file.ends_with(".example"):
			var json_path := "%s/%s" % [config_dir, file]
			
			print("Importing entity from: %s" % json_path)
			
			var creator := EntityFromJson.new()
			try:
				var scene_path := creator.create_from_json(json_path)
				imported.append(scene_path)
				print("  ✓ Created: %s" % scene_path)
			catch error:
				var err_msg := "Failed to import %s: %s" % [file, error]
				errors.append(err_msg)
				push_error(err_msg)
	
	da.list_dir_end()
	
	# Print summary
	print("\n--- Import Summary ---")
	print("Imported: %d entities" % imported.size())
	if not errors.is_empty():
		print("Errors: %d" % errors.size())
		for err in errors:
			print("  - %s" % err)
		quit(1)
		return
	
	print("✓ Entity import completed successfully")
	quit(0)

