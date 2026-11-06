# Tactics — Architecture (Godot 4 / GDScript)

**Current implementation:** Combat v0.5 / Playable Prototype UI v0.2, workspace verified 2026-11-06. Earlier GitHub-snapshot issues are distinguished from current behavior below; executed-test evidence is in DEVELOPMENT_STATUS.md.

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
| `scripts/combat/dying_manager.gd` | Pending dying, rescue HP/state resolution, elimination |
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

## Combat v0.5 transition ownership
- Dying priority follow-up: `TurnManager.get_dying_block_reason()` runs before pending-Attack checks and also gates `ActionExecutor.respond_to_attack()`. `DyingManager.ensure_pending_dying()` adopts an existing DYING participant if there is no registered window, so direct resolver/pipeline damage is discovered at the next guard/status/controller rescue/finalize boundary. It preserves the current window; it is not a centralized damage event dispatcher or a new simultaneous-damage ordering contract.
- Finalizing an eliminated pending-attack target completes that stale response through the executor without consuming Dodge. Otherwise the interrupted attack remains pending and resumes after rescue/elimination. The UI uses the shared modal for Dying before response/tool pickers, with rescuer/healing-card selection and explicit no-rescue elimination. Compact hand cards render name plus rank/suit; tooltip/selection descriptions come from cards.json.
- Paid-rescue migration: `CombatController.rescue_player(rescuer_id, target_id, card_id=0)` now takes an **owned healing-card instance ID**, replacing the former free heal-amount argument. Missing/default card ID fails. `ActionExecutor.use_rescue` checks the active Dying target, delegates eligibility/ownership/effect/amount checks to ActionValidator, pays one card via GameState, and invokes `DyingManager.rescue_player(..., heal_amount)` as the low-level HP/state operation; failed resolution restores the card. All gameplay/UI calls use the paid executor path. The low-level manager signature is retained for internal effect resolution.
- EffectResolver preserves negative damage HP and enters DYING at HP <= 0. DyingManager permits self-rescue by the current DYING player and rescue by another living player. Partial recovery through negative HP/zero retains the current window; recovery above zero closes it. No normal phase resumes while any Dying window remains.
- Healing follow-up: `CombatController.use_heal(actor_id, card_id)` delegates to `ActionExecutor.use_heal` and `ActionValidator.validate_heal`. Validation requires the current living wounded actor in PLAY, an owned single-effect healing card, a positive integral JSON amount and no pending windows/effect holds. Executor pays via GameState, calls the existing EffectResolver.restore_hp, and restores the card if healing fails. UI never assigns HP. This is self-healing, not Dying rescue.
- Prototype hand/confirmation follow-up: the lower hand renders the current actor with Bot DEBUG labeling. Local card/target selection is cancellable; the shared confirmation dispatches to the current actor's validated Attack/Heal/Tool/turn-discard API. Separate sidebar Debug controls and target Dodge/tool modal pickers remain available. No engine turn/phase or default-scene changes.
**Opening/interaction follow-up:** the user reconfirmed named order `[1, 2, 3, 4]` and four opening cards. The latest correction requires normal DRAW on every turn, including the first; it supersedes the earlier first-DRAW skip. The original v0.5 start_game API remains compatible.
- `GameState.deal_initial_hands(count, order) -> ActionResult` preflights a pristine table, unique valid participants, conservation and sufficient draw cards before round-robin dealing through draw_card. It rejects duplicate deals and shortages without a partial opening hand.
- `CombatController.start_match(initial_cards=4)` deals once, then starts normal progression with 2-card DRAW even on the first turn. The obsolete skip_first_draw flag/first-draw bookkeeping are removed; public method signatures and the Phase enum are unchanged. Existing `start_game()` callers retain their no-deal behavior.
- `TurnManager.get_phase_display_name(phase)` maps all six enums to Vietnamese labels shared by UI/turn logging. Player-facing phase guards/status/card hints also use Vietnamese; gameplay continues to compare enum values rather than translated strings.
- `ActionValidator.validate_tool_use/validate_tool_choice` checks source ownership, active ALIVE actor, PLAY, all pending windows/effect holds, different live target, one-card effect, JSON target zones and optional range, and victim ownership. `get_tool_effect` reads the owned source card's existing JSON effect.
- `CombatController.use_tool` delegates to ActionExecutor. Execution uses CardZoneManager/GameState transfers and consumes the tool exactly once. A failed source payment restores the victim card. No HP/phase/window state is assigned from UI.
- UI card-choice overlays are modal input surfaces. The response overlay belongs to the actual pending target, not the actor selected in Debug. It lists their Dodge cards and requires selection plus confirm, or explicit pass. Tool overlays show only card backs and zone labels; they do not expose definition/suit/rank/tooltip. Tool selection is a cancellable proposal until commit; the engine revalidates it at confirmation, so stale choices fail without payment. Opening a tool picker does not consume a card or create a new gameplay response window.
- `TurnManager.new(state, order: Array[int] = [], rules: RuleEngine = null)` accepts the explicit seat-ID order. The prototype passes `[1, 2, 3, 4]` for Human/below, Bot 1/right, Bot 2/above, Bot 3/left: counterclockwise on screen after the latest position swap. `current_player_index` still indexes GameState.players; order IDs do not depend on array/node positions. Default order follows the supplied player array for existing callers.
- `ActionExecutor` calls `TurnManager.bind_combat(self, rules)`. TurnManager keeps a **WeakRef** to inspect pending attack/dying without a strong ownership cycle. It also checks unresolved DYING/zero-HP participants, including those not registered by a future damage source.
- `advance_phase() -> void` remains a guarded **single step** for low-level callers. It cannot exit PLAY, skip a DISCARD decision, resolve an unsupported effect, or bypass pending windows. Direct `start_game()` is also blocked while a window is unresolved.
- `TurnManager.end_play(actor_id) -> ActionResult` validates an explicit request to leave PLAY. `get_required_discards()` queries RuleEngine; `-1` denotes an unavailable/invalid hand-limit rule and prevents phase skipping.
- `set_phase_wait(phase, reason)` registers an unresolved effect/choice; an empty reason clears that explicit hold. A nonempty judgment zone is automatically held because judgment resolution is not implemented. `get_effect_wait_reason()` also gates attacks and discard payment while such a hold exists.
- `_select_next()` checks at most the number of seats. ELIMINATED seats receive neither turn nor DRAW. With no eligible seat, current index becomes `-1`, phase END, and status reports no eligible player without assigning a winner.
- `turn_started(player_id, number)` resets ActionExecutor's attack counter and synchronizes CombatController's tracked actor/turn even for guarded low-level transitions. Mixing direct executor calls with controller calls cannot reset an already-used attack limit a second time.
- `CombatController.start_game()` now automatically reaches the first decision. `advance_until_decision(max_steps=32)` performs at most 32 steps, detects no progress, and preserves every window/decision. Invalid budgets are rejected. `advance_phase()` is retained as a resume alias and **does not implicitly end PLAY**.
- `CombatController.end_turn(actor_id)` requests end_play, then resumes automatic phases. `discard_for_turn(actor_id, card_id)` calls ActionExecutor -> ActionValidator -> GameState.discard_card. It checks current actor, ALIVE, DISCARD, remaining excess, ownership, pending windows and effect holds. Each selected card is moved once; auto-progression resumes after the limit is met.
- Responses, rescue and finalization resume automatic phases after a valid action. Action success is distinct from a later phase hold/budget stop: the completed action remains valid, while `get_status_message()` explains the current stop. Pending windows always take priority over any stored auto-stop reason.
- Core phase changes happen synchronously; future effects that require a decision must register a phase hold before allowing progression. A complete trigger/event engine is not implemented in v0.5.
- PlayablePrototype v0.2 reads state and uses these coordinator APIs. Normal controls expose End Turn and selected-card discard; Bot turn/discard and resume/draw controls stay in the Debug area. It never assigns HP/life state/window/phase directly. Main startup and existing scene paths are unchanged.

### Compatibility migration
Constructor additions are optional and existing public return types remain unchanged. The approved auto-phase rule deliberately changes `CombatController.start_game()` (usually START -> PLAY automatically) and `advance_phase()` (resume without ending PLAY). Existing CombatSystemTest/DyingSystemTest fixtures and UI smoke now use the explicit end-turn contract; TurnManagerTest retains low-level phase assertions and adds v0.5 coverage. The same 13 regression suite classes remain.

## Historical integration issues (earlier GitHub snapshot)
Items 1–6 below have been resolved in the workspace by Stage 0.1/0.2 and the prototype; they are retained as historical context. Item 7 remains Stage 0.3 work. Main still selectively invokes suites, while DyingSystemTest and a separate UI smoke are present.
1. `scripts/actions/action_executor.gd`: `respond_to_attack()` returns success immediately after `pending_attack.clear()` on the damage path. A **second block** calling `dying_manager.begin_dying()` occurs **after that return** and is unreachable. Consequently, lethal damage can put `Player` into DYING without opening the pending Dying Window.
2. `scripts/actions/action_executor.gd`: `use_attack()` checks `pending_attack`, but does not block an existing pending dying window.
3. `scripts/rules/distance_calculator.gd`: filters `player.is_alive()`; this excludes DYING seats. Intended behavior is to exclude only ELIMINATED.
4. `scripts/core/turn_manager.gd`: `_next_player()` increments modulo player count, without skipping ELIMINATED.
5. `TurnManager.advance_phase()` is publicly callable and bypasses `CombatController`'s pending-attack/dying guards.
6. `main.gd` invokes only `DamageRegistryTest.run_all()`; most other tests are commented out. No `DyingSystemTest` file is present in the inspected tree.
7. `DamagePipeline.process_damage()` called outside `ActionExecutor.respond_to_attack()` does not automatically open a Dying Window. Future design should centralize lethal-damage notifications.

## Desired state invariants
- Each physical card instance belongs to exactly one zone.
- `ALIVE`: HP > 0. `DYING`: HP <= 0 until rescued above zero. `ELIMINATED`: HP = 0 and cannot act.
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
