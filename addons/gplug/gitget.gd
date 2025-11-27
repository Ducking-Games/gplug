@tool
extends Node
class_name GitGet

enum ORIGINS {
  GITHUB = 0,
  GITLAB
}

const origins: Array[Dictionary] = [
  {
    "name": "github",
    "base_url": "github.com",
    "api_url": "api.github.com",
    "type": ORIGINS.GITHUB,
    "supported": true,
    "icon": "github_icon",
  },
  {
    "name": "gitlab",
    "base_url": "gitlab.com",
    "api_url": "gitlab.com/api/v4",
    "type": ORIGINS.GITLAB,
    "supported": false,
    "icon": "gitlab_icon",
  }
]

static func origin_icons() -> Dictionary[String, Texture2D]:
  var github_icon: Texture2D = preload("uid://ba2s1sl1sk3jn")
  var gitlab_icon: Texture2D = preload("uid://hmreu8yge1jq")
  return {
    "github_icon": github_icon,
    "gitlab_icon": gitlab_icon,
  }



static func OriginName(idx: ORIGINS) -> String:
  for origin in origins:
    if origin["type"] == idx:
      return origin["name"]
  return "unknown"

static func OriginIndex(name: String) -> ORIGINS:
  for origin in origins:
    if origin["name"] == name:
      return origin["type"]
  return -1

static func OriginHashURL(addon: GPlugIntegration) -> String:
  match addon.origin:
    ORIGINS.GITHUB:
      return "https://%s/repos/%s/%s/commits/%s" % [origins[0]["api_url"], addon.owner(), addon.repository(), addon.branch]
    _:
      return ""

static func DownloadURL(addon: GPlugIntegration) -> String:
  match addon.origin:
    ORIGINS.GITHUB:
      return "https://%s/%s/%s/archive/%s.zip" % [origins[0]["base_url"], addon.owner(), addon.repository(), addon.branch]
    _:
      return ""

## get the commit hash of repo:branch, check if hash.zip exists in tmp_dir, if not download it
func get_commit_hash(addon: GPlugIntegration, token: String = "") -> String:
  match addon.origin:
    ORIGINS.GITHUB:
      var hash: String = await _github_commit_hash(addon, token)
      return hash
    _:
      glog._error("Origin %s not supported for getting commit hash." % OriginName(addon.origin))
      return ""

## get the commit hash of repo:branch from GitHub API
func _github_commit_hash(addon: GPlugIntegration, token: String = "") -> String:
  var url: String = OriginHashURL(addon)

  var headers: PackedStringArray = []
  if token != "":
    headers.append("Authorization: token %s" % token)
  var header_accept: String = "Accept: application/vnd.github.VERSION.sha"
  headers.append(header_accept)

  var http_request: HTTPRequest = HTTPRequest.new()
  add_child(http_request)

  var error: Error = http_request.request(url, headers)
  if error != OK:
    glog._ierror("Failed to make HTTP request to %s" % url)
    return ""

  var resp: Array = await http_request.request_completed
  var result: int = resp[0]
  var response_code: int = resp[1]
  var response_headers: PackedStringArray = resp[2]
  var response_body: PackedByteArray = resp[3]

  if result != OK or response_code != 200:
    glog._ierror("HTTP request to %s failed with code %d" % [url, response_code])
    return ""
  
  var body_str: String = response_body.get_string_from_utf8()
  return body_str.strip_edges()

## download the addon zip from the given addon download URL
func get_archive(addon: GPlugIntegration, token: String = "") -> PackedByteArray:
  match addon.origin:
    ORIGINS.GITHUB:
      var archive: PackedByteArray = await _github_get_archive(addon, token)
      return archive
    _:
      glog._ierror("Origin %s not supported for downloading archive." % OriginName(addon.origin))
      return PackedByteArray()
  
func _github_get_archive(addon: GPlugIntegration, token: String = "") -> PackedByteArray:
  var url: String = DownloadURL(addon)

  var headers: PackedStringArray = []
  if token != "":
    headers.append("Authorization: token %s" % token)

  var http_request: HTTPRequest = HTTPRequest.new()
  add_child(http_request)

  var error: Error = http_request.request(url, headers)
  if error != OK:
    glog._ierror("Failed to make HTTP request to %s" % url)
    return PackedByteArray()

  glog._iinfo("Downloading archive from %s..." % url)
  var resp: Array = await http_request.request_completed
  var result: int = resp[0]
  var response_code: int = resp[1]
  var response_headers: PackedStringArray = resp[2]
  var response_body: PackedByteArray = resp[3]

  if result != OK or response_code != 200:
    glog._ierror("HTTP request to %s failed with code %d" % [url, response_code])
    return PackedByteArray()

  return response_body

