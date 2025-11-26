@tool

class_name GPlugAddonTarget extends Resource

var targets: Dictionary[String, String]

## Add a target repo directory to be injected at the target project location
func add_target(repo: String, project: String) -> void:
  assert(not targets.has(repo), "Target already exists for repo: %s" % repo)
  targets[repo] = project

func pack() -> Dictionary:
  var data: Dictionary = {
    "targets": targets
  }
  return data