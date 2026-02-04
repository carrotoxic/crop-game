class_name CropInstance
extends RefCounted

var def_id: String = ""
var remaining_grow: int = 3
var has_pest: bool = false
var pest_rounds: int = 0

func _init(p_def_id: String = "", p_grow: int = 3) -> void:
	def_id = p_def_id
	remaining_grow = p_grow

func duplicate_crop() -> CropInstance:
	var c := CropInstance.new(def_id, remaining_grow)
	c.has_pest = has_pest
	c.pest_rounds = pest_rounds
	return c
