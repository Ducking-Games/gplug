@tool
extends PanelContainer

@onready var packed_integration_container: PackedScene = preload("uid://d3nxrbqbt6gw1")

@export var integration_container: Control
@export var ilIntegrationList: ItemList

var manifest: GPlugManifest = GPlugManifest.new()

var file_options: Dictionary[int, Callable] = {
	0: _add_new_integration,
	4: _reload_manifest,
	2: _save_backup,
	3: _restore_backup,
}

var workflow_options: Dictionary[int, Callable] = {
	0: _run_all,
	1: _disable_all,
}

func _ready() -> void:
	manifest.integration_added.connect(_on_integration_added)
	manifest.integration_removed.connect(_on_integration_removed)
	manifest.startup()

## Called when a file option is pressed
func _on_file_id_pressed(id: int) -> void:
	if file_options.has(id):
		file_options[id].call()

func _on_workflow_id_pressed(id: int) -> void:
	if workflow_options.has(id):
		workflow_options[id].call()

func _add_new_integration() -> void:
	glog._info("Adding new integration...")
	manifest.new_integration()

func _reload_manifest() -> void:
	glog._info("Reloading GPlug manifest...")
	ilIntegrationList.clear()
	ilIntegrationList.add_item("Select an Integration", null, false)
	for child in integration_container.get_children():
		child.queue_free()
	await get_tree().create_timer(0.1).timeout
	manifest.startup()

func _run_all() -> void:
	glog._info("Running all enabled integrations...")
	for integration in integration_container.get_children():
		var this_integration: GPlugIntegrationDisplay = integration as GPlugIntegrationDisplay
		if this_integration.integration.enabled:
			#this_integration.run_integration.emit(false)
			await this_integration._handle_run(false)

func _disable_all() -> void:
	glog._info("Disabling all integrations...")
	for integration in manifest.integrations:
		integration.enabled = false

func _save_backup() -> void:
	manifest.save(true)

func _restore_backup() -> void:
	glog._info("Reloading from GPlug manifest backup...")
	ilIntegrationList.clear()
	ilIntegrationList.add_item("Select an Integration", null, false)
	for child in integration_container.get_children():
		child.queue_free()
	await get_tree().create_timer(0.1).timeout
	manifest.startup(true)

func _on_integration_added(integration: GPlugIntegration) -> void:
	var integration_instance: GPlugIntegrationDisplay = packed_integration_container.instantiate()
	integration_instance.integration = integration
	integration_container.add_child(integration_instance)
	ilIntegrationList.add_item(integration.name)
	ilIntegrationList.select(ilIntegrationList.get_item_count() - 1)
	integration_instance.delete_integration.connect(manifest.remove_integration)
	integration.integration_changed.connect(_on_integration_changed.bind(integration))

func _on_integration_changed(integration: GPlugIntegration) -> void:
	ilIntegrationList.set_item_text(ilIntegrationList.get_selected_items()[0], integration.name)

func _on_integration_removed(integration: GPlugIntegration) -> void:
	_remove_integration(integration)

func _on_il_integration_list_item_selected(index: int) -> void:
	for child in integration_container.get_children():
		if child.integration.name == ilIntegrationList.get_item_text(index):
			child.visible = true
		else:
			child.visible = false

func _remove_integration(integration: GPlugIntegration) -> void:
	glog._info("Cleaning up integration '%s'..." % integration.name)
	for child in integration_container.get_children():
		if child.integration == integration:
			child.queue_free()
			break
	for i in ilIntegrationList.get_item_count():
		if ilIntegrationList.get_item_text(i) == integration.name:
			ilIntegrationList.remove_item(i)
			break
