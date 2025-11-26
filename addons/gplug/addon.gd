@tool
extends Resource
class_name GPlugAddon

## Optional name for the addon (only used in gplug)
var name: String

## Whether this addon should be installed or not
var enabled: bool

## Whether this addon should automatically be updated or not
var update: bool

## Which upstream origin service the repo is hosted on (github/gitlab)
var origin: GitGet.ORIGINS

## Remote repository of the addon
var repo: String

## Target branch for the addon
var branch: String

## Target remote directories to integrate into target local directories
var targets: GPlugAddonTarget

## The hash of the last commit integrated
var last_integrated_hash: String

## The timestamp of the last integration
var last_integrated_time_dict: Dictionary


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

## pack the addon data into a dictionary for serialization
func pack() -> Dictionary:
  var data: Dictionary = {
    "name": name,
    "enabled": enabled,
    "update": update,
    "origin": origin,
    "repo": repo,
    "branch": branch,
    "targets": targets.pack(),
    "last_integrated_hash": last_integrated_hash,
    "last_integrated_time_dict": last_integrated_time_dict
  }
  return data