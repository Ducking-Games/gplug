@tool
extends EditorPlugin

var ESD = preload("external/editor_settings_description.gd")

var packed_dock: PackedScene = preload("uid://b18q2uxcpumvk")
var dock: Control

var settings_path: String = "gplug"

var gplug_settings: Dictionary[String, Dictionary] = {
	"debug_logging": {
		"name": "%s/enable_debug_logging" % settings_path,
		"type": TYPE_BOOL,
		"basic": true,
		"default": false,
		"hint": PROPERTY_HINT_NONE,
		"hint_tooltip": "Enables debug logging for GPlug, useful for development and debugging.",
	}
}

func _enter_tree() -> void:
	_apply_settings()
	dock = packed_dock.instantiate()
	dock.name = "GPlug"
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	print_rich("[color=green]Loaded GPlug[/color]")


func _exit_tree() -> void:
	_revert_settings()
	if dock and dock.is_inside_tree():
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null
		print_rich("[color=orange]Unloaded GPlug... quack![/color]")
	pass

func _apply_settings() -> void:
	for setting in gplug_settings:
		var data: Dictionary = gplug_settings[setting]
		var name: String = data["name"]
		ProjectSettings.set_setting(name, data.get("name"))
		ProjectSettings.set_as_basic(name, data.get("basic"))
		ProjectSettings.add_property_info(data)
		ProjectSettings.set_initial_value(name, data.get("default"))
		ESD.set_project_setting_desc(name, data.get("hint_tooltip", ""))

func _revert_settings() -> void:
	for setting in gplug_settings:
		var data: Dictionary = gplug_settings[setting]
		var name: String = data["name"]
		if ProjectSettings.has_setting(name):
			ProjectSettings.clear(name)
