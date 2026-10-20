## Every known portal adapter and the startup choice between them. A new portal is one line in `_all`.
class_name PlatformCatalog
extends RefCounted

const DEFAULT_ID := &"null"
const FEATURE_PREFIX := "platform_"

static var _all: Dictionary = {
	&"null": NullAdapter,
}

static func ids() -> Array:
	return _all.keys()

static func create(id: StringName) -> PlatformAdapter:
	var adapter_class: Variant = _all.get(id, _all[DEFAULT_ID])
	return adapter_class.new() as PlatformAdapter

## A custom export feature tag `platform_<id>` picks the adapter, else the null adapter.
static func detect() -> StringName:
	for id: StringName in _all:
		if OS.has_feature(FEATURE_PREFIX + String(id)):
			return id
	return DEFAULT_ID
