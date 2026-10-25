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
Update this section after each stage. Never assume a stage is complete simply because its prompt was submitted.

- Last completed stage: [UPDATE THIS]
- Current stage: [UPDATE THIS]
- Feature branch: [UPDATE THIS]
- Last verified commit: [UPDATE THIS]
- Tests and results: [UPDATE THIS]
- Known bugs or unfinished work: [UPDATE THIS]
- Next action: [UPDATE THIS]

## Handover rule
Before continuing, inspect the repository and compare its actual state with this roadmap. 
If the code, branch, commits, or tests contradict this document, trust verified repository evidence and explain the discrepancy. 
Continue from the first incomplete stage rather than restarting or blindly repeating previous work.
