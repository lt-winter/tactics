extends SceneTree


func _initialize() -> void:
	print("WARNINGS_AS_ERRORS=", ProjectSettings.get_setting("debug/gdscript/warnings/treat_warnings_as_errors", false))
	for path: String in DirAccess.get_files_at("res://scripts/test"):
		if not path.ends_with("_test.gd"):
			continue
		print("SUITE_BEGIN: ", path)
		var suite: Script = load("res://scripts/test/" + path)
		if suite == null or not suite.can_instantiate():
			push_error("SUITE_LOAD_FAILED: " + path)
			continue
		suite.call("run_all")
		# Inspect suite PASS markers and SCRIPT ERRORs too, not just this marker.
		print("SUITE_RETURNED: ", path)
	quit()
