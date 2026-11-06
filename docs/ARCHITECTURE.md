# Tactics — Architecture (Godot 4 / GDScript)

**Snapshot:** inspected `lt-winter/tactics`, branch `main`, 2026-11-06. This is a code-grounded map, not a guarantee of successful test execution.

## Layer overview

```text
data/cards.json + data/decks/standard.json + data/rules/base_rules.json
          |
CardDatabase / DeckDatabase / RuleEngine
          |
CardDefinition -> CardInstance -> Deck
          |
GameState -> CardZoneManager -> Player
          |
TurnManager ----> CombatController
                       |
                 ActionExecutor
                  /          \
         ActionValidator    EffectResolver
                                |
                         DamagePipeline
                                |
                     DamageModifierRegistry
                       + DamageContext
                       |
                    DyingManager
```

This diagram is conceptual: `ActionExecutor` owns both `DamagePipeline` and `DyingManager`, while `DamagePipeline` owns an `EffectResolver` reference. `CombatController` coordinates `TurnManager` and `ActionExecutor`.

## Repository paths and responsibilities

| Path | Responsibility |
|---|---|
| `scripts/cards/` | Card definition, instances, decks and data loading |
| `scripts/core/player.gd` | HP, life state, card zones |
| `scripts/core/game_state.gd` | Player collection, deck, zone transfers, integrity |
| `scripts/core/card_zone_manager.gd` | Move physical card instances among zones |
| `scripts/core/turn_manager.gd` | Phase order and current seat |
| `scripts/rules/rule_engine.gd` | Base rules and prioritized modifiers |
| `scripts/rules/rule_context.gd` | Context for rule evaluation |
| `scripts/rules/distance_calculator.gd` | Circular seat distance |
| `scripts/actions/action_validator.gd` | Attack legality |
| `scripts/actions/action_executor.gd` | Attack card use, response window, damage execution |
| `scripts/actions/effect_resolver.gd` | Apply damage / restore HP |
| `scripts/combat/damage_pipeline.gd` | Apply ordered damage modifiers |
| `scripts/combat/damage_modifier_registry.gd` | Modifier registration, priority ordering |
| `scripts/combat/dying_manager.gd` | Pending dying, simulated rescue, elimination |
| `scripts/combat/combat_controller.gd` | Public combat-facing coordinator |
| `scripts/test/` | Static `run_all()` regression suites |
| `main.gd` | Current test invocation entry point |

## Important APIs (current)
- `GameState.new(cards: Array[CardInstance], players: Array[Player])`
- `GameState.get_player(id)`, `draw_card`, `discard_card`, `validate_state`
- `TurnManager.start_game() -> void`, `advance_phase() -> void`, `get_current_player()`
- `RuleEngine.load_base_rules(path)`, `get_rule(rule_id, context={}, rule_context=null)`
- `ActionValidator.validate_attack(actor_id, target_id, card_id, attacks_used) -> ActionResult`
- `CombatController.start_game()`, `advance_phase()`, `use_attack()`, `respond_to_attack()`
- `CombatController.has_pending_dying()`, `rescue_player()`, `finalize_dying()`
- `DamagePipeline.process_damage(source_id, target_id, amount) -> bool`
- `DyingManager.begin_dying()`, `rescue_player()`, `finalize_dying()`

**Note:** Changing `TurnManager.advance_phase()` from `void` to `bool` or `ActionResult` requires checking all existing tests and callers.

## Known integration issues (verified in GitHub snapshot)
1. `scripts/actions/action_executor.gd`: `respond_to_attack()` returns success immediately after `pending_attack.clear()` on the damage path. A **second block** calling `dying_manager.begin_dying()` occurs **after that return** and is unreachable. Consequently, lethal damage can put `Player` into DYING without opening the pending Dying Window.
2. `scripts/actions/action_executor.gd`: `use_attack()` checks `pending_attack`, but does not block an existing pending dying window.
3. `scripts/rules/distance_calculator.gd`: filters `player.is_alive()`; this excludes DYING seats. Intended behavior is to exclude only ELIMINATED.
4. `scripts/core/turn_manager.gd`: `_next_player()` increments modulo player count, without skipping ELIMINATED.
5. `TurnManager.advance_phase()` is publicly callable and bypasses `CombatController`'s pending-attack/dying guards.
6. `main.gd` invokes only `DamageRegistryTest.run_all()`; most other tests are commented out. No `DyingSystemTest` file is present in the inspected tree.
7. `DamagePipeline.process_damage()` called outside `ActionExecutor.respond_to_attack()` does not automatically open a Dying Window. Future design should centralize lethal-damage notifications.

## Desired state invariants
- Each physical card instance belongs to exactly one zone.
- `ALIVE`: HP > 0. `DYING`: HP = 0 until rescued. `ELIMINATED`: HP = 0 and cannot act.
- A pending attack response must be resolved before phase advance.
- A pending dying window must be resolved before ordinary phase advance or new attacks.
- No turn is assigned to an ELIMINATED player.
- No new turn starts after match completion.
- Rule modifiers must be evaluated against the acting player's context and source priority.
- A successful action cannot partially mutate game state and then fail without explicit recovery semantics.

## Architecture evolution principles
- Prefer a single authoritative coordinator for phase transitions; guard direct `TurnManager` access.
- Keep `ActionResult` as the standard user-facing validation result.
- Avoid duplicate handling of dying transitions across attack cards, skills and delayed effects.
- Separate card effects from the controller as additional cards are implemented.
- Add an explicit match lifecycle / victory evaluator before bot matches.
- Do not introduce UI dependencies into core engine code.
