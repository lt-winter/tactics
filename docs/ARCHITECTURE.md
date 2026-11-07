# Tactics — Architecture (Godot 4 / GDScript)

**Current implementation:** Combat v0.5 / Playable Prototype UI v0.2 with AOE Tool System v0.1, workspace verified 2026-11-06. Earlier GitHub-snapshot issues are distinguished from current behavior below; executed-test evidence is in DEVELOPMENT_STATUS.md.

## Numeric suit contract (2026-11-07)

`CardInstance.Suit`: HEARTS=0, DIAMONDS=1, CLUBS=2, SPADES=3. DeckDatabase accepts these numeric values or the existing English suit names. Red is Hearts/Diamonds (0/1); black is Clubs/Spades (2/3). Standard deck values were migrated to preserve each physical card's original suit, rank and order. Older numeric mappings below are historical.

## Layer overview

Armor System v0.1 (2026-11-07): ArmorEffectRegistry dispatches descriptors by effect_id and hook through registered callables. EquipmentSystem's existing commit_equip gains an optional slot argument (weapon default); armor action adapters use the same atomic replace batch. One-armor occupancy remains CardZoneManager's existing slot invariant. Registry queries live equipment, tracks identity/revision on equipment_changed and rejects stale removed/re-equipped decisions. CardDatabase validates recognized armor effect parameters; names/definition IDs never select gameplay handlers. Existing inert armor metadata is still accepted by the loader, while equip_armor only enables supported effects.

AttackContext captures the original CardInstance color before payment. AttackResolution adds a targeted checkpoint: Black Shield resolves only its owner; Barrel offers a manual pre-Dodge judgment once. The latter directly moves one top draw CardInstance to discard through CardZoneManager with normal deck recycling, without passing through hand/delayed judgment zones. Failure/skip goes to ordinary Dodge; success resolves that target. No available judgment card retains the choice with an error and a skip option, per designer approval.

DamagePipeline applies Helmet after existing ordered/legacy modifiers, then may retain a prepared context/result for Chainmail before HP mutation. process_damage_result adds pending=true for accepted deferred damage; the retained result is completed in place so Attack/AOE continuations see actual applied_amount only after resolution. The bool process_damage adapter means accepted/processed, not necessarily HP applied synchronously when armor is pending. Attack's damage_wait checkpoint and AOE's saved damage result prevent premature follow-ups or cursor movement. Armor's globally increasing decision IDs are shared across target/damage opportunities. Decline commits prepared damage once; successful Chainmail self-discard cancels it before applying HP. Transfer/reentry/global-Dying guards cover confirmation, continuation and phase entry; stale protection cannot advance a phase past newly lethal damage.

EffectResolver binds back to its pipeline with WeakRef. Its existing deal_damage accepts an already-resolved amount: controller-bound calls now pass through armor checks without repeating normal damage modifiers. Pipeline alone calls the private _apply_damage HP primitive. Source 0 is supported for unknown GENERIC damage, preserving old unknown-source reward semantics; normal Attack/AOE/weapon damage still requires its real source. Standalone/unbound resolver remains a low-level legacy primitive; production actions construct/bind the pipeline in ActionExecutor. This is controlled single pending damage, not a general skill trigger/recursive damage framework.

New APIs: CombatController.equip_armor(actor_id, card_id), get_pending_armor(), resolve_armor(owner_id, decision_id, activate). Dying has presentation/command priority; prepared-damage armor preempts target armor/response, then resumes the original Attack/AOE/weapon flow. Optional armor UI reuses the inline own-card presenter, displays the equipped card with Đồng ý/Bỏ qua and logs judgments/prevention; no direct HP/life/phase/window writes. Player panels show compact armor names, with full type/description in tooltips to preserve seat bounds.

Multi-card mandatory discard follow-up (2026-11-07): CombatController/ActionExecutor expose discard_cards_for_turn(player_id, card_ids: Array[int]); the existing singular discard_for_turn remains an adapter. ActionValidator.validate_turn_discards checks every selected hand card, ownership, uniqueness, phase/windows and a count in 1..get_required_discards before one CardZoneManager batch. Controller resumes auto-phases once after successful transfer; partial batches remain waiting. TurnManager now blocks transitions during any zone transfer so synchronous discard notifications cannot advance or draw before the batch finishes. Prototype keeps a separate discard draft with multi-card lift/dimming/count/cancel, preserving owned choices across a Dying interruption. Mandatory DISCARD double-click toggles selection rather than submitting a partial cost. Font sizes are raised slightly from the previous compact pass (body 15, seats/log 13, compact labels at least 12); native window/canvas scaling remains.

Compact Full HD follow-up (2026-11-07): prototype/main menu use smaller native text and synchronize content_scale_size to Window.size on size_changed, with an equality guard to avoid resize feedback loops. They keep an existing larger window when scenes change, and only enlarge an undersized initial window to the former 1280x720 baseline. This supersedes the earlier fixed 1280x720 canvas description. The prototype conditionally reads/renders weapon range only for equipped weapons and hides absent defense slots; no rule/slot state changes. Direction/deal tutorial text and redundant manual-control hints are removed from presentation. FullHD smoke checks 2–6 seats at 1920x1080, empty/equipped/removed weapon display, compact font sizes and actual pointer coordinates.

Inline-hand presentation follow-up (2026-11-07): PlayablePrototype reuses its existing choice content/handlers, reparenting them into InlineCardChoice below the table for Support, response, AOE, rescue and Slingshot cost decisions. The ordinary hand column is hidden during this presentation, so the player sees one actionable card area. Confirmation actions appear above the cards. Opponent card choices still use CardChoiceOverlay, preserving their visibility rules. is_choice_visible reports either presentation; _hide_choice restores the normal hand on resolution/reset/game end. Game rules and command validation are unchanged. Invalid own response/rescue cards are rendered disabled without selection handlers. TablePrompt/TableNotice are in the table-to-hand strip; compact instructions and the adjusted center-preview anchor preserve 1280x720 bounds and opponent-seat separation.

Deck.shuffle_count remains the count of raw shuffle calls. New Deck.reshuffle_count increments only after a successful discard-pile recycle; initial setup/manual shuffle/no-op recycle leave it unchanged. The prototype's Xào lại display reads this count. This changes observable bookkeeping, not shuffle order, deck composition or card identity.

Active weapons follow-up (2026-11-07): ActionExecutor delegates Attack declaration/response to AttackResolution; AttackContext retains source, paid card ID, seat-ordered target list, weapon/effect snapshot, base damage, cursor, stage and per-target outcomes. Existing use_attack/respond_to_attack/has_pending_response signatures remain. pending_attack is a presentation snapshot of the current response, no longer mutable engine storage. The root stays busy during weapon decisions and damage-induced Dying, even when the response snapshot is empty. TurnManager checks this root lock, including direct calls. This is a bounded 16-step pump for current single-weapon effects and non-recursive secondary damage, not a general recursive trigger bus.

Checkpoints: declaration -> response -> pre-modifier replacement choice -> DamagePipeline -> positive-damage follow-up -> next target -> resolved. Dying suspends before further work. Decision views contain an ID, chooser/source/primary/weapon IDs, eligible cards/targets and descriptor parameters; returned views are deep copies. Commands validate chooser, ID, live weapon lifetime, ownership/zone/count, distance and pending Dying before atomic payment. Synchronous notification reentry is guarded. Equipment changes permanently invalidate uncommitted effects for that root; declared targets survive. Confirmed Slingshot costs are retained if secondary damage is prevented.

DamagePipeline.process_damage_result adds processed/applied_amount/source_kind evidence; process_damage retains its bool API. Cancelled/zero damage does not trigger follow-ups. WEAPON_EFFECT is appended to SourceKind, preserving previous enum values. Secondary damage reuses pipeline/Dying without another Attack response or weapon trigger. DistanceCalculator accepts optional authoritative seat_order; validator call sites supply it, preserving the three-argument API. GameState.validate_state accepts negative DYING HP and rejects nonpositive ALIVE/positive DYING; the old validator fixture now eliminates its victim via lifecycle APIs.

New coordinator APIs: use_attack_targets(actor_id, target_ids: Array[int], card_id), get_attack_target_limit(actor_id), get_pending_weapon(), resolve_weapon(actor_id, decision_id, activate, card_ids: Array[int]=[], target_id=0). Single-target use_attack is retained. Prototype multi-selection/weapon modal use these APIs; costs, hidden hand cards and face-up equipment remain presentation drafts until confirmation. Dying replaces the modal and restores a fresh view afterwards.

Main-menu/Exchange follow-up (2026-11-07): `scenes/main_menu.tscn` / `MainMenu` is now the F5 startup scene, configured in project.godot. Its Chơi action changes to the existing prototype scene; F6 still works directly. Catalog loading uses CardDatabase without creating CardInstances or a match. MainMenu uses the same 1280x720 canvas scaling as the prototype so pointer coordinates and layout remain consistent. Catalog navigation sits outside the scrolling entries; descriptions wrap to available width.

SupportToolResolution validates optional unique `discard_zones` (hand/equipment, default hand for compatibility), copies them into its pending view and resolves each submitted card ID to its actual owned zone before one atomic CardZoneManager batch. ActionValidator counts only eligible zones and drawable hand cards for mandatory-discard preflight. Exchange specifies both zones. Equipment departure uses the existing synchronous modifier lifecycle; UI renders grouped face-up choices and includes equipment names in its completion log. Public support command signatures remain unchanged.

Screenshot-guided presentation follow-up: PlayablePrototype uses a left table/hand column plus MatchSidebar (New Table, deck information, Event Log, HumanInfoPanel). Opponent seats remain keyed to engine IDs. PlayedCardArea renders a noninteractive preview of the last card submitted by a successful UI action, without relocating/cloning any CardInstance. Optional arguments on the existing _record helper carry that card and participant IDs; old callers remain compatible. A rejected command updates feedback without logging or replacing the preview. Successful records have no technical OK suffix or auto-phase status spam. New matches reset the presentation cache.

Elimination/log follow-up: EffectResolver.deal_damage accepts an optional source ID; DamagePipeline forwards its actual source. GameState records lethal credit and emits damage/healing/elimination/reward signals for presentation. DyingManager clears credit on full rescue; finalization batches every victim zone to discard, detaches equipment, eliminates, awards the confirmed temporary two-card reward through GameState.draw_card, then checks the existing survivor win. It keeps the Dying guard and a reentry flag throughout cleanup/reward. Unknown/self/eliminated sources do not receive rewards. CardZoneManager preserves the old names-only signal and exposes a deep-copied last-discard owner grouping for UI logs. No UI HP/life/zone mutation is added.

Setup/input/defense follow-up: `MatchSetupMenu` is a presentation-only Control emitting start_requested(count)/cancel_requested. PlayablePrototype validates 2–6 seats and opening-deal capacity before replacing the old session, rebuilds only seat controls, and names engine players P1…Pn with ascending authoritative seat IDs. P1 remains in HumanInfoPanel; other seats adapt to count, with two side rows for 5–6. No match is constructed before CreateMatch; cancelling setup retains state/windows. New Table remains usable after a winner.

Card gui_input handles a left-button double-click and routes to the existing selection + confirm methods. The old button is disabled for the remainder of that gesture so its release cannot submit again; normal selection can rebuild hand controls. Target requirements, engine validation, response contexts and single-click behavior are unchanged. Hand and hidden/face-up modal cards share this behavior.

`CardDefinition.EQUIPMENT_SLOTS` recognizes weapon/armor, with `has_equipment_slot()` for zone occupancy checks. CardZoneManager enforces one card per recognized slot using its existing batch preflight. EquipmentSystem.get_equipment is the shared read query; get_weapon remains compatible and get_defense queries armor, also exposed by CombatController. Weapon RuleModifier registration remains weapon-only; armor hooks are handled by ArmorEffectRegistry. CardDatabase accepts empty effects only for inert armor metadata, rejects inconsistent slots/subcategories and validates the four supported armor descriptors. Current armor actions/effects supersede the earlier metadata-only foundation.

Prototype presentation: `HumanInfoPanel` owns Seat1 separately from `BotTable` (Seats2…N, up to 6 total participants); this layout does not change engine turn order. The active actor's hand remains shared. Card buttons use a 132 px slot around their 120 px face, reserving 12 px for selection lift without container reflow. Hand/modal selections share the visual helper. Draft feedback stays in the feedback label; confirmed-action/result logging is unchanged.

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
- AOE v0.1: `CombatController.use_aoe(actor_id, card_id)`, `respond_to_aoe(target_id, response_card_id=0) -> ActionResult`; 0 explicitly declines. Read APIs: `has_pending_aoe()`, `get_pending_aoe() -> Dictionary` (deep copy), `get_aoe_response_cards(target_id) -> Array[CardInstance]`. Direct executor commands retain the same guards.
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

AOE flow: validate own PLAY/card/schema -> capture counterclockwise targets and pay once -> explicit target response -> discard response OR DamagePipeline(AOE_TOOL) -> save next cursor -> resolve any Dying first -> resume next eligible target -> clear queue -> return to existing turn continuation. No phase advancement or second target response runs through an unresolved Dying window.
- AOE v0.1 extends the existing transition guard: Dying first, then active Attack/AOE. `ActionValidator.validate_aoe_use` checks own PLAY, life state, ownership, phase holds and effect schema without distance/Attack-count checks. All normal actions already using this guard now stop during AOE, including direct TurnManager calls. The existing Attack-only `has_pending_response()` contract is preserved; AOE has a separate query.
- `ActionExecutor` owns `AoeResolution` alongside its existing pipeline/DyingManager. The new class holds a single committed tool snapshot and a bounded forward-only seat queue, with no name-specific branches or recursive effect execution. `begin` captures eligible seat IDs after the source, installs the pending lock before one card payment, and rejects reentry during synchronous notifications. `respond` revalidates current target/hand/type, discards a response OR applies pipeline damage, advances the cursor once, discovers Dying, then attempts `resume`. No weapon handler or normal Attack executor is invoked.
- `resume` stops while Dying remains active, skips eliminated queued targets and clears only after the queue and final Dying window finish. At most one scan of the finite captured list is possible; no response is automated. Controller continuation reaches this through the existing guard before auto-phase. Partial rescue keeps the cursor suspended. Match-finished clears both attack and AOE pending state. Source elimination does not recreate or cancel a committed tool; existing turn logic skips the invalid actor only after resolution finishes.
- JSON schema: a single-effect tool with `effect_id=aoe_response_damage`, parameters `{target_scope: "all_other_players", response_effect: "block_attack" | "deal_attack", damage: positive finite integer}`. CardDatabase and runtime validation share `AoeResolution.valid_parameters`; unsupported scope/response/malformed amounts reject without partial loading/payment. Card definitions are separated from the runtime captured source/card name/targets/index/current-target state.
- `DamageContext.SourceKind` distinguishes GENERIC, ATTACK and AOE_TOOL. `DamagePipeline.process_damage` accepts an optional fourth source-kind argument (existing three-argument calls remain compatible); normal Attack passes ATTACK and AOE passes AOE_TOOL. `DamageModifier` optionally filters `source_kinds` before owner/role matching, preserving source-priority ordering. Attack-only weapon modifiers must opt into ATTACK; common defenses may leave the filter empty. The four unimplemented weapon abilities remain unimplemented.
- Prototype AOE modal reads the controller snapshot and legal response cards; it cannot write the queue, HP, phase or pending attack. Empty-hand targets still receive an explicit decline button. Dying replaces the modal, and restoration queries current engine state. This finite AOE continuation does not implement the general F2 nested-decision/weapon stack.
- Latest UI targeting/zone grouping: `_is_target_available()` reuses validate_attack/validate_tool_use for the selected card and current actor. Both seat disabling and the selection handler use it; selected stale targets clear on refresh and Confirm requires a valid target. Tool choices render per-zone containers while preserving card ID + source-zone metadata, so selection works across nested groups and executor revalidation remains authoritative. Shared faces are 88x120 with uppercase display names; JSON is unchanged.
- Compact-log/deck-info follow-up: UI log entries use one newline and card names without card-description/rank/suit text. Card faces retain only the top rank/suit and centered title. DeckInfoPanel beside the action row reads draw/discard counts plus new Deck.shuffle_count, which increments at each existing shuffle() call without changing RNG or recycling behavior. This includes the opening shuffle; no new gameplay decision or rule was introduced.
- Latest UI-only redesign: the Debug sidebar and its selector/draw/action controls are removed. EventLogPanel sits in the top header; the table uses anchored Control seats and the lower hand still follows the current actor for manual Bot play. Portrait hand/response/rescue/equipment card faces are built from native Buttons/Labels; filled/empty hearts display health with a numeric negative deficit. No engine/card-data/scene-startup behavior changes.
- PlayablePrototype._can_select_card queries existing validators for usable actions (any valid target for Attack/tools, valid self-heal/equip, or required turn discard). It disables unavailable hand cards and rejects synthetic selection of them. Response/rescue modal cards are a separate input context. Eliminated seats are disabled/dimmed, cleared as selected targets and rejected by the target-selection handler. UI presentation never replaces final executor validation.
- Basic equipment follow-up is implemented: `CombatController.equip_weapon` -> `ActionExecutor.equip_weapon` -> `ActionValidator.validate_equip_weapon` -> new `EquipmentSystem.commit_equip`. CardDefinition exposes the user's flat `equipment_slot` / `range` metadata; CardDatabase validates weapon slot and positive integral range. EquipmentSystem queries the existing equipment zone for the weapon (no duplicate card storage), registers per-owner/instance range and remove_attack_limit RuleModifiers, and synchronizes on equipment changes. No active weapon trigger framework has been added.
- `CardZoneManager.transfer_cards(moves)` preflights a shadow state before committing all touched arrays, rejects duplicate weapon-slot occupancy, then emits `equipment_changed` and `cards_discarded(PackedStringArray names)` synchronously. The original transfer_card signature remains a single-move adapter. Reentrant transfers during notification are rejected. Equip/replace and Hủy/Cướp use batches; failed batches change neither cards nor modifiers and emit no discard log.
- Last-survivor lifecycle: GameState owns match_over/winner_id and emits match_finished once after update_match_result. DyingManager checks after rescue/finalization; controller checks startup. Any DYING blocks a win. TurnManager phase/action guards, executor responses, damage primitives and GameState draws stop after match end. Executor clears stale pending_attack on match_finished; controller does not resume phases after a finalization ends the match. UI announces winner, disables gameplay and retains New Table.
- Dying priority follow-up: `TurnManager.get_dying_block_reason()` runs before pending-Attack checks and also gates `ActionExecutor.respond_to_attack()`. `DyingManager.ensure_pending_dying()` adopts an existing DYING participant if there is no registered window, so direct resolver/pipeline damage is discovered at the next guard/status/controller rescue/finalize boundary. It preserves the current window; it is not a centralized damage event dispatcher or a new simultaneous-damage ordering contract.
- Finalizing an eliminated pending-attack target completes that stale response through the executor without consuming Dodge. Otherwise the interrupted attack remains pending and resumes after rescue/elimination. The UI uses the shared modal for Dying before response/tool pickers, with rescuer/healing-card selection and explicit no-rescue elimination. Compact hand cards render name plus top rank/suit; descriptions come from cards.json only for tooltips, not selection logs.
- Paid-rescue migration: `CombatController.rescue_player(rescuer_id, target_id, card_id=0)` now takes an **owned healing-card instance ID**, replacing the former free heal-amount argument. Missing/default card ID fails. `ActionExecutor.use_rescue` checks the active Dying target, delegates eligibility/ownership/effect/amount checks to ActionValidator, pays one card via GameState, and invokes `DyingManager.rescue_player(..., heal_amount)` as the low-level HP/state operation; failed resolution restores the card. All gameplay/UI calls use the paid executor path. The low-level manager signature is retained for internal effect resolution.
- EffectResolver preserves negative damage HP and enters DYING at HP <= 0. DyingManager permits self-rescue by the current DYING player and rescue by another living player. Partial recovery through negative HP/zero retains the current window; recovery above zero closes it. No normal phase resumes while any Dying window remains.
- Healing follow-up: `CombatController.use_heal(actor_id, card_id)` delegates to `ActionExecutor.use_heal` and `ActionValidator.validate_heal`. Validation requires the current living wounded actor in PLAY, an owned single-effect healing card, a positive integral JSON amount and no pending windows/effect holds. Executor pays via GameState, calls the existing EffectResolver.restore_hp, and restores the card if healing fails. UI never assigns HP. This is self-healing, not Dying rescue.
- Prototype hand/confirmation follow-up: the lower hand renders the current actor with manual Bot labeling. Local selection is cancellable; shared confirmation dispatches to validated Attack/Heal/Equip/Tool/turn-discard APIs. The sidebar Debug controls have been removed by the later UI request; target Dodge/tool/rescue modal pickers remain. No engine turn/phase or default-scene changes.
**Opening/interaction follow-up:** the user reconfirmed named order `[1, 2, 3, 4]` and four opening cards. The latest correction requires normal DRAW on every turn, including the first; it supersedes the earlier first-DRAW skip. The original v0.5 start_game API remains compatible.
- `GameState.deal_initial_hands(count, order) -> ActionResult` preflights a pristine table, unique valid participants, conservation and sufficient draw cards before round-robin dealing through draw_card. It rejects duplicate deals and shortages without a partial opening hand.
- `CombatController.start_match(initial_cards=4)` deals once, then starts normal progression with 2-card DRAW even on the first turn. The obsolete skip_first_draw flag/first-draw bookkeeping are removed; public method signatures and the Phase enum are unchanged. Existing `start_game()` callers retain their no-deal behavior.
- `TurnManager.get_phase_display_name(phase)` maps all six enums to Vietnamese labels shared by UI/turn logging. Player-facing phase guards/status/card hints also use Vietnamese; gameplay continues to compare enum values rather than translated strings.
- `ActionValidator.validate_tool_use/validate_tool_choice` checks source ownership, active ALIVE actor, PLAY, all pending windows/effect holds, different live target, one-card effect, JSON target zones and optional range, and victim ownership. `get_tool_effect` reads the owned source card's existing JSON effect.
- `CombatController.use_tool` delegates to ActionExecutor. Victim transfer and tool payment commit in a single CardZoneManager batch; no partial movement on failure. No HP/phase/window state is assigned from UI.
- UI card-choice overlays are modal input surfaces. The response overlay belongs to the actual pending target, not the actor selected in Debug. It lists their Dodge cards and requires selection plus confirm, or explicit pass. Tool overlays reveal equipment names/ranks/suits/tooltips; hand cards remain hidden. Tool selection is cancellable and revalidated at confirmation. Opening a tool picker consumes no card and creates no new gameplay response window. UI logs card names from the discard signal rather than predicting discarded cards from button actions.
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
- PlayablePrototype reads state and uses coordinator APIs. End Turn and card confirmation operate for the active Human or manually controlled Bot; there is no Debug area or forced-draw button in the current UI. It never assigns HP/life state/window/phase directly. Existing scene paths remain available; the later menu follow-up changes F5 startup to MainMenu.

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
