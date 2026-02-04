extends PanelContainer

func _ready() -> void:
	add_theme_stylebox_override("panel", GameTheme.style_hud_panel())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(200, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Rules"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	vbox.add_child(title)
	var rules: Array[String] = [
		"• 8×8 grid. Each turn: optionally plant one crop (click card, then empty cell). Grown crops (green) can be harvested by clicking; price is calculated when you harvest. Then End Turn.",
		"• 4 stages, 10 turns each. Meet the money requirement by end of stage or Game Over.",
		"• From turn 3: one pest per turn (shown 1 turn ahead). Pest blocks growth; 3 rounds untreated = crop destroyed. Chili is immune.",
		"• You cannot plant the same crop on the cell where you last planted that crop. Plant a different crop there first to be able to plant the original again.",
		"• Pumpkin: Grows 1 turn faster if no crops within 1 tile when planted.",
		"• Chili: Immune to pests. On plant, removes pests in 2-tile radius.",
		"• Money Plant: 10% chance each turn to self-destruct (no payout).",
		"• Strawberry: Sell price +1 per connected Strawberry (N/E/S/W).",
		"• Sunflower: Sell price +1 per plant on its 4 diagonal lines.",
	]
	for r in rules:
		var lbl := Label.new()
		lbl.text = r
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(180, 0)
		vbox.add_child(lbl)
	scroll.add_child(vbox)
	margin.add_child(scroll)
	add_child(margin)
