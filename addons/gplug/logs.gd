@tool
extends Resource
class_name glog

const indent_step: int = 4

static func gen_indent() -> String:
  return "└" + "-".repeat(max(1, (indent_step - 1)))

static func _print(message: String) -> void:
  print_rich("[GPlug]::%s" % message)

static func _format(str: String, color: Color) -> String:
  var hex_color: String = color.to_html(false)
  return "[color=%s]%s[/color]" % [hex_color, str]

static func _error(message: String) -> void:
  _print(_format("[Erro] %s" % message, Color.RED))

static func _ierror(message: String) -> void:
  _error("%s%s" % [gen_indent(), message])

static func _info(message: String) -> void:
  _print(_format("[Info] %s" % message, Color.CYAN))

static func _iinfo(message: String) -> void:
  _info("%s%s" % [gen_indent(), message])

static func _success(message: String) -> void:
  _print(_format("[Plug] %s" % message, Color.GREEN))

static func _isuccess(message: String) -> void:
  _success("%s%s" % [gen_indent(), message])

static func _warn(message: String) -> void:
  _print(_format("[Warn] %s" % message, Color.ORANGE))

static func _iwarn(message: String) -> void:
  _warn("%s%s" % [gen_indent(), message])

static func _debug(message: String) -> void:
  if ProjectSettings.get_setting("gplug/enable_debug_logging", false):
    _print(_format("[Debug] %s" % message, Color.YELLOW))

static func _idebug(message: String) -> void:
  _debug("%s%s" % [gen_indent(), message])