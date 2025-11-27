@tool
class_name GPlugIntegration extends Resource

signal integration_changed()

## Name for this integration
var name: String = "New Integration":
	set(value):
		name = value
		integration_changed.emit()

## Whether or not this integration is enabled
var enabled: bool = false:
	set(value):
		enabled = value
		integration_changed.emit()

## Whether or not this integration is paused and should retain its current version
var paused: bool:
	set(value):
		paused = value
		integration_changed.emit()

## Which upstream origin service the repo is hosted on (github/gitlab)
var origin: GitGet.ORIGINS = GitGet.ORIGINS.GITHUB:
	set(value):
		origin = value
		integration_changed.emit()

## Remote repository of the addon
var repo: String = "":
	set(value):
		repo = value
		integration_changed.emit()

## Target branch for the addon
var branch: String = "main":
	set(value):
		branch = value
		integration_changed.emit()

## Target remote directories to integrate into target local directories
var targets: Dictionary[String, String] = {}:
	set(value):
		targets = value
		integration_changed.emit()

## The hash of the last commit integrated
var last_integrated_hash: String = "":
	set(value):
		last_integrated_hash = value
		integration_changed.emit()

## The timestamp of the last integration
var last_integrated_time_dict: Dictionary = {}:
	set(value):
		last_integrated_time_dict = value
		integration_changed.emit()

## user-driven notes about this integration
var notes: String = "":
	set(value):
		notes = value
		integration_changed.emit()

func add_target(remote_path: String, local_path: String) -> void:
	targets[remote_path] = local_path
	integration_changed.emit()

func remove_target(remote_path: String) -> void:
	if targets.has(remote_path):
		targets.erase(remote_path)
		integration_changed.emit()
	else:
		glog._warn("Target for repo '%s' does not exist, cannot remove." % remote_path)

func format_targets() -> Array[String]:
	var display: Array[String] = []
	for remote_path in targets.keys():
		var local_path: String = targets[remote_path]
		display.append("%s -> %s" % [remote_path, local_path])
	return display
func owner() -> String:
	var repo_split: PackedStringArray = repo.split("/")
	return repo_split[0]

func repository() -> String:
	var repo_split: PackedStringArray = repo.split("/")
	return repo_split[1]

func to_dict() -> Dictionary:
	var data: Dictionary = {
		"name": name,
		"enabled": enabled,
		"paused": paused,
		"origin": origin,
		"repo": repo,
		"branch": branch,
		"targets": targets,
		"last_integrated_hash": last_integrated_hash,
		"last_integrated_time_dict": last_integrated_time_dict
	}
	return data

func to_config(conf: ConfigFile) -> void:
	conf.set_value(name, "enabled", enabled)
	conf.set_value(name, "paused", paused)
	conf.set_value(name, "origin", origin)
	conf.set_value(name, "repo", repo)
	conf.set_value(name, "branch", branch)
	conf.set_value(name, "targets", targets)
	conf.set_value(name, "last_integrated_hash", last_integrated_hash)
	conf.set_value(name, "last_integrated_time_dict", last_integrated_time_dict)

static func from_dict(data: Dictionary) -> GPlugIntegration:
	var integration: GPlugIntegration = GPlugIntegration.new()
	integration.name = data.get("name", "")
	integration.enabled = data.get("enabled", false)
	integration.paused = data.get("paused", false)
	integration.origin = data.get("origin", GitGet.ORIGINS.GITHUB)
	integration.repo = data.get("repo", "")
	integration.branch = data.get("branch", "main")
	integration.targets = data.get("targets", {})
	integration.last_integrated_hash = data.get("last_integrated_hash", "")
	integration.last_integrated_time_dict = data.get("last_integrated_time_dict", {})
	return integration

## format the timestamp of the last integration into a human-readable string
func format_last_integrated_datetime() -> String:

	if not last_integrated_time_dict:
		return "Never"
	var year: int = last_integrated_time_dict.get("year", 0)
	var month: int = last_integrated_time_dict.get("month", 0)
	var day: int = last_integrated_time_dict.get("day", 0)
	var hour: int = last_integrated_time_dict.get("hour", 0)
	var minute: int = last_integrated_time_dict.get("minute", 0)
	var second: int = last_integrated_time_dict.get("second", 0)
	if year == 0 or month == 0 or day == 0:
		return "Never"
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		year, month, day, hour, minute, second
	]
