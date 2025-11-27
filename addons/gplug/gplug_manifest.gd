@tool
## Stores/retrieves metadata about GPlug and its integrations
class_name GPlugManifest extends Resource

signal integration_added(integration: GPlugIntegration)
signal integration_removed(integration: GPlugIntegration)
signal manifest_changed()

const config_file: String = "gplug.cfg"
const backup: String = "gplug.bkp.cfg"

var integrations: Array[GPlugIntegration] = []

func _init() -> void:
    manifest_changed.connect(_handle_manifest_change)

func startup(from_backup: bool = false) -> void:
    glog._info("Loading GPlug manifest from '%s'..." % config_file)
    var err: Error = load_config(from_backup)
    if err != OK:
        glog._warn("Failed to load GPlug manifest from '%s'. Starting with an empty manifest." % config_file)


func _handle_manifest_change() -> void:
    save(false)

func generate_safe_name() -> String:
    var name: String = "New Integration"
    var increment: int = 0
    while get_integration(name) != null:
        increment += 1
        name = "New Integration %d" % increment
    return name

func get_integration(name: String) -> GPlugIntegration:
    for integration in integrations:
        if integration.name == name:
            return integration
    return null

func new_integration() -> Error:
    var integration: GPlugIntegration = GPlugIntegration.new()
    integration.name = generate_safe_name()
    integration.integration_changed.connect(manifest_changed.emit)
    add(integration)
    return OK

func remove_integration(integration: GPlugIntegration) -> void:
    integrations.erase(integration)
    integration_removed.emit(integration)
    manifest_changed.emit()

func add(integration: GPlugIntegration) -> void:
    integrations.append(integration)
    integration_added.emit(integration)
    manifest_changed.emit()

func build_save_data() -> ConfigFile:
    var current: ConfigFile = ConfigFile.new()
    for integration in integrations:
        integration.to_config(current)
    return current

func save(_backup: bool = false) -> Error:
    if _backup:
        glog._info("Saving GPlug manifest backup to '%s'..." % backup)
    else:
        glog._debug("Saving GPlug manifest to '%s'..." % config_file)
    var config: ConfigFile = build_save_data()
    var filepath: String = backup if _backup else config_file
    var err: Error = config.save(filepath)
    return err

func load_config(_backup: bool) -> Error:
    var filepath: String = backup if _backup else config_file
    var config: ConfigFile = ConfigFile.new()
    var err: Error = config.load(filepath)
    if err != OK:
        return err
    integrations.clear()
    for section in config.get_sections():
        glog._iinfo("Loading integration '%s' from manifest..." % section)
        var data: PackedStringArray = config.get_section_keys(section)
        var integration_data: Dictionary = {}
        for key in data:
            integration_data[key] = config.get_value(section, key)
        var integration: GPlugIntegration = GPlugIntegration.from_dict(integration_data)
        integration.integration_changed.connect(manifest_changed.emit)
        integration.name = section
        integrations.append(integration)
        integration_added.emit(integration)
    return OK