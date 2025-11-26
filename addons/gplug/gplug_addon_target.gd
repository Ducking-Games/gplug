@tool

class_name GPlugIntegrationTarget extends Resource

var targets: Dictionary[String, String]

## Add a target repo directory to be injected at the target project location
func add_target(repo: String, project: String) -> void:
	if targets.has(repo):
		glog._warn("Target for repo '%s' already exists, overwriting." % repo)
	targets[repo] = project

func to_dict() -> Dictionary:
	var data: Dictionary = {
	"targets": targets
	}
	return data

func to_display() -> Array[String]:
	var display: Array[String] = []
	for repo in targets.keys():
		var project: String = targets[repo]
		display.append("repo::%s -> project::%s" % [repo, project])
	return display

static func from_dict(data: Dictionary) -> GPlugIntegrationTarget:
	var target: GPlugIntegrationTarget = GPlugIntegrationTarget.new()
	target.targets = data.get("targets", {})
	return target
