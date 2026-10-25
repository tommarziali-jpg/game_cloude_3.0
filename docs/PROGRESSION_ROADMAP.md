# SOULFALL — Progression System Roadmap

## Project
- Game: SOULFALL
- Engine: Godot 4.x
- Language: GDScript
- Repository: https://github.com/tommarziali-jpg/game_cloude_3.0
- Main branch: `main`

## Overall goal
Build a complete, polished, balanced progression system that fits the existing game architecture and preserves current gameplay.

## Target content
- Approximately 10 total artifacts, including existing artifacts.
- At least 50 distinct cards; aim for 55–60 total, including existing cards.
- Approximately 8–12 useful consumables, including existing consumables.
- Several distinct build identities with meaningful card/artifact/consumable synergies.
- Integrated rewards, shops, unlocks, descriptions, UI feedback, balancing, and save/load behavior where applicable.

## Implementation rules
1. Inspect the actual repository and current code before editing.
2. Work on a dedicated feature branch, never directly on `main`.
3. Read existing systems before designing replacements.
4. Reuse existing architecture where practical.
5. Avoid duplicate IDs, broken references, unused effects, and hard-coded item combinations where a reusable event system is appropriate.
6. Preserve existing combat, Major Arcana abilities, progression, controls, and save data unless a deliberate compatible change is necessary.
7. Implement and test one stage at a time.
8. Do not claim a feature or test works unless it has been verified.
9. At the end of every stage, report changed files, implemented features, tests run and results, remaining issues, branch name, and the next stage.
10. Commit completed stages when GitHub access and permissions allow. Never overwrite unrelated user changes.

## Required stages
- Stage 0: Inspect repository, current branch, existing systems, and available tests.
- Stage 1: Implement a reusable combat-event foundation for item effects.
- Stage 2: Expand and integrate the card catalog to 55–60 total cards.
- Stage 3: Expand and integrate the artifact catalog to approximately 10 total artifacts.
- Stage 4: Implement cross-item synergies and build identities.
- Stage 5: Expand and integrate the consumable catalog to approximately 8–12 total consumables.
- Stage 6: Integrate items with rewards, shops, unlocks, and progression.
- Stage 7: Polish item UI, descriptions, feedback, and navigation.
- Stage 8: Balance, test, fix bugs, and complete the release audit.
- Stage 9: Perform an independent final audit and fix verified issues.

## Current progress
Evidence-based audit completed: 2026-10-25. Statuses below reflect inspected code, not prior chat claims.

| Stage | Status | Repository evidence |
|---|---|---|
| 0 — Repository audit | **Completed** | Confirmed default branch, recent commits, project configuration, core progression/combat scripts, item databases, and available test/CI evidence. |
| 1 — Combat-event foundation | **Partially completed** | Feature branch adds `autoload/CombatEvents.gd`, registers it as an autoload, and emits events for player attacks/damage, enemy damage/defeat, consumable use, and floor lifecycle. Godot runtime/parser verification is still pending. |
| 2 — Card catalog (55–60) | **Not started** | `ArcanaDatabase.gd` currently defines 30 distinct cards: 12 Minor, 6 Corrupted, 5 Astral, and 7 Major. |
| 3 — Artifact catalog (~10) | **Completed by existing code** | `ArtifactDatabase.gd` defines 11 artifacts; shop offers and boss rewards already use the artifact system. No catalog expansion is needed unless later audit finds broken effects. |
| 4 — Cross-item synergies/build identities | **Partially completed** | `PlayerStats.gd` combines shared effect IDs across cards/artifacts and has theme-count bonuses. Broader event-driven item synergies and build coverage remain unfinished. |
| 5 — Consumable catalog (8–12) | **Partially completed** | `ConsumableDatabase.gd` defines 6 consumables; inventory/use and shop integration exist. Add and validate more useful items. |
| 6 — Rewards, shops, unlocks, progression | **Partially completed** | Shop offers cards/artifacts/consumables, boss defeats grant artifacts and Arcana slots, and reaching floor 15 unlocks card tier 2. Full reward-flow audit remains. |
| 7 — Item UI/descriptions/feedback | **Partially completed** | Shop code builds item offers and displays card descriptions plus artifact/consumable tooltips; end-to-end UI polish/navigation has not been audited. |
| 8 — Balance/test/release audit | **Not started** | No automated test suite or CI workflow was found in the inspected repository cache; runtime tests have not been run. |
| 9 — Independent final audit | **Not started** | Depends on completing implementation and validation stages. |

- Last completed stage: Stage 0 — repository audit.
- Current stage: Stage 1 — combat-event foundation (implementation in progress; runtime verification pending).
- Feature branch: `feature/soulfall-combat-event-foundation`
- Last verified commit: `3d21628662120dc459117654d09d51278727b4bd` (source changes inspected; not runtime-tested).
- Tests and results: Static source inspection only. GitHub commit status checks returned no statuses for the inspected commit. No test directory or workflow configuration was found in the inspected file cache. A local clone/headless Godot run could not be performed because this execution environment could not resolve github.com.
- Known bugs or unfinished work: The new event bus and typed signal declarations still require Godot 4.x parser/runtime validation. No automated test harness was found. Catalogs remain below the card and consumable targets.
- Next action: Validate the event bus with Godot 4.6 headless/editor import and gameplay smoke tests, then finish Stage 1 before moving to card expansion.

## Handover rule
Before continuing, inspect the repository and compare its actual state with this roadmap. 
If the code, branch, commits, or tests contradict this document, trust verified repository evidence and explain the discrepancy. 
Continue from the first incomplete stage rather than restarting or blindly repeating previous work.
