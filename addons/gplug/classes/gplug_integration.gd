@tool
class_name GPlugIntegration extends Resource

## Name for this integration
var name: String = "New Integration"

## Whether or not this integration is enabled
var enabled: bool = false

## Whether or not this integration is paused and should retain its current version
var paused: bool

## Which upstream origin service the repo is hosted on (github/gitlab)
var origin: GitGet.ORIGINS = GitGet.ORIGINS.GITHUB

## Remote repository of the addon
var repo: String

## Target branch for the addon
var branch: String = "main"

## Target remote directories to integrate into target local directories
var targets: GPlugIntegrationTarget = GPlugIntegrationTarget.new()

## The hash of the last commit integrated
var last_integrated_hash: String

## The timestamp of the last integration
var last_integrated_time_dict: Dictionary

## user-driven notes about this integration
var notes: String = ""

func validate() -> bool:
    if name == "":
        return false

    if repo == "":
        return false
    var repo_split: Array[String] = repo.split("/")
    if repo_split.size() != 2:
        return false
    if len(repo_split[0]) == 0 or len(repo_split[1]) == 0:
        return false

    if not targets or targets.targets.size() == 0:
        return false

    return true

func owner() -> String:
    var repo_split: Array[String] = repo.split("/")
    return repo_split[0]

func repository() -> String:
    var repo_split: Array[String] = repo.split("/")
    return repo_split[1]

func to_dict() -> Dictionary:
    var data: Dictionary = {
        "name": name,
        "enabled": enabled,
        "paused": paused,
        "origin": origin,
        "repo": repo,
        "branch": branch,
        "targets": targets.pack(),
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
    conf.set_value(name, "targets", targets.to_dict())
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
    integration.targets = GPlugIntegrationTarget.from_dict(data.get("targets", {}))
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