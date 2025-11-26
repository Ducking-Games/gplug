@tool
extends PanelContainer

@onready var packed_integration_container: PackedScene = preload("uid://nyqljojfwpig")

@export var integration_container: Control


func _on_btn_add_tracking_pressed() -> void:
	var integration_instance: GPlugFoldingIntegration = packed_integration_container.instantiate()
	var integration: GPlugIntegration = GPlugIntegration.new()
	integration.name = "New Integration %d" % (integration_container.get_child_count() + 1)
	integration_instance.integration = integration
	integration_container.add_child(integration_instance)
