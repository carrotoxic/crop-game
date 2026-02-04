@tool
class_name CropDef
extends Resource

enum Type { PUMPKIN, CHILI, MONEY_PLANT, STRAWBERRY, SUNFLOWER }

@export var id: String = ""
@export var display_name: String = ""
@export var cost: int = 0
@export var base_price: int = 0
@export var grow_time: int = 3
@export var type_enum: Type = Type.PUMPKIN
@export var pumpkin_isolation_radius: int = 1
@export var chili_clean_radius: int = 2
