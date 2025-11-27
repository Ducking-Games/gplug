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

func _get_plugin_name():
	return "GPlug"

func _has_main_screen() -> bool:
	return true

func _enable_plugin() -> void:
	_apply_settings()
	dock = packed_dock.instantiate()
	dock.name = "GPlug"
	#add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	EditorInterface.get_editor_main_screen().add_child(dock)
	_make_visible(false)
	get_editor_interface().set_main_screen_editor("GPlug")
	print_rich("[color=green]Loaded GPlug[/color]")

func _enter_tree() -> void:
	pass

func _disable_plugin() -> void:
	_revert_settings()
	if dock and dock.is_inside_tree():
		# if you don't do this you will make the main screen stuck
		# TODO: only do this if the current main screen is GPlug
		get_editor_interface().set_main_screen_editor("AssetLib")
		dock.queue_free()
		dock = null
		print_rich("[color=orange]Unloaded GPlug... quack![/color]")

func _exit_tree() -> void:
	pass

func _make_visible(visible: bool) -> void:
	if dock:
		dock.visible = visible

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
