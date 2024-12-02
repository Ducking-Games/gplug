@tool
extends Resource
class_name GplugAddon

class AddonTarget extends Resource:
  var TargetPairs: Dictionary

  func add_target(repo: String, project: String) -> void:
    assert(not TargetPairs.has(repo))
    TargetPairs[repo] = project

## Optional name for the addon (only used in gplug)
var Name: String

## Whether this addon should be installed or not
var Enabled: bool

## Whether this addon should automatically be updated or not
var Update: bool

## Which upstream origin service the repo is hosted on (github/gitlab)
var Origin: GitGet.ORIGINS

## Remote repository of the addon
var Repo: String

## Target branch for the addon
var Branch: String

## Target remote directories to integrate into target local directories
var Targets: AddonTarget

## The hash of the last commit integrated
var LastIntegratedHash: String