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
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	vbox.add_child(title)
	var rules: Array[String] = [
		"• 8×8 grid. Each turn, you may plant one crop on an empty cell. Fully grown crops (green) can be harvested; money is calculated on harvest. End the turn afterward.",
		"• The game has 5 stages, each lasting 10 turns. You must meet the money requirement by the end of each stage or the game ends.",
		"• Starting on turn 3, one pest appears per turn (shown one turn in advance). Pests block growth; if untreated for 3 turns, the crop is destroyed.",
		"• You cannot plant the same crop on a cell consecutively. Plant a different crop on that cell before planting the original again.",
	]
	for r in rules:
		var lbl := Label.new()
		lbl.text = r
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(228, 0)
		vbox.add_child(lbl)
	scroll.add_child(vbox)
	margin.add_child(scroll)
	add_child(margin)
