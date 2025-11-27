@tool
class_name GPlugFoldingIntegration extends FoldableContainer

signal enabled_toggled(pressed: bool)
signal run()
signal delete_integration_request()

@export var integration: GPlugIntegration

@export_group("Integration Details")
@export var leIntegrationName: LineEdit
@export var obOrigin: OptionButton
@export var leRepository: LineEdit
@export var leBranch: LineEdit
@export var leRepoTarget: LineEdit
@export var leProjectTarget: LineEdit
@export var teNotes: TextEdit
@export var ilTargets: ItemList
@export var lblLastIntegratedHash: Label
@export var lblLastIntegratedTime: Label

@export_group("Icons")
@export var delete_integration_icon: Texture2D
@export var delete_integration_confirm_icon: Texture2D
@export var run_integration_icon: Texture2D
@export var enabled_integration_icon: Texture2D
@export var dark_enabled_integration_icon: Texture2D

var btnEnable: Button
var btnDelete: Button
var btnRun: Button

var awaiting_delete_confirmation: bool = false
var awaiting_delete_timer: Timer

var awaiting_run_completion: bool = false

var targets_selected: Array[int] = []

func _init() -> void:
	run.connect(_run_integration)
	delete_integration_request.connect(_delete_integration)
	enabled_toggled.connect(_enabled_toggled)

func _ready() -> void:
	ilTargets.item_selected.connect(func(idx: int):
		targets_selected.append(idx)
	)
	ilTargets.empty_clicked.connect(func(_at: Vector2, _btn_index: int):
		targets_selected.clear()
		ilTargets.deselect_all()
	)
	leIntegrationName.text_changed.connect(func(new_text: String):
		integration.name = new_text
		title = new_text
	)
	obOrigin.item_selected.connect(func(idx: int):
		integration.origin = GitGet.OriginIndex(obOrigin.get_item_text(idx))
	)
	leRepository.text_changed.connect(func(new_text: String):
		integration.repo = new_text
	)
	leBranch.text_changed.connect(func(new_text: String):
		integration.branch = new_text
	)
	teNotes.text_changed.connect(func():
		integration.notes = teNotes.text
	)
	

func _enter_tree() -> void:
	btnEnable = Button.new()
	#btnEnable.icon = enable_integration_icon
	btnEnable.tooltip_text = "Disable Integration"
	btnEnable.toggle_mode = true
	btnEnable.flat = true
	btnEnable.set_pressed_no_signal(integration.enabled)
	_enabled_toggled(integration.enabled)
	btnEnable.toggled.connect(enabled_toggled.emit)
	add_title_bar_control(btnEnable)


	btnRun = Button.new()
	btnRun.icon = run_integration_icon
	btnRun.tooltip_text = "Run THIS Integration Now"
	btnRun.pressed.connect(run.emit)
	add_title_bar_control(btnRun)

	btnDelete = Button.new()
	btnDelete.icon = delete_integration_icon
	btnDelete.tooltip_text = "Delete Integration"
	btnDelete.pressed.connect(_show_delete_confirmation)
	add_title_bar_control(btnDelete)

	awaiting_delete_timer = Timer.new()
	awaiting_delete_timer.wait_time = 5.0
	awaiting_delete_timer.one_shot = true
	awaiting_delete_timer.timeout.connect(_cancel_delete)
	add_child(awaiting_delete_timer)

	for origin in GitGet.origins:
		obOrigin.add_item(origin["name"])
		obOrigin.set_item_icon(obOrigin.get_item_count() - 1, GitGet.origin_icons().get(origin["icon"]))
		obOrigin.set_item_disabled((obOrigin.get_item_count() - 1), not origin["supported"])

	_update_ui()

func _exit_tree() -> void:
	awaiting_delete_timer.queue_free()


func _update_ui() -> void:
	obOrigin.selected = int(integration.origin)

	if integration:
		title = integration.name
		leIntegrationName.text = integration.name
		leRepository.text = integration.repo
		leBranch.text = integration.branch
		teNotes.text = integration.notes
		obOrigin.selected = int(integration.origin)
		lblLastIntegratedHash.text = "Last Integrated: " + integration.last_integrated_hash if integration.last_integrated_hash != "" else "Last Integrated: N/A"
		lblLastIntegratedTime.text = "At: " + integration.format_last_integrated_datetime()
	else:
		title = "Invalid Integration"
		leIntegrationName.text = "Invalid Integration"

func _refresh_targets_list() -> void:
	ilTargets.clear()
	var target_display: Array[String] = integration.format_targets()
	for target_str in target_display:
		ilTargets.add_item(target_str)

func _enabled_toggled(pressed: bool) -> void:
	integration.enabled = pressed
	if integration.enabled:
		#btnEnable.icon = enable_integration_icon
		btnEnable.tooltip_text = "Disable Integration"
		glog._success("Integration '%s' %s." % [integration.name, "enabled"])
	else:
		btnEnable.icon = dark_enabled_integration_icon
		btnEnable.tooltip_text = "Enable Integration"
		glog._warn("Integration '%s' %s." % [integration.name, "disabled"])

func _cancel_delete() -> void:
	awaiting_delete_confirmation = false
	btnDelete.icon = delete_integration_icon
	btnDelete.tooltip_text = "Delete Integration"

func await_delete_confirmation() -> void:
	awaiting_delete_confirmation = true
	btnDelete.icon = delete_integration_confirm_icon
	btnDelete.tooltip_text = "Click again to confirm deletion"
	awaiting_delete_timer.start()
	

func _show_delete_confirmation() -> void:
	if awaiting_run_completion:
		glog._warn("Please wait for the current integration run to complete before deleting.")
		return
	if awaiting_delete_confirmation:
		_delete_integration()
	else:
		await_delete_confirmation()
	

func _delete_integration() -> void:
	if awaiting_run_completion:
		glog._warn("Please wait for the current integration run to complete before deleting.")
		return
	glog._warn("Integration '%s' deleted." % integration.name)

func _run_integration() -> void:
	if awaiting_run_completion:
		glog._warn("Cancelling current integration run.")
		awaiting_run_completion = false
		## TODO: Trigger cleanup somehow? bail out? will have to figure out signals maybe
		return
	if not integration.enabled:
		glog._warn("Integration '%s' is disabled, cannot run." % integration.name)
		return
	
	awaiting_run_completion = true
	glog._success("Integration '%s' Started." % integration.name)


func _on_btn_add_target_pressed() -> void:
	if leRepoTarget.text == "" or leProjectTarget.text == "":
		glog._warn("Both Repo Target and Project Target must be specified to add a new target.")
		return
	integration.add_target(leRepoTarget.text, leProjectTarget.text)
	_refresh_targets_list()
	leRepoTarget.text = ""
	leProjectTarget.text = ""


func _on_btn_remove_target_pressed() -> void:
	for idx in targets_selected:
		var target_str: String = ilTargets.get_item_text(idx)
		var repo: String = target_str.split(" -> ")[0].replace("repo::", "")
		integration.remove_target(repo)
	_refresh_targets_list()
	targets_selected.clear()
