# SOULFALL — Design & Technical Overview

Godot version: **4.x** (uses `CharacterBody2D`, `@export`, typed GDScript). Perspective: top-down 2D
("3/4 view" feel like Cat Quest, done in 2D with a Camera2D that gently follows the player — no 3D
needed). All art in this prototype is placeholder **primitive shapes** (Polygon2D / drawn nodes) plus
a small **procedural icon generator** (`resources/IconGenerator.gd`) that draws real Arcana Card /
Artifact / Consumable silhouettes in code, so the shop and card-choice UIs show real icons and the
project opens with zero missing-resource errors. Swap in sprites/AnimatedSprite2D any time — every
character script exposes `$Visual` for exactly that.

## 0. Major Revision History
This started as a gold/EXP/leveling/weapon-loot RPG and has since been revised twice:
- **Revision 2** replaced that entire economy with the card-and-artifact **Arcana Descent** system
  described below.
- **Revision 3** (this one) simplified it further per follow-up feedback:
  - **Removed the Ascension difficulty-selector meta-loop entirely** (no more `AscensionSelector`,
    `unlocked_ascension`, `selected_ascension` -- difficulty now comes purely from floor depth).
  - **Consolidated three separate reward interactables (Reward Altar / Rest Chamber / Special Shop)
    into a single `Shop`** that appears once per cleared floor and sells everything -- Cards,
    Artifacts, and Consumables -- out of one shared, rarity-weighted pool.
  - **Replaced the auto-descend countdown timer with a `FloorPortal`** the player must walk into and
    interact with to descend -- no more automatic progression.
  - **Fixed a real centering bug**: shop/popup windows were computed via `panel.size = X;
    panel.position = -X/2-ish`, which (given how `Control.position`/`.size` interact when anchors sit
    at a single center point) landed the window visibly off-center. Every popup now uses
    `_center_control()`, which sets all four offsets symmetrically around the anchor point in one
    step -- see section 9.

Core Arcana Descent design (unchanged from Revision 2):
- **No more gold, EXP, character levels, Merchant, Trainer, Chests, or boss-dropped weapons.**
- **Star Shards** are the only currency — earned from mobs, Elites, bosses, and breaking Corruption
  Crystals.
- **Arcana Cards** (Minor / Major / Corrupted / Astral) go into slots (3 at run start, +1 per boss
  kill) and pass their `theme` (Fire/Storm/Frost/Shadow/Nature/Void/Blood) into a synergy system —
  2-3 equipped cards sharing a theme grant extra bonuses.
- **Artifacts** are permanent-for-the-run passives that don't take a slot.
- **Consumables** replace potions — stack in an inventory, used with one key (health is prioritized
  automatically; buff consumables apply instantly on use).
- **Cards can be fused** (two equipped cards of the same theme merge into one stronger "Fused" copy)
  or **removed** (freeing a slot) for Star Shards, via the "Manage Arcana" panel in the Shop.
- The player's melee/ranged attacks are **fixed innate abilities** (no more weapon loot at all — see
  section 3) since "boss weapons" and "chest weapons" no longer exist as a category.
- **Meta-progression** (persists across deaths AND app restarts, in `user://savegame.json`): deepest
  floor reached, total runs, bosses defeated all-time, and unlocked card tier.

## 1. Project Structure

```
InfinityDescent/                      (folder name kept for continuity; game itself is "SOULFALL")
  project.godot
  autoload/
    GameManager.gd       -- run/floor/wave state machine, scene flow, boss-defeat rewards
    PlayerStats.gd        -- Arcana/Artifact/Consumable aggregation, Star Shards, meta unlocks
    SettingsManager.gd    -- key-rebinding persistence (user://input_settings.cfg)
  resources/
    IconGenerator.gd            -- procedural pixel-icon generator (cards/artifacts/consumables)
    cards/ArcanaCard.gd, ArcanaDatabase.gd
    artifacts/Artifact.gd, ArtifactDatabase.gd
    consumables/Consumable.gd, ConsumableDatabase.gd
  scenes/
    player/Player.tscn+gd
    enemies/  (Enemy.gd base incl. Elite support + attack telegraphs, 6 minions, CorruptionCrystal)
    bosses/   (BossBase.gd + 3 unique bosses -- grant Arcana slot + Artifact on death, not weapons)
    pickups/PickupOrb.tscn+gd          -- single Star Shard orb type
    projectile/Projectile.tscn+gd
    interactables/Shop.tscn+gd         -- THE single shop, appears every floor clear
    interactables/FloorPortal.tscn+gd  -- walk in + interact to descend (no auto-timer)
    tower/Tower.tscn+gd, WaveData.gd
    hub/Hub.tscn+gd, TowerEntrance.tscn+gd, HubHUD.tscn+gd
    ui/StoryIntro.tscn+gd, MainMenu.tscn+gd, Settings.tscn+gd, HUD.tscn+gd
  docs/STORY.md, DESIGN.md
```

Open `project.godot` in Godot 4.2+ and press Play — it boots to the Story Intro, then the Main Menu,
then the Hub.

## 2. Core Loop

```
Story Intro -> Main Menu (Play/Settings/Quit) -> Hub -> enter Tower
            -> Floor 1..N (waves -> clear -> Shop opens + Portal opens -> interact with Portal)
            -> every 5th floor = Boss floor (grants +1 Arcana slot, an Artifact, Star Shards)
            -> player death -> ejected back to Hub; ALL Arcana Cards, Artifacts, Consumables, and
               Star Shards from that run are lost -- only meta-progression stats persist
```

`GameManager` (autoload) owns floor/wave state and the boss-defeat reward hook
(`on_boss_defeated()`). `PlayerStats` (autoload) is the single source of truth for the player's
current run (Star Shards, equipped Arcana, owned Artifacts, Consumable inventory, HP) and for
persistent meta-progression. `SettingsManager` (autoload) owns input rebinding.

## 3. Player

`Player.tscn` (`CharacterBody2D`):
- **Movement:** 8-directional, `PlayerStats.speed_multiplier()` folds in Storm-theme synergy, Haste
  consumables, Bloodthirst/Tempest Core corrupted-and-major effects.
- **Dash:** short burst with i-frames; cooldown from `PlayerStats.dash_cooldown()` (Shadow-theme
  cards, Temporal Echo, Cracked Hourglass artifact, Chaos Surge penalty all fold in here).
- **Two fixed attacks** (no more weapon loot/slots at all): a short melee arc and a ranged
  projectile, both always available from the start. The melee attack now swings a **visible sword**
  (`Player.tscn`'s `Visual/SwordPivot`) through an arc via `Player._play_sword_swing()`, plus a
  fading translucent "swoosh" showing the actual hit area — replacing what used to be an invisible
  angle/range check with no visual feedback at all. Damage, crit chance/multiplier, attack speed,
  burn-on-hit, chill-on-hit, lifesteal, and Thorns are all computed live from equipped Arcana +
  Artifacts + active Consumable buffs via `PlayerStats` aggregate functions (`damage_multiplier()`,
  `crit_chance()`, `lifesteal_pct()`, `thorns_pct()`, etc.) — see `PlayerStats.gd`'s "AGGREGATES"
  section for the full list and exactly which cards/artifacts feed each one.
- **The Ability key (E)** triggers whichever single **Active Major Arcana** the player has equipped
  (`PlayerStats.active_ability_card()`) — the 5 unique abilities from earlier design revisions
  (Dash Strike, Whirlwind, Second Wind, Elemental Infusion, Avatar Form) now live as Major Arcana
  Cards instead of level-gated unlocks.
- **No block, no jump** — move / dash / melee / ranged / ability / consumable.

## 4. Star Shard Pickups
Every enemy, Elite, boss, and Corruption Crystal death spawns `PickupOrb` instances (Star Shards
only — no more EXP/gold split). Orbs idle briefly, then magnetize toward the player once in range and
auto-absorb on contact. `PlayerStats.has_auto_collect()` (Astral Magnetism card / Star Compass
artifact) extends the magnet radius to the whole floor; `PlayerStats.pickup_radius_bonus()` (Void
Pull card) extends it more modestly.

## 5. Enemies, Elites & Corruption Crystals
- `Enemy.gd` base class now supports `is_elite` (set randomly by `Tower.gd`, starting floor 3): triples
  HP, boosts contact damage and scale, and triples the Star Shard payout — a distinct "elite" currency
  source per spec, without needing a whole separate enemy roster.
- **Attacks are a visible windup -> strike -> recover sequence**, not an instant hit the moment the
  cooldown expires: the enemy telegraphs (scales up ~22%, flashes a warning tint, freezes in place),
  then a brief fading "slash" shape appears and damage actually lands only at that instant (re-checking
  the player is still roughly in range), then a short recovery before it can act again. Timing is
  randomized per attack (`attack_timer` gets a random initial offset at spawn and is re-rolled ×0.8-1.3
  after every attack) so identical enemies spawned together drift out of sync instead of swinging in
  lockstep. Subclasses are untouched by this — they still just override `_do_attack()` with their
  unique damage/effect logic; the base class now simply calls it at the "strike" instant instead of
  immediately. Bosses keep their own separate telegraphed attack-pattern system and are unaffected.
- `CorruptionCrystal.gd` is a stationary breakable hazard (extends `Enemy.gd` with zero move
  speed/attack, and overrides `_try_attack()`/`_do_attack()` to no-ops so it never telegraphs an attack)
  scattered on ~30% of waves; breaking one showers Star Shards. It's added to the wave's clear-tracking,
  so floors expect it to be dealt with like any other threat.
- Bosses (`BossBase.gd` + 3 unique bosses, unchanged attack patterns from earlier revisions — see
  `docs/STORY.md` Bestiary) now grant, on death: **+1 Arcana slot**, a **guaranteed weighted-random
  Artifact**, and a burst of Star Shards — via `GameManager.on_boss_defeated()`.

## 6. Arcana Cards (`resources/cards/`)
`ArcanaCard` fields: `card_name, description, arcana_type(MINOR/MAJOR/CORRUPTED/ASTRAL), theme,
effect_id, value, icon_kind, is_active_ability, ability_cooldown, level`. `ArcanaDatabase.gd` is a
plain-GDScript data table (not dozens of `.tres` files) holding every card definition, gated by
`PlayerStats.unlocked_card_tier` (meta-progression). `ArcanaDatabase.random_choices()` does the
weighted draw (mostly Minor, sometimes Corrupted, rarely Astral/Major) used by the Shop.

- **Minor** (12): small single-stat bonuses, 2 per theme (damage, speed, attack speed, chill-on-hit,
  max HP, dash cooldown, crit chance, thorns, lifesteal, shard gain, pickup radius, burn-on-hit).
- **Corrupted** (6): risk/reward compound effects (e.g. Reckless Fury: +30% damage / -20% max HP).
- **Astral** (5, tier 2+): rare powerful effects (auto-collect, a per-floor shield, big shard/dash
  bonuses).
- **Major** (7): run-defining legendaries — 5 are **Active** (bind to the Ability key, reskinning the
  old level-gated abilities) and 2 are big passive stat blocks (Heart of the Spire, Tempest Core).

**Fusion & removal** happen in the Shop's "Manage Arcana" panel: fusing two equipped cards sharing a
`theme` consumes both and returns `ArcanaCard.make_fused_copy()` (same effect, ~60% stronger value,
"Fused" name prefix) into one of the two slots; removing a card frees its slot for Star Shards.

## 7. Artifacts (`resources/artifacts/`)
`Artifact` fields: `artifact_name, description, effect_id, value, rarity(COMMON/RARE/LEGENDARY),
icon_kind`. `ArtifactDatabase.gd` holds ~11 definitions; `random_weighted()` (55% common / 35% rare /
10% legendary) is used by boss kills and the Shop. Notable Legendaries: Phoenix Ash (revive once
per run at 50% HP), Heart of the Warden (+80 HP/+10% damage), Star Compass (auto-collect + shard gain).
Artifacts share the same `effect_id` vocabulary as cards where it makes sense (e.g. `dmg_pct`,
`max_hp_flat`) so `PlayerStats._effect_value()/_effect_count()` sum across **both** cards and artifacts
transparently. In both the HUD and the Shop, Artifacts render as small icons with their name/rarity/
description in a hover tooltip — never as a card — per the Slay-the-Spire-inspired presentation.

## 8. Consumables (`resources/consumables/`)
`Consumable` fields: `consumable_name, description, effect(HEAL/STRENGTH_BUFF/SPEED_BUFF/
FORTITUDE_BUFF/SHARD_BURST/SHIELD), value, duration, cost, icon_kind`. `ConsumableDatabase.gd` holds 6
definitions. Health Draughts stack and are prioritized by the single Consumable key
(`PlayerStats.use_best_consumable()`); the timed buff consumables (Might/Haste/Fortitude) apply
immediately when bought or used rather than sitting in a multi-item hotbar — a deliberate scope
simplification, noted here so it's easy to expand into a full hotbar later. "Unstable Shard Cluster" is
drop-only (never sold, since paying shards for shards would be a non-choice). Like Artifacts,
Consumables show as small icons (with a stack-count badge in the HUD) with full details in a hover
tooltip, matching the Shop's presentation.

## 9. The Shop & the Floor Portal
Per spec, there is now **exactly one shop interactable per cleared floor** (`Shop.gd`/`.tscn`),
replacing the old three-way split between a free Reward Altar, a small Rest Chamber, and a bigger
Special Shop every 10th floor.

**Layout is modeled directly on Slay the Spire's shop screen**, per follow-up feedback:
- **Arcana Cards** (`CARD_OFFER_COUNT` = 3) are shown as real tarot-card-sized panels with their full
  effect text written directly on the card — no lookup or tooltip needed to know what a card does.
- **Artifacts and Consumables** (3 each) are deliberately **not** shown as cards — they're small
  relic-shelf icon buttons, exactly like Slay the Spire's relics/potions row. Their name, description,
  and price only appear in a native Godot hover tooltip (`Button.tooltip_text`), keeping the shop
  visually clean the way the reference image does.
- The card and artifact rolls are already rarity-weighted under the hood (`ArcanaDatabase.
  random_choices()`, `ArtifactDatabase.random_weighted()`), so Corrupted/Astral/Major cards and
  Rare/Legendary artifacts turn up less often than common items.
- The "Manage Arcana" fuse/remove panel is itself offered as a shelf icon (styled after the
  reference image's "Card Removal Service!" tile) rather than a text button, for visual consistency
  with the rest of the shelf.
- A scaling-cost **Reroll** button remains, next to **Leave**.

There's no more auto-descend countdown. Alongside the Shop, floor-clear also spawns a
**`FloorPortal`** — the player must walk up to it and press "interact" to descend
(`FloorPortal.entered` signal -> `Tower._descend_to_next_floor()`); nothing happens automatically.

**Popup centering fix:** every popup window is centered using `Shop._center_control()`, which sets a
Control's four offsets symmetrically (`-w/2, -h/2, w/2, h/2`) around a `PRESET_CENTER` anchor point in
one step, and renders through a dedicated `CanvasLayer` at `layer = 20` so it always sits above the HUD
and the game world regardless of where the player/camera currently are.

**Stack overflow fix:** the shop used to tear down and rebuild a `GridContainer` nested inside a
`ScrollContainer` on every redraw, clearing old children with `queue_free()` alone (which only
*defers* removal) while immediately adding new ones on top in the same call — for a brief window, both
the old and new node trees existed simultaneously, and that combination could trigger a Godot
layout/size-negotiation stack overflow ("Stack overflow (stack size: 1024)"), especially under the
autowrap-heavy small-card layout the shop used before. The fix has three parts, all now standard
practice across the project (`Shop._clear()`, `HUD._clear_row()`):
1. The shop's static frame (background, title, Star Shard counter, button row) is built **once**, in
   `_open_shop()`. Redraws (Reroll, Manage Arcana, Back) only clear and rebuild the small
   `content_area` sub-tree, not the whole panel.
2. Clearing always calls `remove_child()` (immediate — detaches the node from the tree right away)
   **before** `queue_free()` (deferred — only frees memory later), so a stale node can never remain
   attached to the tree at the same time a freshly-built replacement is added.
3. The `GridContainer`-inside-`ScrollContainer` combination is gone entirely, replaced by simple fixed-
   count `HBoxContainer` rows — removing the specific nested-container/autowrap layout pattern most
   likely to have triggered the recursion in the first place.

## 10. Meta-Progression & the Hub
`PlayerStats._check_meta_unlocks()` (called after every run and boss kill) raises
`unlocked_card_tier` (Tier 2 at floor 15) — the only meta-unlock left after removing the Ascension
difficulty-selector loop. `HubHUD.gd` displays deepest floor, total runs, lifetime boss kills, and
unlocked card tier. Difficulty now comes purely from `GameManager.floor_difficulty_multiplier()`
(floor depth + any Corrupted Arcana effects), with no separate meta difficulty setting to manage.

## 11. Extending This Prototype
- Swap placeholder Polygon2D visuals for `AnimatedSprite2D` — every character script exposes `$Visual`.
- Swap `IconGenerator` icons for real texture assets by changing `TextureRect.texture` calls.
- Add more `ArcanaDatabase`/`ArtifactDatabase`/`ConsumableDatabase` entries — they're just data, no
  new scenes required.
- Add a 4th/5th boss by copying `BossBase.gd`'s pattern.
- Build an actual "tower variant" system by branching `WaveData.gd`'s enemy pools and `Tower.gd`'s
  arena setup behind a Hub-side selector, if desired later.
- Give Consumables a real multi-slot hotbar instead of the single priority-use key.
- If re-adding a difficulty-selector meta-loop, reuse `Shop._center_control()`'s pattern for any new
  popup UI to avoid reintroducing the centering bug.
