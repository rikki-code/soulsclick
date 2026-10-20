## The realms of a run in order. Adding a realm = a .tres in data/realms/ plus one path here.
class_name RealmCatalog
extends RefCounted

const PATHS: Array[String] = [
	"res://data/realms/realm_1.tres",
	"res://data/realms/realm_2.tres",
	"res://data/realms/realm_3.tres",
	"res://data/realms/realm_4.tres",
]

static func default_realms() -> Array[RealmDefinition]:
	var realms: Array[RealmDefinition] = []
	for path in PATHS:
		realms.append(load(path) as RealmDefinition)
	return realms
