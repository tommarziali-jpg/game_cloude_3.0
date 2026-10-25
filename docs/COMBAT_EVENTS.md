# Combat event foundation

## Contract

CombatEvents.publish(name, context) is the event entry point. Events are dispatched FIFO on the next process tick, not synchronously from the damage stack. Each event has an internal event ID, chain ID, depth, and visited-effect set. Listeners may enqueue follow-up events; they do not recursively dispatch them.

The normal primary attack sequence is player_attack_started, attack_hit (one per target actually hit), enemy_damaged, and enemy_defeated if lethal. critical_hit is queued with the corresponding hit context. Combat state changes immediately, while listeners run on the next process tick, so listeners treat events as notifications rather than a way to cancel damage.

Context fields include attacker, target, source, damage, attack_type, is_critical, is_dot, is_secondary, effect_id, and progression metadata where applicable. Node references are nulled during dispatch if they have already been freed.

Limits: chain depth 8, 32 events per chain, and 256 dispatched events per frame. claim_effect prevents the same effect ID from triggering twice inside one chain. publish_once suppresses duplicate collision/callback events for a key until its cooldown expires. PlayerStats.reset_for_new_run clears the queue, chain counters, dedupe keys, and effect cooldowns.

## Effect rules

autoload/CombatEffects.gd owns data-driven rules with id, event, action, cooldown, and optional action values. Rules are inert unless the player has the corresponding effect ID. Existing attack damage, burn/chill, lifesteal, knockback, projectiles, and Major Arcana logic remain in their current owners; the event system observes them and provides a reusable extension point.

## Validation

Run godot --headless --path . --script tests/combat_events_smoke_test.gd with Godot 4.x. The smoke test covers FIFO dispatch, duplicate suppression, and the recursion-depth ceiling. In an editor/gameplay smoke test, verify melee multi-target hit counts, projectile hit/critical context, burn/chill applied and expired events, dodge during dash, boss phase 2, boss defeat, and wave/floor lifecycle. The implementation environment did not have a Godot CLI available, so this script still needs to run in Godot 4.x before the stage can be called runtime-verified.
