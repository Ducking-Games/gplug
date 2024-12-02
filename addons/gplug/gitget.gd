@tool
extends Node
class_name GitGet

enum ORIGINS {GITHUB = 0, GITLAB}

static func OriginName(idx: int) -> String:
  var names: Array[String] = [
    "github",
    "gitlab"
  ]
  return names[idx]

class GitSource extends Node:
  var index: ORIGINS
  var source_name: String
  var base_url: String
  var api_url: String

  func _init(idx: ORIGINS, base: String, api: String) -> void:
    index = idx
    source_name = GitGet.OriginName(idx)
    base_url = base
    api_url = api
