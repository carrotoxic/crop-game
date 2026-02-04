extends PanelContainer

const TOOLTIP_DELAY := 0.25
const MINI_CELL := 14

var _controller: GameController
var _card_buttons: Array[Button] = []
var _selected_id: String = ""
var _tooltip: PopupPanel
var _tooltip_timer: float = -1.0
var _hovered_btn: Button = null

func _ready() -> void:
	add_theme_stylebox_override("panel", GameTheme.style_hud_panel())
	_controller = get_tree().get_first_node_in_group("game_controller")
	if not _controller:
		return
	_controller.state_changed.connect(_on_state_changed)
	_build_tooltip()
	_build_cards()

func _process(delta: float) -> void:
	if _tooltip_timer >= 0:
		_tooltip_timer -= delta
		if _tooltip_timer < 0 and _hovered_btn:
			_show_tooltip_for(_hovered_btn)

func _build_tooltip() -> void:
	_tooltip = PopupPanel.new()
	_tooltip.add_theme_stylebox_override("panel", GameTheme.style_hud_panel())
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 8)
	var desc_label := Label.new()
	desc_label.name = "Desc"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_font_override("font", load("res://art/pixel_operator/PixelOperatorHB.ttf"))
	desc_label.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(desc_label)
	var grid_holder := GridContainer.new()
	grid_holder.name = "Grid"
	grid_holder.columns = 5
	for j in 5:
		for i in 5:
			var r := ColorRect.new()
			r.custom_minimum_size = Vector2(MINI_CELL, MINI_CELL)
			r.name = "c_%d_%d" % [i, j]
			grid_holder.add_child(r)
	vbox.add_child(grid_holder)
	margin.add_child(vbox)
	_tooltip.add_child(margin)
	add_child(_tooltip)

func _build_cards() -> void:
	var root := get_node_or_null("Margin") if has_node("Margin") else self
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	center.add_child(h)
	root.add_child(center)
	var group := ButtonGroup.new()
	for def in _controller.registry.get_all_defs():
		var btn := Button.new()
		btn.button_group = group
		btn.custom_minimum_size = Vector2(152, 80)
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_font_override("font", load("res://art/pixel_operator/PixelOperatorHB.ttf"))
		btn.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
		btn.add_theme_color_override("font_disabled_color", GameTheme.TEXT_MUTED)
		btn.set_meta("crop_id", def.id)
		btn.gui_input.connect(_on_card_gui_input.bind(def.id))
		btn.pressed.connect(_on_card_pressed.bind(def.id))
		btn.mouse_entered.connect(_on_card_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_card_mouse_exited.bind(btn))
		_update_card(btn, def, _controller.state)
		h.add_child(btn)
		_card_buttons.append(btn)

func _on_card_mouse_entered(btn: Button) -> void:
	_hovered_btn = btn
	_tooltip_timer = TOOLTIP_DELAY

func _on_card_mouse_exited(btn: Button) -> void:
	if _hovered_btn == btn:
		_hovered_btn = null
	_tooltip_timer = -1.0
	_tooltip.hide()

func _show_tooltip_for(btn: Button) -> void:
	var crop_id: String = btn.get_meta("crop_id")
	var margin_node: MarginContainer = _tooltip.get_child(0)
	var vbox_node: VBoxContainer = margin_node.get_child(0)
	var desc: Label = vbox_node.get_node("Desc")
	var grid_holder: GridContainer = vbox_node.get_node("Grid")
	desc.text = CropAbilityInfo.get_ability_text(crop_id)
	var cells: Array[Vector2i] = CropAbilityInfo.get_effect_cells(crop_id)
	var center_color := Color(0.6, 0.85, 0.6)
	var range_color := Color(0.75, 0.9, 0.75)
	var pumpkin_range_color: Color = GameTheme.NON_PLANTABLE  # soft red: doesn't want other plants in 1 range
	for j in 5:
		for i in 5:
			var idx: int = j * 5 + i
			var r := grid_holder.get_child(idx) as ColorRect
			var p := Vector2i(i, j)
			var in_range: bool = p in cells
			var is_center: bool = p == Vector2i(2, 2)
			if in_range and is_center:
				r.color = center_color
			elif in_range and crop_id == "pumpkin":
				r.color = pumpkin_range_color
			elif in_range:
				r.color = range_color
			else:
				r.color = GameTheme.SOIL_NORMAL
				r.color.a = 0.35
	var content: Control = _tooltip.get_child(0)
	var min_sz: Vector2 = content.get_combined_minimum_size()
	_tooltip.set_size(min_sz)
	var rect: Rect2 = btn.get_global_rect()
	var pos: Vector2i = Vector2i(int(rect.position.x), int(rect.position.y - min_sz.y - 4))
	var size_i: Vector2i = Vector2i(int(min_sz.x), int(min_sz.y))
	_tooltip.popup(Rect2i(pos, size_i))

func _on_card_gui_input(event: InputEvent, crop_id: String) -> void:
	# Select on mouse down so the choice registers even if release happens outside the card.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_select_card(crop_id)

func _on_card_pressed(crop_id: String) -> void:
	_select_card(crop_id)

func _select_card(crop_id: String) -> void:
	_selected_id = crop_id
	var state: GameState = _controller.state
	for btn in _card_buttons:
		var def = _controller.registry.get_def(btn.get_meta("crop_id"))
		if def:
			_update_card(btn, def, state)
	for btn in _card_buttons:
		btn.set_pressed_no_signal(String(btn.get_meta("crop_id")) == crop_id)
	var grid = get_tree().get_first_node_in_group("grid_view")
	if grid and grid.has_method("set_selected_crop"):
		grid.set_selected_crop(crop_id)
	Global.last_crop = crop_id
	_controller.update_plantable()
	

func _on_state_changed(state: GameState) -> void:
	for btn in _card_buttons:
		var def = _controller.registry.get_def(btn.get_meta("crop_id"))
		if def:
			_update_card(btn, def, state)
	# Re-sync ButtonGroup from _selected_id so selection never gets lost
	for btn in _card_buttons:
		btn.set_pressed_no_signal(String(btn.get_meta("crop_id")) == _selected_id)

func _update_card(btn: Button, def: CropDef, state: GameState) -> void:
	var blocked: bool = _controller.game_ended or _controller.stage_clear_showing
	var cost_ok := state and state.money >= def.cost
	var is_selected: bool = String(btn.get_meta("crop_id")) == _selected_id
	btn.text = "%s\nCost: %d  Sells: %d  Grows: %d" % [def.display_name, def.cost, def.base_price, def.grow_time]
	# Only disable when blocked (game over / popup). Keep cards clickable so selection always registers.
	btn.disabled = blocked
	var style_normal: StyleBoxFlat
	var style_hover_pressed: StyleBoxFlat
	var style_disabled: StyleBoxFlat
	if is_selected and cost_ok:
		style_normal = GameTheme.style_card_selected_bright()
		style_hover_pressed = GameTheme.style_card_selected_bright()
		style_disabled = GameTheme.style_card_selected_bright()
	elif cost_ok:
		style_normal = GameTheme.style_card_normal()
		style_hover_pressed = GameTheme.style_card_selected()
		style_disabled = GameTheme.style_card_disabled()
	else:
		style_normal = GameTheme.style_card_cannot_afford()
		style_hover_pressed = GameTheme.style_card_cannot_afford()
		style_disabled = GameTheme.style_card_cannot_afford()
	# Force all font colors so text is never white in any state (normal/hover/pressed/disabled)
	var text_color: Color = GameTheme.TEXT_DARK if ((is_selected and cost_ok) or not cost_ok) else GameTheme.TEXT_MUTED
	btn.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_focus_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color)
	# Hover and pressed use the same style so the card stays highlighted during click (no flip to pale).
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover_pressed)
	btn.add_theme_stylebox_override("pressed", style_hover_pressed)
	btn.add_theme_stylebox_override("focus", style_hover_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
