@tool
extends Resource
class_name glog

static func _info(message: String) -> void:
  print_rich("[godotons] [color=cyan]%s[/color]" % message)

static func _iinfo(message: String) -> void:
  _info("    %s" % message)