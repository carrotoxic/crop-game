extends PanelContainer

func _ready() -> void:
	add_theme_stylebox_override("panel", GameTheme.style_hud_panel())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Rules"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", load("res://art/pixel_operator/PixelOperatorHB.ttf"))
	title.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	vbox.add_child(title)
	var rules: Array[String] = [
		". Move the cursor around using WASD",
		". Select a seed using ENTER, then select a valid tile using ENTER. Press ESCAPE to return to seed selection.",
		"• 5×5 grid. Each turn: optionally plant one crop (click card, then empty cell). Grown crops (green) can be harvested by clicking; price is calculated when you harvest. Then End Turn.",
		"• 5 stages, 10 turns each. Meet the money requirement by end of stage or Game Over.",
		"• From turn 3: one pest per turn (shown 1 turn ahead). Pest blocks growth; 3 rounds untreated = crop destroyed.",
		"• You cannot plant the same crop on a cell where you last planted that crop. Plant a different crop there first to plant the original again.",
		"• When a plant has fully grown, hover over it and press ENTER to harvest it."
	]
	for r in rules:
		var lbl := Label.new()
		lbl.text = r
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_font_override("font", load("res://art/pixel_operator/PixelOperatorHB.ttf"))
		lbl.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(228, 0)
		vbox.add_child(lbl)
	scroll.add_child(vbox)
	margin.add_child(scroll)
	add_child(margin)
