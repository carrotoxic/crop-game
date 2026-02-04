class_name GameTheme
extends RefCounted

# Clean farm/soil palette
const BG_COLOR := Color("#FAF8F5")
const SOIL_NORMAL := Color("#C4A574")
const SOIL_BORDER := Color("#A68B5B")
const SOIL_HOVER := Color("#D4B896")
const CARD_BG := Color("#EDE9E2")
const CARD_BORDER := Color("#D4CFC4")
const CARD_SELECTED := Color("#B8D4A8")
const CARD_DISABLED := Color("#E5E1DA")
const CARD_CANNOT_AFFORD := Color(0.95, 0.75, 0.75)
const TEXT_DARK := Color("#2C2419")
const TEXT_MUTED := Color("#5C5348")
const HUD_PANEL := Color("#F0EDE8")
const PROGRESS_FILL := Color("#8FBC8F")
const PROGRESS_BG := Color("#E0DDD6")
const PEST_WARN := Color("#C45C4A")
const NON_PLANTABLE := Color(0.9, 0.6, 0.6)
const HARVESTABLE := Color(0.6, 0.85, 0.6)
const CARD_SELECTED_BORDER := Color(0.2, 0.6, 0.3)

static func make_stylebox_flat(bg: Color, border: Color, corner: int = 4, border_width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(corner)
	return s

static func style_grid_cell() -> StyleBoxFlat:
	return make_stylebox_flat(SOIL_NORMAL, SOIL_BORDER, 2)

static func style_card_normal() -> StyleBoxFlat:
	return make_stylebox_flat(CARD_BG, CARD_BORDER, 6)

static func style_card_selected() -> StyleBoxFlat:
	return make_stylebox_flat(CARD_SELECTED, SOIL_BORDER, 6)

static func style_card_selected_bright() -> StyleBoxFlat:
	return make_stylebox_flat(CARD_SELECTED, CARD_SELECTED_BORDER, 6, 3)

static func style_grid_cell_non_plantable() -> StyleBoxFlat:
	return make_stylebox_flat(NON_PLANTABLE, SOIL_BORDER, 2)

static func style_grid_cell_harvestable() -> StyleBoxFlat:
	return make_stylebox_flat(HARVESTABLE, CARD_SELECTED_BORDER, 2, 2)

static func style_card_disabled() -> StyleBoxFlat:
	return make_stylebox_flat(CARD_DISABLED, CARD_BORDER, 6)

static func style_card_cannot_afford() -> StyleBoxFlat:
	return make_stylebox_flat(CARD_CANNOT_AFFORD, CARD_BORDER, 6)

static func style_hud_panel() -> StyleBoxFlat:
	return make_stylebox_flat(HUD_PANEL, CARD_BORDER, 4)
