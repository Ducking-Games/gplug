@tool
class_name GPlugIntegrationDisplay extends PanelContainer

signal toggle_enabled(pressed: bool)
signal run_integration(ignore_enabled: bool)
signal delete_integration(integration: GPlugIntegration)

@export var integration: GPlugIntegration
@export var busy: bool = false

@export_group("Display Elements")
@export var lblTitle: Label
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
@export var btnAddTarget: Button
@export var btnRemoveTarget: Button
@export var btnEnable: Button
@export var btnDelete: Button
@export var btnRun: Button

@export_group("Icons")
@export var delete_integration_icon: Texture2D
@export var delete_integration_confirm_icon: Texture2D
@export var run_integration_icon: Texture2D
@export var run_integration_busy_icon: Texture2D
@export var enabled_integration_icon: Texture2D
@export var disabled_integration_icon: Texture2D

var awaiting_delete_confirmation: bool = false
var awaiting_delete_timer: Timer

var targets_selected: Array[int] = []

func _init() -> void:
	toggle_enabled.connect(_handle_enabled_toggle)
	run_integration.connect(_handle_run)

func _ready() -> void:
	refresh_display()
	_build_signals()
	awaiting_delete_timer = Timer.new()
	awaiting_delete_timer.wait_time = 3.0
	awaiting_delete_timer.one_shot = true
	awaiting_delete_timer.timeout.connect(_cancel_delete_wait)
	add_child(awaiting_delete_timer)

func _enter_tree() -> void:
	for origin in GitGet.origins:
		obOrigin.add_item(origin["name"])
		obOrigin.set_item_icon(obOrigin.get_item_count() - 1, GitGet.origin_icons().get(origin["icon"]))
		obOrigin.set_item_disabled((obOrigin.get_item_count() - 1), not origin["supported"])


## set up the signal connections
func _build_signals() -> void:
	## add target
	btnAddTarget.pressed.connect(_add_target)
	## remove target
	btnRemoveTarget.pressed.connect(_remove_selected_targets)

	btnEnable.toggled.connect(toggle_enabled.emit)
	btnRun.pressed.connect(run_integration.emit.bind(true))
	btnDelete.pressed.connect(_handle_delete)


	## integration name change
	leIntegrationName.text_changed.connect(func(new_text: String):
		integration.name = new_text
		lblTitle.text = new_text
	)
	## origin change
	obOrigin.item_selected.connect(func(idx: int):
		integration.origin = GitGet.OriginIndex(obOrigin.get_item_text(idx))
	)
	## repository change
	leRepository.text_changed.connect(func(new_text: String):
		integration.repo = new_text
	)
	## branch change
	leBranch.text_changed.connect(func(new_text: String):
		integration.branch = new_text
	)
	## notes change
	teNotes.text_changed.connect(func():
		integration.notes = teNotes.text
	)

	## target selection
	ilTargets.item_selected.connect(func(idx: int):
		targets_selected.append(idx)
	)
	## target deselection
	ilTargets.empty_clicked.connect(func(_at: Vector2, _btn_index: int):
		targets_selected.clear()
		ilTargets.deselect_all()
	)


## Refresh the UI from the integration data
func refresh_display() -> void:
	if integration:
		lblTitle.text = integration.name
		leIntegrationName.text = integration.name
		obOrigin.selected = int(integration.origin)
		leRepository.text = integration.repo
		leBranch.text = integration.branch
		teNotes.text = integration.notes
		lblLastIntegratedHash.text = integration.format_last_integration_hash()
		lblLastIntegratedTime.text = integration.format_last_integrated_datetime()
		_refresh_targets()
		_handle_enabled_toggle(integration.enabled)
	else:
		lblTitle.text = "Invalid Integration"
		leIntegrationName.text = "Invalid Integration"

## refresh the targets list
func _refresh_targets() -> void:
	ilTargets.clear()
	var targets: Array[String] = integration.format_targets()
	for target in targets:
		ilTargets.add_item(target)

## add a new target
func _add_target() -> void:
	if leRepoTarget.text == "" or leProjectTarget.text == "":
		glog._warn("Repo or Project target is empty, cannot add empty target. Use '.' to denote root.")
		return
	integration.add_target(leRepoTarget.text, leProjectTarget.text)
	_refresh_targets()
	leRepoTarget.text = ""
	leProjectTarget.text = ""

## remove selected targets
func _remove_selected_targets() -> void:
	for idx in targets_selected:
		var target_text: String = ilTargets.get_item_text(idx)
		var repo: String = target_text.split(" -> ")[0].replace("repo::", "")
		integration.remove_target(repo)
	_refresh_targets()
	targets_selected.clear()
	ilTargets.deselect_all()

func _handle_run(ignore_enabled: bool) -> void:
	if not busy:
		glog._info("Running integration '%s'..." % integration.name)
		if integration.enabled or ignore_enabled:
			busy = true
			btnRun.icon = run_integration_busy_icon
			await _integrate()
			busy = false
			btnRun.icon = run_integration_icon
		else:
			glog._info("Integration '%s' is disabled, ignoring..." % integration.name)
	else:
		glog._warn("Cancelling current integration run for '%s'." % integration.name)
		busy = false
		btnRun.icon = run_integration_icon

func _handle_delete() -> void:
	if busy:
		glog._warn("Please wait for the current integration run to complete before deleting.")
		return
	if awaiting_delete_confirmation:
		_delete_integration()
	else:
		awaiting_delete_confirmation = true
		btnDelete.icon = delete_integration_confirm_icon
		btnDelete.tooltip_text = "Click again to confirm deletion"
		awaiting_delete_timer.start()

func _cancel_delete_wait() -> void:
	awaiting_delete_confirmation = false
	btnDelete.icon = delete_integration_icon
	btnDelete.tooltip_text = "Delete Integration"

func _delete_integration() -> void:
	_cancel_delete_wait()
	awaiting_delete_timer.stop()
	delete_integration.emit(integration)
	glog._warn("Integration '%s' deleted." % integration.name)

func _handle_enabled_toggle(pressed: bool) -> void:
	integration.enabled = pressed
	btnEnable.icon = enabled_integration_icon if integration.enabled else disabled_integration_icon
	btnEnable.tooltip_text = "Disable Integration" if integration.enabled else "Enable Integration"
	if integration.enabled:
		glog._success("Integration '%s' enabled." % integration.name)
	else:
		glog._warn("Integration '%s' disabled." % integration.name)

func _integrate() -> void:
	glog._iinfo("Integrating '%s'..." % integration.name)

	var git: GitGet = GitGet.new()
	add_child(git)

	var hash: String = await git.get_commit_hash(integration)
	if hash == "":
		glog._ierror("Failed to retrieve latest commit hash for integration '%s'." % integration.name)
		git.queue_free()
		return

	glog._isuccess("Latest commit hash for integration '%s' is %s." % [integration.name, hash])

	var archive: PackedByteArray = await git.get_archive(integration)
	if archive.size() == 0:
		glog._ierror("Failed to retrieve archive for integration '%s'." % integration.name)
		git.queue_free()
		return
	git.queue_free()

	var tmp_dir: DirAccess = DirAccess.create_temp(integration.name)
	if tmp_dir == null:
		glog._ierror("Failed to create temporary directory for integration '%s'." % integration.name)
		return

	var integration_holding: DirAccess = tmp_dir.create_temp(hash)

	if integration_holding == null:
		glog._ierror("Failed to create temporary integration directory for integration '%s'." % integration.name)
		return

	var archive_path: String = "%s/%s.zip" % [integration_holding.get_current_dir(), integration.name]

	var archive_file: FileAccess = FileAccess.open(archive_path, FileAccess.WRITE)
	if archive_file == null:
		glog._ierror("Failed to create archive file for integration '%s'." % integration.name)
			
		return
	archive_file.store_buffer(archive)
	archive_file.close()
	glog._isuccess("Downloaded archive for integration '%s'." % integration.name)

	glog._iinfo("Extracting archive for integration '%s'..." % integration.name)
	# extract the archive
	var zip_reader: ZIPReader = ZIPReader.new()
	var zip_err: Error = zip_reader.open(archive_path)
	if zip_err != OK:
		glog._ierror("Failed to open ZIP archive for integration '%s'." % integration.name)
		return

	var prefix: String = "%s-%s/" % [integration.repository(), integration.branch]

	for archived_file: String in zip_reader.get_files():
		var internal_name: String = archived_file.trim_prefix(prefix)
		#glog._iinfo("Processing archived file '%s' for integration '%s'..." % [internal_name, integration.name])
		# need to remove prefix like inkgd-godot4/
		if internal_name.trim_suffix("/") in integration.targets.keys():
			glog._iinfo("Extracting target '%s' for integration '%s'..." % [archived_file, integration.name])

	var zip_close: Error = await zip_reader.close()
	if zip_close != OK:
		glog._ierror("Failed to close ZIP archive for integration '%s'." % integration.name)
		return

	# copy repo target to project target

	# clean up

	glog._isuccess("Integration '%s' completed successfully." % integration.name)
	integration.last_integrated_hash = hash
	integration.last_integrated_time_dict = Time.get_datetime_dict_from_system()
