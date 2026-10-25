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
| 1 — Combat-event foundation | **Implemented; runtime verification pending** | Ordered event queue, chain/depth limits, duplicate suppression, data-driven effect rules, hit/crit/status/dodge/ability events, projectile dedupe, boss/wave/floor hooks, and a headless smoke-test script are present. Godot parser/runtime execution remains pending. |
| 2 — Card catalog (55–60) | **Not started** | `ArcanaDatabase.gd` currently defines 30 distinct cards: 12 Minor, 6 Corrupted, 5 Astral, and 7 Major. |
| 3 — Artifact catalog (~10) | **Completed by existing code** | `ArtifactDatabase.gd` defines 11 artifacts; shop offers and boss rewards already use the artifact system. No catalog expansion is needed unless later audit finds broken effects. |
| 4 — Cross-item synergies/build identities | **Partially completed** | `PlayerStats.gd` combines shared effect IDs across cards/artifacts and has theme-count bonuses. Broader event-driven item synergies and build coverage remain unfinished. |
| 5 — Consumable catalog (8–12) | **Partially completed** | `ConsumableDatabase.gd` defines 6 consumables; inventory/use and shop integration exist. Add and validate more useful items. |
| 6 — Rewards, shops, unlocks, progression | **Partially completed** | Shop offers cards/artifacts/consumables, boss defeats grant artifacts and Arcana slots, and reaching floor 15 unlocks card tier 2. Full reward-flow audit remains. |
| 7 — Item UI/descriptions/feedback | **Partially completed** | Shop code builds item offers and displays card descriptions plus artifact/consumable tooltips; end-to-end UI polish/navigation has not been audited. |
| 8 — Balance/test/release audit | **Not started** | No automated test suite or CI workflow was found in the inspected repository cache; runtime tests have not been run. |
| 9 — Independent final audit | **Not started** | Depends on completing implementation and validation stages. |

- Last completed implementation stage: Stage 1 — combat-event foundation (source changes implemented; runtime validation is still required before declaring the stage stable).
- Current stage: Stage 1 validation — run the smoke test and gameplay checks under Godot 4.x.
- Feature branch: `feature/soulfall-combat-event-foundation`
- Last source revision inspected: `10031edffd18ca1a0f89de079a4fecc5ca63ce69` (static source checks only; not runtime-tested).
- Tests and results: 11 targeted static source checks passed for autoload registration, queue/limits, effect rules, combat hooks, status lifecycle, boss/wave/floor hooks, reset behavior, secondary-effect protection, smoke-test coverage, and HUD independence. The Godot smoke-test script was added but not executed because no Godot CLI is installed in this environment. GitHub status checks still need to be queried for the latest branch head.
- Known unfinished work: Godot 4.x parser/runtime validation and in-game smoke tests are still required. Card and consumable catalogs remain below their eventual targets.
- Next action: Run `godot --headless --path . --script tests/combat_events_smoke_test.gd`, then test multi-target melee, projectile crits, statuses, dodge, and boss/wave/floor events before starting Stage 2.

## Handover rule
Before continuing, inspect the repository and compare its actual state with this roadmap. 
If the code, branch, commits, or tests contradict this document, trust verified repository evidence and explain the discrepancy. 
Continue from the first incomplete stage rather than restarting or blindly repeating previous work.
