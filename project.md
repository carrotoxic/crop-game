# Godot Prototype Spec: 8×8 Crop Placement + Pests + 4 Stages (40 Turns)

This document is written for a Cursor agent to implement the full prototype in Godot using clean game-programming patterns (data-driven crops, signal-driven UI, and a deterministic turn system).

---

## 0) High-level game loop

**Core loop (per turn):**

1. Player **plants at most once** (optional) by selecting a crop card and clicking a grid cell, paying cost.
2. Player clicks **End Turn**.
3. Systems resolve in order:

   * **Spawn pest** (from turn ≥ 3) on a valid crop.
   * **Apply pest effects** (freeze growth; destroy after 3 rounds untreated).
   * **Advance crop growth** (only if not pest-blocked).
   * **Harvest crops** that finished growing → gain money (with dynamic pricing).
   * **Stage progression**: after 10 turns, check **money requirement**; if pass, go next stage; else fail.

**Win/Lose:**

* Win: clear Stage 4 requirement at the end of its 10th turn.
* Lose: fail a stage money requirement check (end of turn 10/20/30/40).

---

## 1) Rules (precise)

### Board / placement

* Board is **8×8**.
* Each cell is either **Empty** or contains **one crop instance**.
* **Cannot plant on an occupied cell**.
* **Cannot plant on a cell until its current plant is harvested** (already implied by “occupied”).

### Stage / turns

* Total **4 stages**, each **10 turns**.
* Each stage has an **end-of-stage money requirement** (configurable, see §8).
* Turn counter is **global** (1–40) or stage-local (1–10) + stage index; implement both for UI.

### Pests

* Starting from **turn 3**, each turn spawns **exactly 1 pest** on a crop.
* **Telegraphing**: the position is shown **one turn ahead** (chosen at end of previous turn, “initiated in that turn”).

  * Implementation detail: decide “next pest target” at end of turn **t**, display it during turn **t+1**, and actually apply the pest at end of turn **t+1**.
  * First telegraph happens at end of turn 2, applied end of turn 3.
* Pests will **not spawn on the same crop until that crop is cleaned**.

  * Interpretation for implementation: a crop that currently has a pest is ineligible for new pest selection (simple and matches intent).
* If a crop has a pest and it’s not cleaned:

  * **It does not grow** (growth timer does not decrease).
  * After **3 rounds** of being pest-infested (3 pest-resolution steps), it is **destroyed** (cell becomes empty, no payout).

### Cleaning pests

* Only **Chili Pepper** has explicit cleaning: “Removes pests when planted (crops within two grids)”.
* “within two grids” = **Chebyshev distance ≤ 2** (a square radius), unless you want Manhattan. Pick one and keep consistent.

  * Recommended: **Chebyshev ≤ 2** because it matches “within N grids” and is easy to visualize as a square.
* When Chili is planted:

  * Remove pest from all crops in range.
  * Reset their pest counters to 0.

---

## 2) Crops (data definitions)

All crops share:

* `name`
* `cost`
* `base_price`
* `grow_time` (GT, number of turns of growth needed)
* `range_rule` (how it measures range; or “none”)
* `ability` hooks

### Pumpkin

* Cost: 2
* Base price: 3
* Grow time: 3
* Ability: **GT - 1 for itself when planted** *if* **no crops within 1 grid**.

  * “within one grid” = neighbors with Chebyshev distance ≤ 1 excluding itself.
  * If condition satisfied at planting time: set this instance’s remaining grow to `max(1, GT-1)`.

### Chili Pepper

* Cost: 1
* Base price: 1
* Grow time: 3
* Ability: on planted → **remove pests in range ≤ 2**.

### Money Plant

* Cost: 2
* Base price: 4
* Grow time: 3
* Ability: **each turn 10% chance to self-destruct**.

  * Trigger during turn resolution (after pest apply, before growth or after growth—choose once).
  * Recommended: resolve **before growth** so it can vanish even if it would have grown.
  * On self-destruct: cell becomes empty, no payout.

### Strawberry

* Cost: 3
* Base price: 2
* Grow time: 3
* Ability: **connected-group bonus**: price +1 for each connected Strawberry.

  * “connected” = 4-direction adjacency (N/E/S/W), typical for “connected”.
  * At harvest time, compute size of its connected component of Strawberries currently on board (including itself).
  * Add bonus `(component_size - 1)` (so a solo Strawberry gets +0).

### Sunflower

* Cost: 3
* Base price: 1
* Grow time: 3
* Ability: price +1 for each plant in **diagonal lines**.

  * Diagonal lines = cells along the 4 diagonal rays (NE, NW, SE, SW) from this crop until board edge.
  * Count **occupied cells** along those rays at harvest time.
  * Bonus = that count.

---

## 3) UI layout requirements

Screen regions:

1. **Top HUD**: stage, turn, money, stage requirement, upcoming pest telegraph, stats.
2. **Middle**: 8×8 grid (clickable cells).
3. **Bottom**: 5 crop cards (card UI) showing cost, base price, grow time, ability; plus current selection + stock if you implement stock.

**Minimal prototype assumption:** unlimited buying per turn constrained only by money. (If you want “stock”, add inventory counts later.)

Key UI interactions:

* Click a crop card → sets `selected_crop_id`
* Hover/click on grid → show cell info tooltip (crop, remaining GT, pest status)
* Click empty cell with selected crop → plant
* End Turn button → resolve

---

## 4) Architecture (clean patterns)

Use a **Model–View–Controller-ish** separation with Godot-friendly patterns:

### A) Data-driven crop definitions (Resources)

* Create a `CropDef.gd` Resource with exported fields:

  * `id`, `display_name`, `cost`, `base_price`, `grow_time`, `type_enum`
  * Optional params: `pumpkin_isolation_radius`, `chili_clean_radius`, etc.
* Store 5 crop defs in `res://data/crops/` and load them into a registry.

### B) Pure game state (no Nodes inside)

Create a `GameState.gd` (RefCounted) that holds:

* `money : int`
* `stage_index : int` (0–3)
* `turn_in_stage : int` (1–10)
* `global_turn : int` (1–40)
* `grid : Array[Array[CropInstance?]]` 8×8
* `next_pest_target : Vector2i?` (telegraphed)
* `rng_seed`, `rng` (RandomNumberGenerator) for determinism
* `stage_requirements : Array[int]`

`CropInstance` (could be a simple Dictionary or a small class `CropInstance.gd`):

* `def_id`
* `remaining_grow : int`
* `has_pest : bool`
* `pest_rounds : int` (0..3)
* `flags` (optional)

### C) Game controller (single source of truth)

`GameController.gd` Node:

* Owns `state : GameState`
* Exposes methods:

  * `can_plant(cell, crop_id) -> bool`
  * `plant(cell, crop_id) -> Result`
  * `end_turn()`
* Emits signals:

  * `state_changed(state)`
  * `cell_changed(pos, cell_data)`
  * `pest_telegraphed(pos?)`
  * `stage_changed(stage_index)`
  * `game_over(win: bool, reason: String)`

### D) Views subscribe to controller signals

* `HUDView.gd` updates labels, telegraph icon.
* `GridView.gd` renders 8×8 buttons/tiles and calls controller for interactions.
* `CardBarView.gd` shows crop cards and selection.

**Rule:** Views never mutate the state directly.

---

## 5) Scene tree proposal (minimal but scalable)

**Main.tscn**

* `Main (Node)`

  * `GameController (Node)` – script `GameController.gd`
  * `UI (CanvasLayer)`

    * `VBoxRoot`

      * `HUD (PanelContainer)` – `HUDView.gd`
      * `GridArea (Control)`

        * `GridView (Control)` – `GridView.gd`
      * `CardBar (PanelContainer)` – `CardBarView.gd`
  * Optional: `GameOverPopup (PopupPanel)`

**Grid rendering options:**

* Simplest: `GridContainer` with 64 `Button`s (or `TextureButton`s).
* Each cell button stores its `Vector2i` in metadata.

---

## 6) Turn resolution order (exact)

In `GameController.end_turn()` do:

### Step 0: advance turn counters

* `global_turn += 1` (or increment after resolution; pick one convention)
* increment `turn_in_stage`, if becomes 11 → stage end check (see Step 6)

### Step 1: apply telegraphed pest (if global_turn >= 3)

* If `state.next_pest_target != null`:

  * if still contains a crop and crop has no pest:

    * set `has_pest = true`
    * set `pest_rounds = 0` (or keep existing, but should be 0)
  * else: (crop harvested/destroyed/moved) → skip gracefully (no pest this turn)

### Step 2: update pest rounds + destroy if needed

For each crop with `has_pest`:

* `pest_rounds += 1`
* if `pest_rounds >= 3`: destroy crop (set cell empty)

### Step 3: money plant self-destruct

For each Money Plant instance (by def_id):

* roll `rng.randf() < 0.10`
* if true: destroy it (empty cell)

### Step 4: growth tick

For each crop:

* if `has_pest`: **do not decrease** `remaining_grow`
* else: `remaining_grow -= 1`

### Step 5: harvest

For each crop with `remaining_grow <= 0`:

* compute final price:

  * `base_price`
  * * Strawberry connection bonus
  * * Sunflower diagonal bonus
  * * other future modifiers
* `money += final_price`
* remove crop from cell

### Step 6: stage end check (when turn_in_stage == 10 after resolution)

* If end of stage:

  * if `money >= stage_requirements[stage_index]`:

    * if `stage_index == 3`: win
    * else:

      * stage_index += 1
      * turn_in_stage = 0 (so next turn becomes 1)
  * else: lose

### Step 7: determine next telegraphed pest target for next turn (if next turn will be >= 3)

* At end of this end_turn, select a valid crop cell:

  * must contain a crop
  * must not have pest (`has_pest == false`)
  * ideally also avoid selecting a crop that will be harvested next resolution? (optional; not required)
* Save to `state.next_pest_target`
* Emit signal so HUD and grid can display telegraph marker

---

## 7) Spatial calculations (define once, reuse)

Implement helpers in `GridRules.gd` (static functions) or inside `GameState`:

* `in_bounds(x,y)`
* `neighbors_chebyshev(pos, radius)` → iterate dx,dy
* `chebyshev_dist(a,b) = max(abs(dx), abs(dy))`
* `manhattan_dist(a,b) = abs(dx) + abs(dy)` (only if you pick it)
* `diag_rays(pos)` → iterate four directions (1,1), (1,-1), (-1,1), (-1,-1) until edge
* `connected_component_4dir(start_pos, filter_def_id)` → BFS/DFS on board

Make one firm choice:

* **Chili range & Pumpkin isolation** use **Chebyshev** radius.
* **Strawberry connectivity** uses **4-direction adjacency**.

---

## 8) Configs (stage requirements, RNG, tuning)

Create `GameConfig.gd` Resource:

* `stage_requirements = [X1, X2, X3, X4]`
* `board_size = Vector2i(8,8)`
* `turns_per_stage = 10`
* `pest_start_turn = 3`
* `pest_destroy_rounds = 3`
* `moneyplant_self_destruct_prob = 0.10`
* `seed = 12345` (allow override)

This makes the prototype tunable without code edits.

---

## 9) UX details that make it “feel deep” (cheap to implement)

These are small but important for “depth”:

1. **Telegraph marker**: show an icon on the targeted cell for the upcoming pest.
2. **Pest counter**: show “1/3, 2/3” on infested crops.
3. **Card preview highlights**:

   * When Pumpkin selected: highlight cells where isolation condition would be met.
   * When Chili selected: show range overlay from hovered cell (which crops would be cleaned).
4. **End-of-stage requirement bar**: show current money vs requirement with a simple progress bar.
5. **Harvest pop-up numbers**: floating “+3” when harvesting (optional, nice polish).

---

## 10) Implementation plan (Cursor agent task breakdown)

### Phase 1 — Core scaffolding

* Create scenes: `Main.tscn`, HUD, grid, card bar.
* Implement `CropDef` resources and a registry loader.
* Implement `GameState` with 8×8 grid init.

### Phase 2 — Interactions

* Card selection logic.
* Grid click → plant (cost deduction, place CropInstance).
* Disable planting when money insufficient.

### Phase 3 — Turn system

* Implement `end_turn()` with the resolution steps in §6.
* Emit `state_changed` and re-render grid each time.

### Phase 4 — Abilities & pricing

* Pumpkin isolation GT reduction on plant.
* Chili pest clean on plant.
* Money Plant self-destruct.
* Strawberry connected pricing at harvest.
* Sunflower diagonal pricing at harvest.

### Phase 5 — Pest telegraph & rules

* Implement telegraph selection at end of turn.
* Display telegraph on grid + HUD.
* Ensure “no respawn on same crop until cleaned” by disallowing `has_pest` crops in selection.

### Phase 6 — Stage system & game over

* Stage end check, win/lose popup, restart button.

---

## 11) Edge cases (must handle gracefully)

* Telegraphed target harvested/destroyed before pest applies → pest step does nothing.
* No valid crop exists for pest telegraph selection → `next_pest_target = null` (no pest next turn).
* Chili cleaning includes telegraphed target? (Yes, if it removes pest before it applies, it should only remove existing pests; telegraph is not a pest yet.)
* Money Plant self-destruct while pest-infested → it still can self-destruct (independent systems).
* Multiple harvests in one turn: compute prices based on the board **at harvest time**; order could matter.

  * Recommended: collect all harvest positions first, then compute prices from a snapshot of the board pre-removal (to avoid Strawberry group shrinking as you harvest).
  * For clarity: during harvest step, create a set/list of harvest positions; compute all payouts using the board state **before removing any harvested crops**, then remove them.

---

## 12) Suggested file/folder structure (Godot)

```
res://
  scenes/
    main/
      Main.tscn
      Main.gd
    ui/
      HUD.tscn
      HUDView.gd
      GridView.tscn
      GridView.gd
      CardBar.tscn
      CardBarView.gd
      GameOverPopup.tscn
  scripts/
    core/
      GameController.gd
      GameState.gd
      CropInstance.gd
      GridRules.gd
    data/
      CropDef.gd
      GameConfig.gd
      CropRegistry.gd
  data/
    crops/
      pumpkin.tres
      chili.tres
      moneyplant.tres
      strawberry.tres
      sunflower.tres
    config/
      game_config.tres
  assets/
    icons/
    fonts/
```

This stays small but follows a clean separation:

* `scripts/core` = logic
* `scripts/data` + `data/` = definitions/config
* `scenes/` = composition

---

## 13) “Definition of done” checklist

* [ ] Can plant crops from cards onto empty cells; money updates correctly.
* [ ] End Turn advances growth; harvest pays out; crops disappear on harvest.
* [ ] Pest telegraph shown one turn ahead; pest applies from turn 3 onward.
* [ ] Pest blocks growth; destroys crop after 3 rounds untreated.
* [ ] Chili cleans pests in radius 2 on plant.
* [ ] Pumpkin reduces GT by 1 if isolated on plant.
* [ ] Money Plant self-destructs ~10% per turn.
* [ ] Strawberry connected bonus works.
* [ ] Sunflower diagonal bonus works.
* [ ] 4 stages × 10 turns; end-of-stage requirement check; win/lose popup.
