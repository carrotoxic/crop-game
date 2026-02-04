class_name CropRegistry
extends RefCounted

const CROP_PATHS := {
	"pumpkin": "res://data/crops/pumpkin.tres",
	"chili": "res://data/crops/chili.tres",
	"rose": "res://data/crops/rose.tres",
	"strawberry": "res://data/crops/strawberry.tres",
	"sunflower": "res://data/crops/sunflower.tres"
}

var _defs: Dictionary = {}  # id -> CropDef

func _init() -> void:
	for id in CROP_PATHS:
		var res = load(CROP_PATHS[id]) as CropDef
		if res:
			_defs[id] = res

func get_def(id: String) -> CropDef:
	return _defs.get(id)

func get_all_ids() -> Array:
	return CROP_PATHS.keys()

func get_all_defs() -> Array:
	var a: Array = []
	for id in get_all_ids():
		var d = get_def(id)
		if d:
			a.append(d)
	return a
