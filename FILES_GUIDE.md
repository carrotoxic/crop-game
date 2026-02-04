# Project Files Guide

This document describes every important file in the game-2 Godot project: what it does, key variables/signals, and how it fits into the whole.

---

## Root

### `project.godot`
Godot project configuration.

- **config/name**: Application name ("game2").
- **run/main_scene**: Entry scene `res://scenes/main/Main.tscn`.
- **config/icon**: App icon path.
- **[display]**: Viewport 720×900; stretch mode `canvas_items`, aspect `expand` for responsive UI.
- **[physics]** / **[rendering]**: Engine defaults (e.g. Jolt, d3d12).

### `project.md`
Design specification: rules, turn order, crop abilities, UI layout, architecture, implementation phases. Reference for behavior and data, not executed by the game.

### `icon.svg`, `icon.svg.import`
Default project icon and its Godot import settings.

---

## `scripts/` — Logic (no scene nodes)

### `scripts/data/GameConfig.gd`
**Resource script** that defines global game parameters (all `@export` for the editor and `.tres`).

| Property | Type | Meaning |
|----------|------|---------|
| stage_requirements | Array[int] | Money needed at end of each stage (default [10, 25, 45, 70]). |
| board_size | Vector2i | Grid size (default 8×8). |
| turns_per_stage | int | Turns per stage (10). |
| pest_start_turn | int | First turn when pests can spawn (3). |
| pest_destroy_rounds | int | Rounds of pest before crop is destroyed (3). |
| moneyplant_self_destruct_prob | float | Chance per turn (0.1 = 10%). |
| seed_value | int | RNG seed for reproducibility. |

Used by `GameController` and `GameState`; actual values come from `data/config/game_config.tres`.

---

### `scripts/data/CropDef.gd`
**Resource script** for one crop type.

- **Type enum**: PUMPKIN, CHILI, MONEY_PLANT, STRAWBERRY, SUNFLOWER.
- **Exports**: id, display_name, cost, base_price, grow_time, type_enum, pumpkin_isolation_radius, chili_clean_radius.

Each crop is a `.tres` in `data/crops/` that references this script. Logic uses `type_enum` and radii for abilities (Pumpkin isolation, Chili clean range).

---

### `scripts/data/CropRegistry.gd`
**RefCounted** (no node). Loads all crop definitions at construction.

- **CROP_PATHS**: Maps crop id (e.g. `"chili"`) to `res://data/crops/<id>.tres`.
- **_defs**: id → CropDef after loading.
- **get_def(id)**: Returns CropDef or null.
- **get_all_ids()** / **get_all_defs()**: For iterating crops (e.g. card bar).

Created once by `GameController` and shared for planting, pricing, and UI.

---

### `scripts/core/CropInstance.gd`
**RefCounted** — one crop on the grid (runtime only).

- **def_id**: Crop type id (e.g. `"pumpkin"`).
- **remaining_grow**: Turns left until harvest; 0 or less = harvest this turn.
- **has_pest**: Whether this crop is infested.
- **pest_rounds**: Turns infested; ≥3 (config) = destroyed.

**_init(def_id, grow)**: Sets def_id and remaining_grow.  
**duplicate_crop()**: Returns a copy (for potential future use).

Stored in `GameState.grid[y][x]`; never in a scene tree.

---

### `scripts/core/GameState.gd`
**RefCounted** — all mutable game state, no nodes.

- **money**, **stage_index** (0–3), **turn_in_stage** (1–10), **global_turn** (1–40).
- **grid**: 2D array `grid[y][x]` = CropInstance or null.
- **next_pest_target**: Vector2i of next pest cell; (-1,-1) = none.
- **stage_requirements**, **size**, **rng**: From GameConfig or defaults.

**_init(config)**: Copies config (requirements, size, seed), builds RNG, calls _init_grid().  
**get_cell(pos)** / **set_cell(pos, crop)** / **clear_cell(pos)**: Bounds-checked grid access.  
**has_pest_telegraph()**: True when next_pest_target is valid.

Owned by `GameController`; views only read it via controller or signals.

---

### `scripts/core/GridRules.gd`
**RefCounted** with **static** helpers for grid geometry. No state.

- **in_bounds(size, pos)**: Whether pos is inside [0, size.x) × [0, size.y).
- **chebyshev_dist(a, b)**: max(|dx|, |dy|).
- **cells_in_chebyshev(size, pos, radius)**: All cells within Chebyshev radius (excluding center). Used for Pumpkin “within 1 grid” and Chili “within 2 grids”.
- **four_neighbors(size, pos)**: N/E/S/W only. Used for Strawberry connected component.
- **diag_rays_from(size, pos)**: Cells along the four diagonals from pos. Used for Sunflower pricing.
- **connected_component_4dir(grid, size, start, def_id)**: BFS over 4-neighbors with same def_id. Used for Strawberry group size at harvest.
- **cell_at(grid, size, pos)**: Safe grid read; grid is row-major grid[y][x].

Used by `GameController` (plant, harvest pricing) and by `CropAbilityInfo` conceptually for tooltip visuals.

---

### `scripts/core/GameController.gd`
**Node** — single source of truth: owns state, config, registry; runs turn logic; emits signals.

**Signals**

- **state_changed(state)**: After any state change (plant, end_turn, restart, continue).
- **cell_changed(pos, cell_data)**: One cell updated (plant, harvest, destroy).
- **pest_telegraphed(pos)**: Next turn’s pest target set.
- **stage_changed(stage_index)**: Stage index changed (e.g. after continue).
- **stage_cleared(stage_index)**: Stage 1–3 cleared; UI shows “Stage N Clear!” popup.
- **game_over(won, reason)**: Win or lose; UI shows game over popup.

**State**

- **state**: GameState.
- **config**: GameConfig (from `game_config.tres`).
- **registry**: CropRegistry.
- **game_ended**: True after win/lose; blocks plant, end_turn; keeps game over popup mandatory.
- **stage_clear_showing**: True while “Stage N Clear!” is up; blocks actions until Continue.

**Methods**

- **_ready()**: Adds to group `game_controller`, loads config and registry, creates initial state (money 15), emits state_changed.
- **can_plant(cell, crop_id)**: False if game_ended/stage_clear_showing, cell occupied, or can’t afford. Otherwise checks cost.
- **plant(cell, crop_id)**: Deducts cost, creates CropInstance, applies Pumpkin (GT−1 if isolated) and Chili (clean pests in radius), sets cell, emits cell_changed and state_changed.
- **end_turn()**: No-op if game_ended or stage_clear_showing. Then: (1) apply telegraphed pest, (2) pest rounds + destroy at 3, (3) Money Plant 10% self-destruct, (4) growth tick (skip if pest), (5) harvest (compute prices from current board, then remove and add money), (6) advance turn and do stage check (10 turns; pass → stage_cleared or game_over win, fail → game_over lose), (7) choose next pest telegraph.
- **continue_to_next_stage()**: Clears stage_clear_showing, increments stage_index, resets turn_in_stage to 1, emits stage_changed and state_changed.
- **_harvest_price(pos, crop)**: base_price + Strawberry connection bonus + Sunflower diagonal bonus.
- **restart()**: Resets game_ended and stage_clear_showing, new GameState, money 15, refreshes grid/cell signals, optional pest telegraph for turn 3.

---

### `scripts/ui/GameTheme.gd`
**RefCounted** — shared colors and style helpers. No nodes.

- **Colors**: BG_COLOR, SOIL_*, CARD_*, TEXT_DARK, TEXT_MUTED, HUD_PANEL, PROGRESS_*, PEST_WARN.
- **make_stylebox_flat(bg, border, corner)**: Builds a flat StyleBox with 1px border.
- **style_grid_cell()** / **style_card_normal()** / **style_card_selected()** / **style_card_disabled()** / **style_hud_panel()**: Convenience styles for grid, cards, and HUD.

Used by HUDView, GridView, CardBarView, and popups for a consistent look.

---

### `scripts/ui/CropAbilityInfo.gd`
**RefCounted** — static data for card tooltips. No nodes.

- **get_ability_text(crop_id)**: Short description string per crop (e.g. Chili: “On plant: removes pests from all crops within 2 tiles.”).
- **get_effect_cells(crop_id)**: Array of Vector2i in a 5×5 local grid (center 2,2) indicating effect area for the mini-grid (Pumpkin: center + 8 neighbors; Chili: full 5×5; etc.).
- **is_center_cell(crop_id, local)**: Whether local is (2,2).

Used by CardBarView when showing the hover tooltip (description + 5×5 effect grid).

---

## `data/` — Resources (tunable data)

### `data/config/game_config.tres`
Single **GameConfig** resource: stage_requirements [10,25,45,70], board 8×8, 10 turns per stage, pest from turn 3, 3 pest rounds, 0.1 Money Plant chance, seed 12345. Loaded by GameController; change values here (or in Inspector) to tune the game without editing scripts.

### `data/crops/*.tres`
One **CropDef** per crop: pumpkin, chili, moneyplant, strawberry, sunflower. Each sets id, display_name, cost, base_price, grow_time, type_enum, and radii. CropRegistry loads these paths; editing a .tres changes that crop’s stats/name.

---

## `scenes/` — Scenes and attached scripts

### `scenes/main/Main.tscn`
Root scene.

- **Main** (Node): Script Main.gd.
- **GameController** (Node): Script GameController.gd; no children.
- **UI** (CanvasLayer): Background ColorRect (warm white), VBoxRoot (VBoxContainer) containing HUD, GridArea (expanding; CenterContainer with GridView), CardBar.
- **GameOverPopup**, **StageClearPopup**: Popups as siblings of UI (so they draw on top).

Layout: top = HUD, middle = centered grid, bottom = card bar; background full-screen.

### `scenes/main/Main.gd`
Attached to root Main node.

- **_ready()**: Gets GameController, GameOverPopup, StageClearPopup. Connects controller.game_over → game_over_popup.show_result, controller.stage_cleared → stage_clear_popup.show_stage_cleared.

Only job: wire controller signals to popups.

---

### `scenes/ui/HUD.tscn`
**PanelContainer** with Margin → VBox: StageTurn label, Money label, Requirement label, ReqBar (ProgressBar), Telegraph label, EndTurn button. Script: HUDView.gd.

### `scenes/ui/HUDView.gd`
- Finds **GameController** via group `game_controller`; subscribes to state_changed, pest_telegraphed; End Turn calls controller.end_turn().
- Applies **GameTheme** styles to panel, labels, progress bar, End Turn button.
- **_refresh(state)**: Disables End Turn if game_ended or stage_clear_showing; sets stage/turn/money text, requirement bar (value = money, max = requirement), clears telegraph text when none.
- **_on_pest_telegraphed(pos)**: Sets telegraph label to “Pest next: (x, y)”.

Displays and drives End Turn only; no direct state mutation.

---

### `scenes/ui/GridView.tscn`
**Control** (anchors full in parent). Script: GridView.gd. No built-in children; grid is created in code.

### `scenes/ui/GridView.gd`
- Adds self to group **grid_view** (so CardBar can call set_selected_crop).
- Finds **GameController**; subscribes to state_changed, cell_changed, pest_telegraphed.
- **_build_grid()**: Creates GridContainer 8×8, one Button per cell (CELL_SIZE 72, soil style, font 9, clip text), stores buttons in _buttons; sets custom_minimum_size so the grid has fixed size.
- **set_selected_crop(crop_id)**: Called by CardBar when a card is selected.
- **_on_cell_pressed(pos)**: If a crop is selected, controller.plant(pos, _selected_crop_id).
- **_refresh_cell(pos)**: Updates one button: if cell has crop, show short name + “G:r P:p” (and “!!” if pest telegraph); if empty, “!!” when telegraph else blank; disabled when cell occupied or when block_input (game_ended / stage_clear_showing).

Renders grid and forwards clicks to controller; never changes state itself.

---

### `scenes/ui/CardBar.tscn`
**PanelContainer** with Margin (no fixed children). Script: CardBarView.gd; adds cards and tooltip in code.

### `scenes/ui/CardBarView.gd`
- Applies **GameTheme** panel style.
- **_build_tooltip()**: Creates a PopupPanel with description Label and 5×5 GridContainer of ColorRects; added as child of CardBar for positioning.
- **_build_cards()**: CenterContainer → HBox; one Button per CropDef (Cost/Sells/Grows text, toggle, hover style). Connects pressed → _on_card_pressed, mouse_entered/exited → hover and tooltip timer.
- **_process(delta)**: When tooltip timer expires, _show_tooltip_for(hovered button): sets description from CropAbilityInfo.get_ability_text, colors 5×5 from get_effect_cells, pops tooltip above card.
- **_on_card_pressed(crop_id)**: Sets _selected_id, updates button pressed state, finds grid_view and calls set_selected_crop(crop_id).
- **_update_card()**: Sets card text (Cost/Sells/Grows), disabled if game_ended/stage_clear_showing or can’t afford; updates normal style (selected / normal / disabled).

Shows crop cards, selection, and hover tooltips; selection is forwarded to GridView.

---

### `scenes/ui/GameOverPopup.tscn`
**PopupPanel** with Margin → VBox: Title, Reason, Restart button. Script: GameOverPopup.gd.

### `scenes/ui/GameOverPopup.gd`
- **show_result(won, reason)**: Sets title “You Win!” / “Game Over”, reason text, exclusive = true, popup_centered(). Called by Main when controller emits game_over.
- **popup_hide**: If closed without Restart (e.g. click outside), re-opens popup while controller.game_ended (keeps popup mandatory).
- **Restart**: Sets _closing_by_restart, calls controller.restart(), hides popup.
- **_input**: Eats key events when visible so keys don’t trigger things behind.

Ensures player must press Restart after game over.

---

### `scenes/ui/StageClearPopup.tscn`
**PopupPanel** with Margin → VBox: Title (“Stage N Clear!”), Continue button. Script: StageClearPopup.gd.

### `scenes/ui/StageClearPopup.gd`
- **show_stage_cleared(stage_index_0based)**: Sets title “Stage %d Clear!” (1-based), exclusive = true, popup_centered(). Called by Main when controller emits stage_cleared.
- **popup_hide**: Re-opens if closed without Continue while controller.stage_clear_showing.
- **Continue**: Sets _closing_by_continue, calls controller.continue_to_next_stage(), hides popup.
- **_input**: Eats key events when visible.

Ensures player must press Continue between stages.

---

## Flow summary

1. **Main** loads; **GameController** creates state, config, registry, emits state_changed.
2. **HUD**, **GridView**, **CardBar** get controller from group, subscribe to signals, and render.
3. Player picks a card (CardBar → set_selected_crop on GridView), then clicks empty cell → controller.plant → state and cell_changed.
4. Player clicks End Turn → controller.end_turn() runs full resolution; then advance turn and stage check; may emit stage_cleared (Stage 1–3) or game_over (win/lose).
5. **StageClearPopup** or **GameOverPopup** appears and stays until Continue or Restart; controller blocks all actions via game_ended / stage_clear_showing.
6. Restart → new state, reset flags, refresh UI. Continue → next stage, turn_in_stage = 1.

Config and crop data live in **data/**; behavior and structure are in **scripts/** and **scenes/** as above.
