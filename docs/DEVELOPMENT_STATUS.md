# Tactics — Development Status

## Fixed equipment positions and per-item hover — 2026-11-07

- Equipment cells now keep fixed geometry in the player's frame. Empty cells reserve their slot but draw no border/text and ignore mouse input; equipping/removal only changes that slot's opacity/content. Weapon, armor and left/right accessories no longer slide when another slot changes, and a single accessory does not stretch across the row. Special remains unoccupied/invisible with no new gameplay slot.
- Hover targets belong to the specific occupied equipment cell. Tooltips contain that instance's card name/rank/suit and description, plus weapon range, without other equipment or player-summary information. Removed frame-wide/name/HP tooltips. Occupied cells use MOUSE_FILTER_PASS so target clicks still reach the existing SeatN Button; empty and non-equipment children ignore input. Slot queries expose only occupied content. Hover remains available on owned equipment even while the owner cannot be selected as a target.
- Tidied row geometry with a constant 20 px equipment row, simpler rank-column separators, subtle rounded corners and tighter body/health spacing. No font reduction, gameplay/API/state or card/deck changes.
- Updated scripts/dev/player_frame.gd, scripts/dev/playable_prototype.gd, scripts/test/player_frame_ui_smoke.gd and docs/GDD.md, ARCHITECTURE.md/this status. Smoke assertions now preserve/check fixed slot rectangles across removals, independent tooltip contents and real hover hits for every slot, blank info tooltips, transparent empty slots, left/right accessory placement, hover under a disabled owner frame and target clicks through an occupied equipment cell as well as the name label. Earlier collapse/stretch assertions were deliberately replaced to match the new design.
- **Executed validation:** Godot 4.7.2 with warnings-as-errors in an isolated copy: **22/22 regression suites and 14/14 UI smoke tests PASS**. All fifteen runner completion logs inspected; no script/parse errors, GDScript warnings, load failures or leak diagnostics. Source/data match the tested copy; git diff --check passed. Native OpenGL captures at 1280x720 and 1920x1080 were rendered/inspected, including a real per-armor tooltip with no player summary. Known sandbox certificate/editor-settings diagnostics remain environmental.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-fixed-slots-94671a78148c459c90622755070812d4`, regression_runner.gd-final.log and fourteen smoke *-final.log files; capture-final.log, player-frame-1280.png/player-frame-1920.png and matching *-tooltip.png captures. Commands use `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 900` after import; capture runs player_frame_ui_smoke.gd with `--rendering-method gl_compatibility -- --capture`. No commit/push.

## Show only occupied player-frame equipment slots — 2026-11-07

- PlayerFrame now hides empty weapon/armor/accessory cells. Equipped slots appear on refresh and disappear immediately after removal. With one accessory only that cell is shown and fills the accessory row; with neither accessory the entire row is hidden. Special stays hidden because no supported special equipment exists. Hidden placeholders are also excluded from frame summaries/tooltips. Frame header, body, health and validated target behavior are unchanged.
- Updated scripts/dev/player_frame.gd, scripts/dev/playable_prototype.gd (removed obsolete special-placeholder tooltip), scripts/test/player_frame_ui_smoke.gd and docs/GDD.md, ARCHITECTURE.md/this status. Extended smoke verifies all-empty frames, slot removal, remaining single-accessory expansion, empty-row collapse and re-equipping; existing occupied rank/suit/color, pointer and lifecycle assertions remain. No gameplay or card/deck data changes.
- **Executed validation:** Godot 4.7.2 with warnings-as-errors in an isolated copy: **22/22 regression suites and 14/14 UI smoke tests PASS**. All completion markers inspected; no script/parse errors, GDScript warnings, load failures or leak diagnostics. Workspace scripts/data match the tested copy; git diff --check passed. Known sandbox certificate/editor-settings diagnostics remain environmental. Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-occupied-slots-419a5f63f7134a3a808f5f2c020317d4`, regression_runner.gd-final.log and fourteen smoke *-final.log files. Commands use `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 900` after editor import. No commit/push.

## Wireframe player panels — 2026-11-07

- Added PlayerFrame, a presentation-only Button matching the designer's layout: player-name header, portrait-reserved body with life state/hand count and effective distance, lower-right health cell, weapon and armor rows, two accessory cells side-by-side and a reserved special row. Actual equipped CardInstance rank/suit appear in separate leading cells (7♥, J♣); red suits use red text and black suits use light ink on the dark theme. Weapon range precedes its name. Living HP retains hearts; DYING/nonpositive HP explicitly shows the numeric deficit. Long captions ellipsize; parent tooltips retain all equipment names/rank/suit/descriptions.
- Empty equipment rows now remain as muted placeholders according to the new wireframe; unarmed range stays hidden. Special is an inert labelled placeholder because the engine has no such slot: no equipment enum, rule or action was added. All frame children ignore mouse input, so the existing SeatN Button still receives target clicks. Current-turn highlighting, legal-target disabling, eliminated dimming, Human sidebar separation and existing gameplay APIs are preserved. Opponent dimensions respond to board height to fit 2–6 seats at 1280x720/1920x1080.
- Added scripts/dev/player_frame.gd and scripts/test/player_frame_ui_smoke.gd (+ UIDs). Updated scripts/dev/playable_prototype.gd; existing playable_prototype/full_hd/menu_interaction/accessory/armor UI smokes now query rendered frame labels instead of removed multiline Button.text, retaining gameplay assertions; docs/GDD.md, ARCHITECTURE.md and this status. No scene, card/deck JSON, engine state/rules or startup changes.
- New smoke checks cell order/bounds, lower-right HP alignment, accessory row alignment, real rank/suit/color for every occupied slot, slot removal, explicit negative HP, reserved-special non-gameplay state, all child mouse filters and actual target click through the name label. It covers both resolutions and 2–6 player seating. OpenGL captures of equipped frames at both resolutions were rendered and inspected.
- This new lifecycle check exposed an existing inline-choice layout issue: reparenting a long Dying title into its initially zero-width hidden host made the label wrap at one pixel, temporarily raising the page minimum above the viewport and leaving inflated offsets after resizing/new table. _present_choice now primes host/content/title widths from the actual page width before showing inline controls. The test retains the Dying -> resize -> new-table sequence and viewport-bound assertions; no assertion was removed to hide the failure. Earlier failed geometry/capture runs are not final pass evidence.
- **Executed validation:** Godot 4.7.2 with warnings-as-errors in an isolated copy: **22/22 regression suites and 14/14 UI smoke tests PASS** (13 prior + Player Frame). All fifteen final runner logs/completion markers inspected; no script/parse errors, GDScript warnings, load failures or leak diagnostics. Workspace scripts/data match the tested copy; git diff --check passed. Known certificate-store/editor-settings sandbox diagnostics remain environmental.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-player-frame-f988c5c07eb848d78f1fdad244de3802`, regression_runner.gd-verified.log and fourteen smoke *-verified.log files; capture-verified.log and player-frame-1280.png/player-frame-1920.png contain the native OpenGL verification. Commands: import with `--headless --path <copy> --editor --import --quit`, runner/smokes with `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 900`; capture uses `--rendering-method gl_compatibility --script res://scripts/test/player_frame_ui_smoke.gd -- --capture`. Existing workspace data/gameplay edits are retained. No commit/push.

## Consolidate all equipment into one group — 2026-11-07

- Merged weapons (5), armor (4) and accessories (2) into data/cards/equipment.json (11 definitions), preserving category=equipment and all slot/subcategory/effect metadata. Removed weapons.json, armor.json and accessories.json and replaced their manifest entries with equipment.json. Official groups are now basic (3), tools (7) and equipment (11).
- Verified **21 before / 21 after**, with the complete ordered definition array deeply identical, and standard.json byte-identical to the task-start snapshot. No GDScript, schema, gameplay handler, UI or CardInstance creation change; registry/catalog order is retained.
- Changed data/cards_manifest.json, created data/cards/equipment.json and removed its three predecessor group files; updated CARD_DATA_GUIDE.md, GDD.md, ARCHITECTURE.md and this status. Earlier five/seven-group records below are historical.
- **Executed validation:** Godot 4.7.2 with warnings-as-errors in an isolated copy: **22/22 regression suites and 13/13 UI smoke tests PASS**, all completion markers inspected, no script/parse errors, GDScript warnings, load failures or leak diagnostics. Source/data match the tested copy; git diff --check passed. Known sandbox certificate/editor-settings diagnostics remain environmental. Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-equipment-merge-2VHdXR`; regression_runner.gd-final.log plus thirteen smoke *-final.log files; definitions-before.json and standard-before.json retain task-start snapshots. Commands use `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 900` after editor import. No commit/push.

## Consolidate all tools into one group — 2026-11-07

- Merged the two AOE and three support definitions into tools.json alongside Discard/Steal. Tools now contains seven cards: discard, steal, gatling, indian, draw_2, exchange, saloon, all retaining category=tool and their original subcategory/effect descriptors. Removed aoe.json/support.json and their manifest entries. Five groups remain: basic, tools, weapons, armor, accessories.
- Verified **21 before / 21 after** with identical ID sets and deep definition content; standard.json is byte-identical to the task-start snapshot. No GDScript, effect handler, schema, gameplay rule or deck-copy change. The registry/catalog now keeps all seven tools together before weapons according to manifest order; turn/response resolution order is unchanged.
- Updated data/cards/tools.json, data/cards_manifest.json; removed data/cards/aoe.json and support.json; updated CARD_DATA_GUIDE.md, GDD.md, ARCHITECTURE.md and this status. The earlier seven-group migration record below is historical.
- **Executed validation:** Godot 4.7.2, warnings-as-errors in an isolated copy: **22/22 regression suites and 13/13 UI smoke tests PASS**, all completion markers inspected, no script/parse errors, GDScript warnings, load failures or leak diagnostics. Source/data match the tested copy; git diff --check passed. Known sandbox certificate/editor-settings diagnostics remain environmental. Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-tools-merge-BdIdul`, regression_runner.gd-final.log and thirteen smoke *-final.log files; snapshots definitions-before.json and standard-before.json. Commands use `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 900` after editor import. No commit or push.

## Grouped card definitions and atomic manifest loader — 2026-11-07

- Replaced the monolithic data/cards.json with seven JSON objects rooted at cards: basic (3), tools (2), weapons (5), aoe (2), support (3), armor (4), accessories (2). Classification follows actual effect/slot behavior, not category alone. data/cards_manifest.json is the only official runtime entry point. Its file order retains the original definition iteration/catalog order; no definition/effect/parameter was changed and no legacy data copy/fallback is shipped.
- CardDatabase.DEFAULT_MANIFEST_PATH centralizes the path. load_from_file supports an ordered manifest or a standalone group for existing schema fixtures/tooling. Public query signatures/return-copy behavior are unchanged. All files validate into one temporary registry and publish only on total success. Under the existing load contract, failed loads leave an empty registry, not stale/partial entries; errors clear on the next attempt. Missing files, malformed JSON/roots/schema, empty/invalid manifests, repeated canonical source paths and duplicate IDs fail the complete load. Errors name the source path/card index; duplicate IDs identify both origins. Invalid effect_id types now stop validation before unsafe string comparisons, making invalid schema fail cleanly rather than raising a runtime error.
- Migrated every production/test/smoke consumer to the shared default manifest path. CardDatabaseTest independently reads the manifest/group JSON and compares full definitions with the registry. Added CardManifestTest covering ordered merge/reload/copy APIs, missing/invalid manifest and group data, ID provenance, same-file/cross-file duplicates, canonical path aliases, late-file failures, no stale entries, repair/reload, direct-group compatibility and preservation of a pre-existing CardInstance.
- One-time migration proof: **21 before / 21 after**, identical ID set, definition order and deep content including all unknown/optional fields. Serialized definition-array SHA256 before/after: `6f9687575a518e65b476a83745b60f4be0b90695880efbd519c093dd176f1b77`. standard.json is byte-identical to the snapshot taken at task start (SHA256 `9fbcef86e86c8fa86ac241d37df66c7c46baede949e6f5918a3be2bf1186324a`). CardInstance creation, deck copies/order, gameplay handlers/resolution and presentation are untouched.
- Files: created data/cards_manifest.json, data/cards/{basic,tools,weapons,aoe,support,armor,accessories}.json, scripts/test/card_manifest_test.gd (+ UID), docs/CARD_DATA_GUIDE.md; removed data/cards.json. Updated scripts/cards/card_database.gd; runtime scripts/dev/main_menu.gd and playable_prototype.gd (load path only); tests accessory_system, action_executor, action_validator, aoe_system, armor_system, card_database, card_model, card_zone, combat_system, damage_registry, deck, defense_foundation, dying_system, elimination_lifecycle, game_state, support_tools, turn_manager and inline_choices_ui/main_menu smokes; docs/GDD.md, ARCHITECTURE.md and this status. Existing test assertions/gameplay coverage are preserved; the database source-reading assertion now aggregates groups instead of the removed monolith.
- Authoring guide: [CARD_DATA_GUIDE.md](CARD_DATA_GUIDE.md) documents group selection, manifest order, unique IDs, atomic failure/reload semantics, supported legacy fixture input and the separate approval required for deck-copy changes. Historical cards.json mentions in older handoff/status entries refer to the prior storage layout.
- **Executed validation:** Godot 4.7.2.stable.official.ed1daf0bf, warnings-as-errors enabled in an isolated copy: **22/22 regression suites and 13/13 UI smoke tests PASS**. Inspected all fourteen final logs and suite completion markers: no script/parse errors, GDScript warnings, load failures or leak diagnostics. All workspace GDScript/data files match the tested copy; no live runtime/test/tooling reference to the removed monolith remains. git diff --check passed. Known sandbox certificate-store/editor-settings diagnostics remain environmental.
- Evidence/snapshot directory: `C:/Users/Admin/AppData/Local/Temp/tactics-card-manifest-rm20zh`; cards-before.json, standard-before.json and migration-verification.json record the one-time comparison outside the shipped repository. Final logs: regression_runner.gd-final.log and thirteen smoke *-final.log files. Commands: `--headless --path <copy> --editor --import --quit`, then `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 900`. New CardManifestTest is discovered by the existing regression runner. No commit/push or subsequent milestone.

## Sequential optional-target UI and approved data repair — 2026-11-07

- Main board clicks now draft one initial target. Confirming it asks whether to add another target only if the engine allows more and another legal candidate exists. Agreement opens a separate next-target picker, excluding the confirmed target and invalid candidates; confirm commits the completed list. Không thêm commits the confirmed targets, while Huỷ dùng bài cancels without card loss, Attack count or log entries. Final engine validation rejects stale equipment/target drafts without payment. No eligible extra target means no empty prompt.
- Slingshot's actual post-hit opportunity asks whether to choose a secondary target before showing cost cards and targets. Decline retains the hand cost and causes no secondary damage. Dying still precedes this opportunity. Attack payment/count, per-target responses, seat-cycle resolution, range rules and AOE remain unchanged; no engine/API changes.
- Found a pre-existing data blocker in the latest workspace: 27 card entries included six duplicate equipment IDs; the latest accessory definitions used unsupported delta/minimum parameters. The designer explicitly approved consolidating to 21 unique definitions, keeping the latest Vietnamese names (Ống ngắm/Ngựa), and normalizing to amount. Kept latest descriptors/descriptions, preserved unique cards and left standard.json untouched. Accessory UI assertions now use JSON display names rather than hardcoded English labels.
- Modified this follow-up: scripts/dev/playable_prototype.gd; scripts/test/weapon_ui_smoke.gd, accessory_ui_smoke.gd; data/cards.json; docs/GDD.md, ARCHITECTURE.md and DEVELOPMENT_STATUS.md. Prior workspace changes are retained; no commit/push.
- **Executed validation:** Godot 4.7.2 with warnings-as-errors, using the repaired workspace data in an isolated copy: **21/21 regression suites and 13/13 UI smoke tests PASS**. All fourteen final completion logs inspected: no script/parse errors, GDScript warnings, load failures or leak diagnostics. Source/data compare against the tested copy found no mismatches; git diff --check passed. Known certificate-store/editor-settings sandbox diagnostics remain environmental. Extended Weapon UI smoke covers initial-target replacement, offer before target picker, free drafts/cancellation, decline to a single target, one-card/count payment, unchanged seat-cycle response order, stale weapon validation, no eligible extra target and Slingshot acceptance/decline.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-target-prompt-5aab8637a0984a9095ac942a6f5ab60e`, `regression_runner.gd-final.log` plus thirteen smoke `*-final.log` files. Commands: import `--headless --path <copy> --editor --import --quit`; runner/smokes `--headless --path <copy> --script res://scripts/test/<script>.gd --quit-after 800`. Earlier valid-fixture runs are not used as evidence for the previously invalid workspace data.

## Accessory System v0.1 — 2026-11-07

- Added Scope (`offensive_accessory`, outgoing -1) and Mustang (`defensive_accessory`, incoming +1) definitions with the shared `modify_distance` effect. CardDatabase checks accessory slot/subcategory, exactly one supported descriptor, matching direction and numeric amount (rejects bool/fraction/invalid direction or slot). No name/ID-based effect dispatch.
- Extended recognized equipment slots and validator/executor/controller commands; existing EquipmentSystem/CardZoneManager atomically replace same-slot accessories and discard the old instance once. Different slots coexist with weapon/armor. EquipmentSystem also rejects a direct commit with a mismatched card/slot. Existing card transfers provide removal, destruction, theft and elimination cleanup; no voluntary free unequip rule is added.
- Central DistanceCalculator now returns `max(1, base + outgoing + incoming)` for distinct valid endpoints. Existing self=0/invalid=-1, authoritative seat order, DYING inclusion and ELIMINATED exclusion are preserved. AccessoryEffects reads only live equipment; no cached/registered distance modifiers can stack or survive departure. Attack, limited tools and Slingshot inherit this API; weapon ranges, AOE/damage/response rules are unchanged.
- UI supports equipping both accessories from hand, displays occupied Công/Thủ slots and effective distance on target seats during targeted PLAY drafts. Invalid targets stay disabled. Catalog labels accessory types. Empty slots stay hidden according to existing presentation requirements.
- Added AccessorySystemTest and accessory_ui_smoke. Coverage: individual/combined directions, clamp, reverse/self/invalid endpoints, non-storage seat order, repeated equipment notifications, both slot replacements, removal/theft/destruction, Attack/Steal/Slingshot ranges, pending restrictions, DYING/elimination and original CardInstance integrity. UI sends actual card/confirm/target clicks, checks slot labels, replacement discard, target disabling and fully equipped opponent bounds.
- **Executed validation:** Godot 4.7.2.stable.official.ed1daf0bf, warnings-as-errors enabled in an isolated copy: **21/21 regression suites PASS and 13/13 UI smoke tests PASS**. Inspected all suite completion markers and fourteen final `*-verified.log` files: no script/parse errors, GDScript warnings, load failures or leak diagnostics. New malformed-input cases exposed typed-array Nil lookup and bool/String comparison errors during development; explicit type validation corrected both before final verification. Existing tests were preserved. Known certificate-store/editor-settings sandbox diagnostics remain environmental. `git diff --check` passed.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-accessories-3acd75563b124b95b811ce7f5ff3d8db`. Commands: `--headless --path <copy> --editor --import --quit`, followed by `--headless --path <copy> --script res://scripts/test/regression_runner.gd --quit-after 1800` and each smoke script. Compared every workspace GDScript against the tested copy: no mismatches. Confirmed the nineteen pre-existing card definitions are unchanged and exactly two definitions were added. Deck SHA256: `438e4ad219c8fb3f8f2a3282d2f212fb9d5d70e4ea2c3a857911c9d48fc0628e`.
- Created `scripts/rules/accessory_effects.gd`, `scripts/test/accessory_system_test.gd`, `scripts/test/accessory_ui_smoke.gd` (+ UIDs). Updated `data/cards.json`; `scripts/cards/card_definition.gd`, `card_database.gd`; `scripts/core/equipment_system.gd`; `scripts/rules/distance_calculator.gd`; `scripts/actions/action_validator.gd`, `action_executor.gd`; `scripts/combat/combat_controller.gd`; `scripts/dev/playable_prototype.gd`, `main_menu.gd`; and GDD/ARCHITECTURE/this status document. Existing public APIs remain; accessory facade APIs are additive.
- `standard.json` is unchanged by this milestone. It currently has no Scope/Mustang copies; no quantity or suit/rank/order was edited. Existing workspace edits are retained. No commit or push; stopped at Accessory System v0.1.

## Numeric suit order migration - 2026-11-07

- Approved mapping: **0 = hearts, 1 = diamonds, 2 = clubs, 3 = spades**. This supersedes all historical numeric mappings below. English suit names remain supported.
- Updated CardInstance enum/constructor bounds and DeckDatabase numeric validation. Existing symbolic suit APIs, color checks and armor effect descriptors retain their behavior.
- Migrated only suit numbers in standard.json: preserved all 52 cards, group/copy order, ranks and physical suits. No copies added or removed; cards.json unchanged.
- DeckTest explicitly checks numeric and named input against independent expected suit names/symbols and red/black colors, plus existing invalid-input coverage.
- Validation: Godot 4.7.2, warnings-as-errors enabled in a fresh isolated copy: **20/20 regression suites PASS and 12/12 UI smoke tests PASS**. All completion markers inspected; no script errors, parse failures or GDScript warnings. Black Shield color and Barrel Hearts tests pass. Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-suit-order-029b79e8d1ae4a3f9e910c4cd1aa2a37` (`regression_runner.gd.log` and smoke logs). `git diff --check` passed. Known sandbox certificate/editor-settings diagnostics are environmental. No commit/push.

## Armor System v0.1 — 2026-11-07

- Implemented Black Shield, Barrel, Helmet and Chainmail using the four existing JSON descriptors and an ArmorEffectRegistry keyed by effect_id/hook, without card-name/ID dispatch. Runtime/loader validate supported descriptor parameters. Existing inert metadata remains loadable; unsupported effects do not enable an equip action. No card/deck JSON was changed.
- Armor equip reuses EquipmentSystem/CardZoneManager: own living player's PLAY, one armor slot independent of weapon, no extra card cost, atomic old armor -> discard/new armor -> equipment. All normal pending windows/phase holds apply. Live lookup and equipment revision tracking remove effects immediately on loss/steal/replacement and reject stale decisions, including remove/re-equip of the same instance.
- Black Shield uses original committed CardInstance color and only resolves that defender's normal Attack. Pistol's other targets continue in the existing seat order. Barrel asks the defender before Dodge; agreement judges one actual top draw card once, Hearts succeeds, otherwise normal Dodge remains. Judgment card goes directly to discard through the zone API, using normal reshuffle; no owned Dodge is automatically spent. Designer approved: if all cards are unavailable, activation fails with the choice retained and skip available. A paid/recycled Attack can itself be the judgment, without duplicate instances or a second Attack use.
- Helmet caps every positive pipeline damage source after ordinary reductions at 1; zero/cancel remains zero and HP 1 can still die. Chainmail offers only post-reduction lethal damage, holds HP unchanged and must discard its own armor before prevention. Failed payment keeps the choice and armor/HP; decline applies damage once. Prepared result/continuation state preserves Attack, AOE and weapon-child resolution across optional armor and Dying; prevented damage never opens Dying or positive-hit weapon follow-ups. Source 0 GENERIC damage preserves unknown-source credit semantics.
- Controller-bound EffectResolver.deal_damage now honors armor while preserving its already-resolved amount semantics (no repeat of ordinary modifiers); a weak pipeline back-reference avoids an ownership cycle. Pipeline alone uses the private raw HP primitive. A fixture-only forced interruption uses that primitive to test global Dying preemption while public damage entry is correctly held. No existing regression assertion was weakened. Pipeline bool success can now mean accepted pending damage; caller continuations use result.pending/applied_amount rather than treating acceptance as HP loss.
- UI enables supported armor hand cards, renders owned armor, and presents manual inline Đồng ý/Bỏ qua for Barrel/Chainmail. Logs report revealed name/rank/suit and prevention. Dying preempts these controls. Full armor descriptions remain tooltips; compact seat names avoid the overflow found during native capture of long armor names. Manual Human/Bot choices remain explicit.
- **Validation:** Godot 4.7.2.stable.official.ed1daf0bf, warnings-as-errors in an isolated copy: **20/20 regression suites PASS** (19 prior + ArmorSystemTest), **12/12 UI smoke tests PASS** (11 prior + Armor UI). Inspected all completion markers and final *-verified.log files: no SCRIPT ERROR, parse/GDScript warnings, load failures or leak diagnostics. git diff --check passed. Known certificate-store/editor-settings sandbox diagnostics remain environmental. An intermediate routed-damage typed-array error was corrected by constructing an explicitly typed empty array; earlier diagnostic runs are not final pass evidence.
- Coverage includes all four suits/renamed definitions, per-target Pistol protection, once-only Barrel success/failure/skip/reshuffle/exhaustion/replay, Helmet source kinds/cancellation/lethal HP 1/removal by Steal, post-reduction Chainmail eligibility and activation/decline, source 0 legacy damage without modifier duplication, failed self-discard, stale armor generations, synchronous notification reentry, global Dying priority, AOE cursor continuation after prevention or rescue, Ná child damage and Dao replacement. UI uses actual clicks for equip/replace/armor choices, disabled own responses, judgment logs, Dying and post-rescue Rifle equipment selection. Native 1280x720 and 1920x1080 captures were rendered/inspected; armor-equipped seat bounds are checked.
- New files: scripts/combat/armor_effect_registry.gd, scripts/test/armor_system_test.gd, scripts/test/armor_ui_smoke.gd (+ UIDs). Changed: scripts/core/equipment_system.gd, turn_manager.gd; scripts/cards/card_database.gd; scripts/actions/action_validator.gd, action_executor.gd, effect_resolver.gd; scripts/combat/damage_context.gd, damage_pipeline.gd, attack_context.gd, attack_resolution.gd, aoe_resolution.gd, combat_controller.gd; scripts/dev/playable_prototype.gd; docs/GDD.md, ARCHITECTURE.md, DEVELOPMENT_PLAN.md and DEVELOPMENT_STATUS.md. Existing workspace changes retained; no main/startup/scene/card/deck edits, commit or push.
- **Deck boundary:** standard.json currently has **0 black_shield, 0 barrel, 0 helmet, 0 chainmail**. At least one physical copy of each would allow all four to be drawn manually (4 additions), but quantities/suits/ranks/order require a separate designer change. Tests use tracked fixture CardInstances; no real-deck copies were inserted. General armor/skill trigger stacks, delayed-card JUDGMENT and AI decisions remain outside v0.1.
- Evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-armor-aa53c5e964344eab8f57fc0027d42763`. Final evidence: thirteen *-verified.log regression/smoke logs; capture.log and armor-equipment/barrel/chainmail/chainmail-hd.png. Commands: --headless --path <copy> --script res://scripts/test/<runner>.gd --quit-after 1800; import uses --editor --import --quit. The copied project alone enables debug/gdscript/warnings/treat_warnings_as_errors=true. Source/data/deck hashes were compared with the tested copy after validation.

## Multi-card mandatory discard and slightly larger fonts — 2026-11-07

- Added atomic multi-card DISCARD through CombatController/ActionExecutor.discard_cards_for_turn(player_id, card_ids: Array[int]) and ActionValidator.validate_turn_discards. One to the current required number of distinct owned hand cards may be confirmed together. All selections validate before any movement; duplicates, foreign/equipped/stale cards, wrong phase/actor, pending windows/holds and over-discard reject without partial payment. Existing discard_for_turn(player_id, card_id) remains compatible. Partial batches stay in DISCARD; the final batch auto-advances once after completion. RuleEngine hand limits and gameplay counts are unchanged.
- TurnManager blocks phase progression while CardZoneManager is transferring, preventing synchronous discard callbacks from advancing phases/drawing during an unfinished batch. New tests cover this reentry path, exact card conservation and per-batch notifications.
- UI now toggles multiple hand cards during DISCARD, raises all selected cards, shows selected/required counts and disables extra choices when the count is reached. Huỷ bỏ clears the draft; Đồng ý confirms it. Mandatory-discard double-click only toggles selection without payment; ordinary PLAY double-click use remains. Owned draft cards survive Dying/rescue, spent cards are pruned, and turn/new-match changes clear the draft. Card movement goes through the coordinator, with all selected names in the action log.
- Slight font increase: body/buttons 15, player/log text 13, compact labels/cards at least 12, slightly larger modal/menu/setup headings. Native 1:1 canvas scaling and Full HD support remain. Inspected actual selected-card renders at 1280x720 and 1920x1080; controls/cards stay within bounds.
- Workspace data already includes four new armor definitions (19 total), preserved without JSON/deck edits. CardDatabaseTest's hard-coded 15-definition expectation failed against that user data; it now verifies the complete JSON ID/name set and count while keeping required baseline card/effect/range/schema assertions. This does not implement armor use/effects. Menu interaction smoke now explicitly asserts the new DISCARD draft-only double-click followed by confirmation; its resource-loss assertion remains after confirmation.
- **Executed validation:** Godot 4.7.2.stable.official.ed1daf0bf, warnings-as-errors in an isolated copy: **19/19 regression suites PASS** (18 prior + MultiDiscardTest), **11/11 UI smoke tests PASS** (10 prior + MultiDiscard UI). Final *-final.log files contain all completion markers and no SCRIPT ERROR, parse/GDScript warning/load/leak diagnostics. git diff --check passed. Known certificate-store/editor-settings sandbox diagnostics remain environmental. Initial failures from the obsolete fixed-count/old-double-click expectations were corrected and are not final pass evidence.
- Created scripts/test/multi_discard_test.gd and multi_discard_ui_smoke.gd (+ UIDs). Changed this follow-up: scripts/actions/action_validator.gd, action_executor.gd; scripts/combat/combat_controller.gd; scripts/core/turn_manager.gd; scripts/dev/playable_prototype.gd, main_menu.gd, match_setup_menu.gd; scripts/test/card_database_test.gd, menu_interaction_smoke.gd, full_hd_ui_smoke.gd; docs/GDD.md, ARCHITECTURE.md and DEVELOPMENT_STATUS.md. No card/deck JSON, scene, startup, Attack/AOE/weapon/heal effect edits; prior workspace changes retained. No commit/push.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-multi-discard-41eba19de4fb4bc9bde220ca8d80070e`; final evidence is the twelve *-final.log regression/smoke files, capture.log and discard-1280.png/discard-1920.png. Commands: --headless --path <copy> --script res://scripts/test/<runner>.gd --quit-after 1800; import uses --editor --import --quit. The copied project alone enables debug/gdscript/warnings/treat_warnings_as_errors=true. Source/data/deck comparisons were performed after tests.

## Compact equipment information and Full HD typography — 2026-11-07

- Player panels now show weapon/range only with an equipped weapon and defense only with actual defensive equipment. Empty placeholders and the unarmed range line are hidden; underlying range/slots/validation are unchanged. Equipped weapons retain their effective RuleEngine range and name; removing one clears that UI immediately.
- Removed the direction label, initial four-card/DRAW tutorial log entry and repeated manual-control wording. Current phase, HP/life state, hand counts, card/target selection and pending-action guidance remain. Opening deal, DRAW and counterclockwise engine order are unchanged.
- Reduced prototype/menu/setup fonts: body/button default 14, seat/log text 12, compact labels/cards at least 11, smaller section/modal headings. Prototype and main menu synchronize canvas size with the actual window, keeping text at native pixel sizes on 1920x1080 instead of scaling the former 1280x720 canvas by 1.5. Larger windows are retained across scene entry; the previous 1280x720 starting baseline is retained for undersized windows. Size synchronization has an equality guard.
- **Validation:** Godot 4.7.2 with warnings-as-errors in an isolated copy: **18/18 regression suites and 10/10 UI smoke tests PASS** (nine prior + Full HD). New smoke covers counts 2–6 at 1920x1080, canvas equality, hand/table bounds, absent/present/removed equipment labels, font sizes, removed noise and real mouse input. Existing menu/prototype assertions now expect absent empty slots and retained equipped-weapon range. Final logs have no script/parse/warning/load/leak diagnostics; git diff --check passed. Known certificate/editor-settings sandbox diagnostics remain environmental. Native OpenGL screenshots were rendered and inspected at exactly 1920x1080 with and without a weapon.
- Changed this follow-up: scripts/dev/playable_prototype.gd, main_menu.gd, match_setup_menu.gd; scripts/test/playable_prototype_smoke.gd, menu_interaction_smoke.gd; docs/GDD.md, ARCHITECTURE.md and DEVELOPMENT_STATUS.md. Created scripts/test/full_hd_ui_smoke.gd (+ UID). No engine, card/deck JSON, scene, project settings or gameplay-rule changes; existing workspace edits retained. No commit/push.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-compact-hd-6829f6197aa94db2b0f491b2006e866f`. Final evidence is the eleven *-final.log regression/smoke logs; capture.log records 1920x1080 image and canvas sizes, hd-empty-equipment.png/hd-equipped.png are inspected captures. Invocation: --headless --path <copy> --script res://scripts/test/<runner>.gd --quit-after 1800 (latest Full HD smoke used 600); import uses --editor --import --quit. The copied project alone enables debug/gdscript/warnings/treat_warnings_as_errors=true. Source/data/deck comparisons were performed after testing.

## Vertical Hủy/Cướp zone picker — 2026-11-07

- Hủy/Cướp now stacks available target zones vertically in the fixed presentation order **Trên tay -> Trang bị -> Phán xét**; cards within each zone remain horizontal. Empty/disallowed zones are omitted. Existing hidden hand/judgment backs, face-up equipment, selections and validated confirmation are unchanged.
- Added a bounded-height scroll area for all three rows; vertical scrolling is reset when returning to other choice presentations. No engine, gameplay, card/deck data, startup or scene changes. Modified scripts/dev/playable_prototype.gd, scripts/test/playable_prototype_smoke.gd and this status document.
- **Validation:** Godot 4.7.2 with warnings-as-errors in an isolated copy: **18/18 regression suites + 9/9 UI smoke tests PASS**, no final script/parse/warning/leak diagnostics. Extended Hủy/Cướp smoke asserts vertical order/alignment, viewport bounds and actual mouse selection across judgment/equipment with automatic scrolling. Inspected an OpenGL 1280x720 capture: picker bounds (340,60), size 600x600. git diff --check passed. Known certificate/editor-settings sandbox diagnostics remain environmental.
- Evidence: `C:/Users/Admin/AppData/Local/Temp/tactics-vertical-zones-d42f32005447437db649d5c3225a406d`; regression_runner.log, the nine smoke logs (latest prototype evidence: playable_prototype_smoke-final.log), capture.log/vertical-zones.png. Commands use --headless --path <copy> --script res://scripts/test/<runner>.gd --quit-after 1800; import uses --editor --import --quit. Source/data were compared with the tested copy. No commit/push.

## Inline own-card choices, notices and reshuffle display — 2026-11-07

- New-match display starts at **Xào lại: 0 lần**; only actual discard-to-draw recycling increments it. Added Deck.reshuffle_count while preserving shuffle_count's raw-call API and existing randomized setup. No-op recycle/manual shuffle do not increment the new counter. DeckTest checks both counters; the new UI smoke verifies 0 -> 1 after a real recycle and card integrity.
- Own-card decisions now use the lower hand region without shading/covering the table: Exchange hand/equipment, Dodge, AOE response, rescue and Slingshot hand cost. The existing choice Controls and handlers are reused/reparented; the ordinary hand is hidden, not duplicated onscreen. Guidance and Đồng ý/decline buttons sit above the cards. Invalid response/rescue cards remain visible and disabled. Opponent card choices (Dao/Hủy/Cướp/Súng trường) keep their existing modal, hidden hand backs and face-up equipment. Rescue owner choice and manual Bot responses remain explicit; engine priority and validations are unchanged.
- General status and event/error feedback moved into a centered table-to-hand strip. Existing concise log/history remains. Shared _hide_choice restores the normal hand for success, cancellation/reset, new table and game end; is_choice_visible covers either presentation. ChoiceCancel is reset when opening a new choice. Updated smoke visibility assertions to test the active presentation rather than assuming every choice is a modal; existing gameplay/payment assertions remain.
- Compact inline titles/zone spacing and a lower center-preview anchor fix the initial layout failures: Exchange initially extended below 720px, and a shortened table made the played-card preview intersect the top opponent seat. Both are fixed, not waived. Inspected OpenGL 1280x720 six-player normal/Exchange captures; all cards/buttons are within the viewport. The new smoke covers counts 2–6, real hand/equipment clicks, button-above-card positioning, notices above the hand, restoration, pending phase guard and real reshuffle display.
- **Executed validation:** Godot 4.7.2.stable.official.ed1daf0bf, warnings-as-errors enabled only in an isolated copy: **18/18 regression suites PASS**, **9/9 UI smoke tests PASS** (eight prior plus Inline Choices). Checked all completion markers and final logs: no SCRIPT ERROR, parse errors, GDScript warnings, load failures or leak diagnostics. git diff --check passed. Certificate-store/editor-settings sandbox diagnostics remain environmental. Early failed layout logs are not final pass evidence.
- Changed this follow-up: scripts/cards/deck.gd; scripts/dev/playable_prototype.gd; scripts/test/deck_test.gd, playable_prototype_smoke.gd, aoe_ui_smoke.gd, menu_interaction_smoke.gd, support_tools_ui_smoke.gd, weapon_ui_smoke.gd; docs/GDD.md, ARCHITECTURE.md and DEVELOPMENT_STATUS.md. Created scripts/test/inline_choices_ui_smoke.gd (+ UID). No card/deck JSON, scene, startup, combat resolution or gameplay-rule changes; earlier workspace edits retained. No commit/push.
- Evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-inline-389de58f3b74468b9d4fcd784515bf86`. Import: `--headless --path <copy> --editor --import --quit`; regression: `--headless --path <copy> --script res://scripts/test/regression_runner.gd --quit-after 1800`; each of the nine smoke scripts uses the same command with its own path. The copied project sets debug/gdscript/warnings/treat_warnings_as_errors=true. Final evidence: import-final.log and ten *-final.log runner/smoke files; native captures are inline-normal.png/inline-exchange.png. Source/data/deck comparison was performed after tests.

## Active weapon effects — 2026-11-07

- Implemented the four remaining active weapons through shared AttackContext/AttackResolution checkpoints and existing JSON effect descriptors, without dispatch by card name/ID. Nỏ thần/ranges and RuleModifier precedence remain working. No card/deck data or startup changes were made by this weapon follow-up; prior menu/Exchange/user JSON formatting changes are retained.
- Designer decisions applied: Pistol resolves selected targets in the authoritative turn cycle starting after its user; Ná excludes both source and primary; Ná/Súng trường resume after the primary is rescued and skip an eliminated primary. Ná retains a committed hand cost if secondary damage is prevented. Dao's optional replacement occurs before damage reduction/prevention. Losing a weapon permanently invalidates its uncommitted effect for that Attack, including remove/re-equip of the same instance; already-declared targets survive.
- Dao uses current JSON policy: attacker selects target hand cards face-down; exactly min(2, available hand count), replacement unavailable at zero. Confirmation atomically discards the selected cards instead of applying damage. Normal-damage choice runs the existing pipeline. Ná validates current owned hand cost plus primary-origin distance, then uses WEAPON_EFFECT pipeline damage with Dying and no Dodge/Attack count/weapon recursion. Súng trường offers only real target equipment and synchronously detaches its modifiers through the zone batch. No available cost/target/equipment means no optional opportunity.
- Pistol validates the entire distinct target list, including each target's range, before one Attack payment/counter increment. Its cursor and independent responses survive Dying/rescue/elimination and source/weapon loss. Attack snapshots retain source/card/weapon IDs, ordered targets, damage, stage and target outcomes. The old single-target commands remain adapters; pending_attack now returns a current-response snapshot. Direct/automatic phases and new gameplay commands are blocked throughout root resolution/weapon decisions. Views are copied and commands reject stale IDs/wrong choosers/invalid cards; payment/response paths reject synchronous transfer reentry. Resume is bounded to 16 steps; secondary damage does not create nested weapon effects.
- UI supports one/two-target drafting and clear count guidance, normal-Dodge responses per target, face-down Dao choices, Ná hand cost plus eligible secondary buttons, and face-up Súng trường equipment. Selection and second-double-click cancellation remain drafts; Đồng ý commits and Bỏ qua/Gây sát thương declines the optional effect. Dying replaces the modal and restores its continuation. Activation logs identify actor, weapon and recipient; removed the obsolete message claiming active effects are unsupported.
- Required foundation fixes: validator distances now use TurnManager.seat_order through an optional backwards-compatible DistanceCalculator argument; negative HP is legal for DYING in GameState.validate_state, while nonpositive ALIVE/positive DYING is invalid. An old validator fixture represented a dead victim as ALIVE with HP 0; it now uses Player.enter_dying/eliminate. A pre-existing Exchange test mutated shuffled deck indices; it now chooses fixture definitions by instance ID. The prior UI assertion expecting an unsupported-weapon warning now asserts that warning is absent. Original gameplay assertions remain.
- New files: scripts/combat/attack_context.gd, scripts/combat/attack_resolution.gd, scripts/test/weapon_system_test.gd, scripts/test/weapon_ui_smoke.gd (+ generated UIDs). Modified by this weapon follow-up: scripts/actions/action_executor.gd, action_validator.gd; scripts/combat/combat_controller.gd, damage_context.gd, damage_pipeline.gd; scripts/core/game_state.gd, turn_manager.gd; scripts/rules/distance_calculator.gd; scripts/dev/playable_prototype.gd; scripts/test/action_validator_test.gd, playable_prototype_smoke.gd, support_tools_test.gd; docs/GDD.md, ARCHITECTURE.md, DEVELOPMENT_PLAN.md, WEAPON_SYSTEM_DESIGN.md and DEVELOPMENT_STATUS.md. The large cards.json formatting diff belongs to existing/live workspace edits; parsed definitions were compared with the tested copy and preserved.
- **Executed validation:** Godot 4.7.2.stable.official.ed1daf0bf, warnings-as-errors in an isolated temporary project: **18/18 regression suites PASS** (17 prior + WeaponSystemTest), **8/8 UI smoke tests PASS** (seven prior + Weapon UI). Inspected all suite/smoke completion markers and final `*-release.log` files: no SCRIPT ERROR, parse errors, GDScript warnings, load failures or leak diagnostics. `git diff --check` passed. Known root-certificate-store/editor-settings sandbox diagnostics remain environmental. Earlier failures from the obsolete fixture/assertion and an untyped test-array loop were corrected and are not final pass evidence.
- New coverage: reversed click order and nonnumeric cyclic seat order; atomic invalid/duplicate/self/out-of-range target rejection; one Attack/count; Dodge independence; Dying cursor resume; Knife pre-modifier timing and 0/1/2/3-card cases; replacement vs HP exclusivity; positive/zero/prevented damage; chosen equipment/modifier detach; source/primary exclusion and primary-origin range; retained cancelled cost; WEAPON_EFFECT source/no response/no recursion; negative child HP requiring multiple rescues; fresh/copy/stale decision state; phase/new-action/reentry/replay guards; weapon removal/re-equip and eliminated-source continuation. UI smoke uses actual clicks/double-clicks for all four effects, hidden/face-up visibility, multi-target drafting, free incomplete drafts and post-rescue continuation. OpenGL 1280x720 modal captures were rendered and visually inspected.
- Evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-weapons-258dc1623da34b37b79087f837e83a02`. Import: `--headless --path <copy> --editor --import --quit`; regression: `--headless --path <copy> --script res://scripts/test/regression_runner.gd --quit-after 1800`; smoke uses the same command with each smoke script. The copied project alone enables debug/gdscript/warnings/treat_warnings_as_errors=true. Final evidence is import-final.log and the nine *-release.log files. Source/data/deck comparison was performed after testing; standard.json is unchanged by this task.
- Remaining boundaries: one supported equipped-weapon effect per Attack, bounded checkpoints rather than an arbitrary trigger/skill/armor framework; no AI, new roles, armor gameplay or deck balancing. General same-checkpoint trigger tie rules remain OPEN. No commit/push or further milestone.

## Main menu and Exchange equipment discard — completed verification 2026-11-07

- Resumed the existing unfinished workspace changes: MainMenu/F5 startup and Exchange hand/equipment selection were already present; the earlier entry only recorded regression/Support smoke validation. This follow-up completes catalog interaction testing, fixes presentation/data inconsistencies and records a fresh full run.
- F5 opens `scenes/main_menu.tscn` with **Chơi** and **Danh mục bài**. Chơi routes to the existing 2–6-player setup; F6 on the prototype remains available. Catalog reads all 15 definitions directly from CardDatabase, displays Vietnamese categories/ranges/descriptions, wraps long descriptions and keeps Quay lại outside scrolling entries. It never constructs a match or CardInstance. Reopening the catalog reloads definitions.
- Fixed a real menu canvas/input mismatch found by actual mouse smoke: the menu changed window size without setting content scaling, so injected pointer coordinates could activate Chơi while aiming at Danh mục bài. MainMenu now uses the same 1280x720 canvas/keep-aspect configuration as PlayablePrototype. The initial failing run was not counted as passing evidence.
- Exchange specifies unique `discard_zones: ["hand", "equipment"]`, defaulting other descriptors to hand for compatibility. Preflight counts eligible owned zones and drawable hand cards. Exact two-card confirmation resolves each ID's actual source zone and uses one atomic transfer; wrong owner, duplicate, judgment, stale/replayed selections reject without partial payment. Equipment modifiers detach synchronously. UI groups hand/equipment separately and the completion log now includes equipped-card names instead of searching only hand. Updated Exchange's JSON description to match this approved rule.
- Expanded SupportToolsTest for equipment removal/modifier detach, duplicate/foreign/judgment rejection, deep-copy safety, depleted-deck preflight and malformed zone lists. Extended Support Tools UI smoke to select one hand card and one face-up equipped weapon through real clicks and confirm exact-once discard/name logging. New MainMenu smoke tests catalog open/back/reopen, all descriptions, bounded card width, navigation after scrolling, Chơi -> setup -> valid match.
- **Executed validation:** Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors in an isolated project: **17/17 regression suites PASS**, **7/7 UI smoke tests PASS** (prototype, AOE, menu interaction, Support Tools, elimination, table presentation, main menu/catalog). Inspected all 17 suite completion markers and seven smoke completion markers; final logs contain no SCRIPT ERROR, parse errors, GDScript warnings, load failures or leak diagnostics. Known certificate-store/editor-settings sandbox errors remain environmental. `git diff --check` passed. OpenGL menu/catalog captures were rendered and visually inspected.
- Evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-menu-exchange-4630ab7183054c729c6d9a88fde07f61`. Import: `--headless --path <copy> --editor --import --quit`; suites: `--headless --path <copy> --script res://scripts/test/regression_runner.gd --quit-after 1800`; smoke scripts use the same command with their script path. The temporary copied project alone enables `debug/gdscript/warnings/treat_warnings_as_errors=true`. Final evidence logs: regression.log, main-menu.log, support-ui.log and the five other named smoke logs; main-menu-debug.log is an earlier failed diagnostic run, not final evidence.
- Files created by this requested follow-up: `scenes/main_menu.tscn`, `scripts/dev/main_menu.gd` (+ UID), `scripts/test/main_menu_smoke.gd` (+ UID). Files modified: `project.godot`, `data/cards.json` (Exchange parameters/description only), `scripts/actions/action_validator.gd`, `scripts/actions/support_tool_resolution.gd`, `scripts/dev/playable_prototype.gd`, `scripts/test/support_tools_test.gd`, `scripts/test/support_tools_ui_smoke.gd`, GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS. Existing user/workspace changes were retained. No standard.json edits; its hash matches the tested copy.
- **Weapon boundary:** equip/replace, ranges and Crossbow unlimited Attack already work. This follow-up does not add the other four active abilities. Their resolution order, post-Dying eligibility/continuation and active-effect lifetime still need designer decisions (WEAPON_SYSTEM_DESIGN G5–G9/G11–G12); JSON specifies several selection/cost details but does not settle all timing. A clarification was sent. The user conditionally authorized weapon development, but no unresolved gameplay rule was silently chosen. No commit/push.

**Workspace verified:** `E:\Projects\Godot\tactics`, 2026-11-06, Godot `4.7.2.stable.official.ed1daf0bf`.
**Evidence standard:** implemented behavior, executed tests, and future work are recorded separately. A zero Godot process exit code alone does not establish a test pass.

## Current snapshot
- **Latest UI presentation:** reference-guided table/hand layout with right sidebar log and bottom-right P1, center preview of the last successfully used card, and concise log without `→ OK`. Selection/error paths leave the center preview unchanged; no gameplay/state/data change. Verification for this follow-up is recorded below.

## Screenshot-guided table, played-card preview and concise log — 2026-11-06

- Applied the supplied image as a layout reference: opponents surround the left play area; hand and centered action buttons sit below; MatchSidebar on the right contains New Table, deck counters, vertical scrollable log and P1 information at the bottom. Keeps 2–6 seats, manual Bot controls, counterclockwise engine order, Western native Control styling and existing F6 entry point. No reference background/character artwork was copied.
- Center preview uses the existing card-face builder, enlarged to 104x142 with owner/optional target caption. It updates only after a successful card use/response/rescue/tool submission; choosing a card, cancelling a draft, failed use, death cleanup and ordinary discards do not replace it. Tool victim cards are not confused with the played tool. Preview ignores pointer/focus input, persists after resolution, and clears on a new match. It is not an engine zone and does not move any physical card.
- _record retains its existing callers through optional presentation arguments. Successful entries use plain action text, without `→ OK`; failures show the reason in feedback instead of polluting match history. Removed automatic phase-status log lines. Shortened new-match/turn/discard/death/reward/response text while retaining actors, card names and actual damage/healing results. Full descriptions remain tooltips.
- Files changed in this follow-up: `scripts/dev/playable_prototype.gd`, `scripts/test/playable_prototype_smoke.gd`, `scripts/test/elimination_ui_smoke.gd`, GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS. Created `scripts/test/table_presentation_smoke.gd`. Existing smoke geometry/log assertions were migrated to the new sidebar and concise wording; gameplay assertions remain. Prior workspace changes were preserved. No engine, JSON, scene, main or project-setting edits by this follow-up.
- Validation: Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled only in a temporary project: **17/17 regression suites PASS**, all **6/6 UI smoke tests PASS** (prototype, AOE, menu, Support Tools, elimination, table presentation). Table smoke uses actual mouse input across all counts 2–6, checks sidebar/hand/preview bounds and non-overlap, successful Attack/Dodge/heal preview changes, draft/full-HP/invalid-command preservation, new-match clearing, no technical success suffix/empty log entries, and card integrity. Inspected completion markers and logs, not exit code alone.
- OpenGL 1280x720 captures of four/six players were rendered and inspected; no overlap or offscreen hand/own panel. No GDScript warnings/errors/load failures/leak diagnostics in final test logs. Known root-certificate/editor-settings sandbox diagnostics remain environmental. Temporary project: `C:/Users/Admin/AppData/Local/Temp/tactics-table-ui-bce54e1427bc4466b57dc3d3f3618fbc`; helpers/captures stay outside the repository. No commit/push or additional milestone.

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$tablePath = 'C:/Users/Admin/AppData/Local/Temp/tactics-table-ui-bce54e1427bc4466b57dc3d3f3618fbc'
# Same isolated copy/import setup; warnings-as-errors is enabled only in the copied project.
& $godotExecutable --headless --path $tablePath --editor --import --quit --log-file (Join-Path $tablePath 'import.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/regression_runner.gd --quit-after 1800 --log-file (Join-Path $tablePath 'regression.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $tablePath 'ui-smoke.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/aoe_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $tablePath 'aoe-ui-smoke.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/menu_interaction_smoke.gd --quit-after 1800 --log-file (Join-Path $tablePath 'menu-smoke.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/support_tools_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $tablePath 'support-ui-smoke.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/elimination_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $tablePath 'elimination-ui-smoke.log')
& $godotExecutable --headless --path $tablePath --script res://scripts/test/table_presentation_smoke.gd --quit-after 1800 --log-file (Join-Path $tablePath 'table-smoke.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

## Previous elimination/input/log snapshot
- **Elimination/input/log follow-up implemented:** all eliminated-player zones go to discard, confirmed lethal source draws a temporary 2-card reward once, repeated double-click clears unfinished drafts, and action controls are centered above the active hand. Logs identify actors, cards, damage/healing recipients, discarded-card owners and rewards. **17/17 suites + all 5 UI smoke tests PASS** under warnings-as-errors; details below.

## Elimination cleanup, temporary kill reward and input/log follow-up — 2026-11-06

- Approved reward policy: identify the source of the damage that actually causes DYING; reward 2 cards only after the victim is eliminated. No reward for rescue, unknown source, self damage or an already ELIMINATED source. A source that is still DYING has not yet been eliminated and is not excluded by this policy. Partial/empty reward draw follows normal deck exhaustion; no cards are created. Full rescue clears lethal credit so an older attacker cannot claim a later unknown-source death.
- EffectResolver.deal_damage and restore_hp gain optional source IDs, preserving old callers. DamagePipeline forwards its real source; normal heal/Saloon supply theirs. GameState retains lethal credit and emits structured damage/healing/elimination/reward signals. Old two-argument direct/debug damage remains unknown-source and earns no kill reward, as agreed.
- DyingManager finalization batches hand/equipment/judgment -> discard, synchronously removes weapon modifiers, eliminates the victim, awards through GameState.draw_card, then runs the existing match-result check. Dying remains guarded during cleanup/reward and a reentry flag rejects repeated finalization. Thus final-kill reward is handled before match end. If the draw pile is empty, ordinary reshuffle can immediately draw cards just discarded from the victim; they still entered discard exactly once and card identity is conserved.
- UI retains first-double-click activation through existing confirm APIs. If that leaves a draft (e.g. Attack without target, or one Exchange discard selected), another double-click of that card deselects it without log/payment. It never rolls back an action already committed. Changed the old menu smoke sequence to explicitly test deselection, then choose a fresh valid attack.
- Moved Đồng ý/Huỷ bỏ/Kết thúc lượt into centered HandActions above HandScroll; independent deck counters remain below. Verified both layout and actual clicks, including a six-seat 1280x720 view. Player information remains separate.
- Event log uses GameState damage/healing/death/reward signals plus explicit user/card/target/source-zone action text. Discard logs add owner names via CardZoneManager.get_last_discard_groups (deep copy) while preserving its existing names-only cards_discarded signal. Attack/AOE response and Hủy/Cướp logs name the submitted card and participants; no card descriptions/instance IDs replace names. Draft selection/reset remains unlogged.
- Created `scripts/test/elimination_lifecycle_test.gd`, `scripts/test/elimination_ui_smoke.gd` and generated UIDs. Modified in this follow-up: `scripts/core/game_state.gd`, `scripts/core/card_zone_manager.gd`, `scripts/combat/damage_pipeline.gd`, `scripts/combat/dying_manager.gd`, `scripts/actions/effect_resolver.gd`, `scripts/actions/action_executor.gd`, `scripts/actions/support_tool_resolution.gd`, `scripts/dev/playable_prototype.gd`, `scripts/test/dying_system_test.gd`, `scripts/test/turn_manager_test.gd`, `scripts/test/menu_interaction_smoke.gd`, and GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS/WEAPON_SYSTEM_DESIGN. No card/deck JSON, scene, main or project-setting writes by this follow-up; prior T2/user edits are retained. The user-added standard deck currently has 52 cards.
- Regression migration: two prior tests expected dead players to retain Dodge/hand cards. They now assert empty hand and discarded-card identity/count under the newly approved cleanup rule; their original response/turn assertions remain. Initial runs with those obsolete assertions failed and were not counted as passes.
- **Actual validation:** Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors in an isolated copy: **17/17 regression suites PASS** (16 prior + EliminationLifecycleTest), **5/5 UI smoke tests PASS** (prototype, AOE, menu interaction, Support Tools, elimination). Inspected suite completion markers and final logs; no SCRIPT ERROR, GDScript warning, load failure or leak diagnostics. Known root-certificate/global-editor-settings sandbox errors remain environmental.
- Added coverage: all three cleanup zones, synchronous weapon detach, conservation and duplicate/reentry rejection, no reward before elimination, rescued/unknown/self/eliminated-source cases, lethal-source reset, AOE reward per victim, final-kill reward and partial reward/reshuffle. UI checks double-click deselection in hand/Exchange drafts, damage/owner/reward log text, exact card payment and centered action-row placement. Existing pending-window/turn/weapon/AOE/Support suites remain passing.
- OpenGL captures at 1280x720: actions-six-players.png and kill-reward-log.png were rendered and inspected. Temporary project: `C:/Users/Admin/AppData/Local/Temp/tactics-elimination-ce152b92836245298efaa630fdfd6f69`; helpers/captures remain outside the repository. Final source/data comparison and git diff --check were performed.
- No role reward policy, AI or active weapon ability was added. This is the explicitly temporary two-card reward. No commit/push or further milestone.

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$deathPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-elimination-ce152b92836245298efaa630fdfd6f69'
# Copy scripts/data/scenes/project.godot/icon.svg and enable warnings-as-errors in that copy only.
& $godotExecutable --headless --path $deathPath --editor --import --quit --log-file (Join-Path $deathPath 'import-final.log')
& $godotExecutable --headless --path $deathPath --script res://scripts/test/regression_runner.gd --quit-after 1800 --log-file (Join-Path $deathPath 'regression-final.log')
& $godotExecutable --headless --path $deathPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $deathPath 'ui-smoke-final.log')
& $godotExecutable --headless --path $deathPath --script res://scripts/test/aoe_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $deathPath 'aoe-ui-smoke-final.log')
& $godotExecutable --headless --path $deathPath --script res://scripts/test/menu_interaction_smoke.gd --quit-after 1800 --log-file (Join-Path $deathPath 'menu-smoke-final.log')
& $godotExecutable --headless --path $deathPath --script res://scripts/test/support_tools_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $deathPath 'support-ui-smoke-final.log')
& $godotExecutable --headless --path $deathPath --script res://scripts/test/elimination_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $deathPath 'elimination-ui-smoke-final.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

## Previous T2 snapshot
- **T2 — Support Tools v0.1 implemented:** Draw 2, Exchange (draw 3 + mandatory selected discard 2), Saloon (heal each ALIVE player by 1). Engine effects reuse draw/zone/heal primitives; pending Exchange blocks normal actions and phases. Definitions exist but **standard.json is unchanged and contains zero copies of these three tools**. Latest test evidence follows; older milestone results remain historical.

## T2 — Support Tools v0.1 — 2026-11-06

- Added tool definitions `draw_2` / Rút 2 lá (`draw_cards`, count=2), `exchange` / Trao đổi (count=3, discard_count=2), `saloon` (`heal_all_players`, amount=1). CardDatabase shares the runtime effect schema validator and rejects malformed numeric parameters without partial loading. CardDatabaseTest now checks all 15 definitions and the new IDs/effects.
- EffectResolver now handles draw_cards via GameState.draw_card, preserving Deck recycling/CardZoneManager ownership, partial draws and finite exhaustion. There is no DeckManager/HealPipeline class in current source; Saloon reuses the implemented restore_hp API for each living wounded player, includes the source, caps to max_hp, skips eliminated/DYING and succeeds when everyone is full. It is not classified as a Rescue card.
- SupportToolResolution owns the synchronous execution lock and Exchange pending decision. It reserves the played card until drawing ends, then discards that tool once; the source cannot recycle into its own draw. Exchange requires exactly two distinct owned hand cards in a single batch, including newly drawn cards if chosen. Wrong owner/count/duplicates/spent/stale cards reject without moving any selected card. Its returned state is a deep copy. Impossible mandatory discards caused by an initially depleted deck are rejected before use; partial draws otherwise retain existing behavior.
- Dying takes priority over the decision; resolution continues afterwards without a second draw or tool payment. If the user is eliminated, the stale decision clears and existing turn skipping resumes. Match end clears it. New support commands are own-PLAY only and consult existing phase/window guards. TurnManager adds the Support busy state to that shared guard; Attack/Dodge/Weapon/AOE validation, damage and resolution bodies are unchanged. CardZoneManager exposes is_transfer_in_progress() so entry during a discard notification cannot apply healing before a failed payment.
- APIs: CombatController.use_support_tool(actor_id, card_id), discard_for_support(actor_id, card_ids: Array[int]) -> ActionResult; has_pending_support(), get_pending_support(). Executor exposes corresponding guarded commands. EffectResolver.draw_cards(player_id, count) -> int and heal_all_players(amount) -> bool are effect primitives, not replacements for action validation.
- UI supports all three tools through the active hand without target selection. Exchange opens a dedicated multi-card discard picker with Đồng ý enabled only for exactly two selections. Chọn lại resets drafts, preserving the committed draw; pending Exchange disables End Turn/normal hand use. Dying replaces the picker and restores it afterwards. Double-click supports the same path without paying twice or submitting an incomplete selection. Draft selection/reset does not write the match log.
- Created: `scripts/actions/support_tool_resolution.gd`, `scripts/test/support_tools_test.gd`, `scripts/test/support_tools_ui_smoke.gd` and generated UIDs. Modified: `data/cards.json`, `scripts/actions/action_executor.gd`, `scripts/actions/action_validator.gd`, `scripts/actions/effect_resolver.gd`, `scripts/cards/card_database.gd`, `scripts/combat/combat_controller.gd`, `scripts/core/card_zone_manager.gd`, `scripts/core/turn_manager.gd`, `scripts/dev/playable_prototype.gd`, `scripts/test/card_database_test.gd`, `docs/GDD.md`, `docs/DEVELOPMENT_STATUS.md`. Existing workspace changes preserved. No standard.json/scene/main/project-setting edits.
- Deck availability: all three IDs have **0 copies** in standard.json (47 physical cards unchanged). At least 1 `draw_2`, 1 `exchange`, 1 `saloon` would make all three drawable (3 extra copies); final quantities/suits/ranks/order require designer choice. No copies were added by this milestone; tests use isolated fixture decks.
- Remaining boundaries: no general nested-trigger framework, new armor/weapon abilities, roles, AI or deck balancing. External mutations that remove hand cards after a committed Exchange must still meet its exact discard count; no automatic partial-discard rule is invented. Existing negative-HP validate_state discrepancy remains outside T2. Stop after T2; no commit/push.

**Actual validation:** Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled only in an isolated temporary copy. **16/16 regression suites PASS** (15 existing + SupportToolsTest), **all four UI smoke tests PASS**: playable_prototype_smoke, aoe_ui_smoke, menu_interaction_smoke and support_tools_ui_smoke. Inspected each suite's completion output and final logs, not just exit codes/return markers. No final SCRIPT ERROR, GDScript warning, load failure or leak diagnostic. Known root-certificate/global-editor-settings sandbox errors remain environmental.

Coverage includes Draw 2/3, partial/zero draws, reshuffle without duplicated instances, exact Exchange batch/discard count, ownership/duplicate/stale selections and replay, full/max/ALIVE/ELIMINATED/6-seat Saloon behavior, no Saloon Rescue, own PLAY/effect hold/Attack/AOE/Dying/Exchange/game-over restrictions, interrupted pending decisions, eliminated source, malformed schema and synchronous notification reentry. UI uses real clicks/double-clicks for targetless tools, resource-free drafts/reset, multi-card selection, exact-once discard and Dying rescue/resumption. An initial UI fixture selected the wrong default rescuer because player storage order differed; the test now explicitly chooses the owner of the healing card, and the final smoke passes.

OpenGL captures at 1280x720 visually verified the new hand cards, Exchange's multi-selection picker and return to PLAY. `git diff --check` passed. Code/data were compared with the tested copy and standard.json hash is unchanged. Temporary evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-support-946aca0955c748d2b89ac5b164586a22`; helpers/captures remain outside the repository.

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$supportPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-support-946aca0955c748d2b89ac5b164586a22'
# Copy scripts/data/scenes/project.godot/icon.svg; enable warnings-as-errors in that copy only.
& $godotExecutable --headless --path $supportPath --editor --import --quit --log-file (Join-Path $supportPath 'import-final.log')
& $godotExecutable --headless --path $supportPath --script res://scripts/test/regression_runner.gd --quit-after 1800 --log-file (Join-Path $supportPath 'regression-final.log')
& $godotExecutable --headless --path $supportPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $supportPath 'ui-smoke.log')
& $godotExecutable --headless --path $supportPath --script res://scripts/test/aoe_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $supportPath 'aoe-ui-smoke.log')
& $godotExecutable --headless --path $supportPath --script res://scripts/test/menu_interaction_smoke.gd --quit-after 1800 --log-file (Join-Path $supportPath 'menu-smoke.log')
& $godotExecutable --headless --path $supportPath --script res://scripts/test/support_tools_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $supportPath 'support-ui-smoke.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

Earlier snapshots retain their original results.

## Previous menu/defense snapshot
- **Latest setup/input/defense follow-up:** setup menu for 2–6 players, P1…Pn names, adaptive seating, double-click confirmation and armor slot/metadata/UI foundation. Defense effects and armor use remain unimplemented as explicitly requested. Validation recorded below; prior AOE evidence is retained separately.

## Match setup, double-click and defense foundation — 2026-11-06

- User confirmed defense scope: **slot/metadata and UI only, no effects**. No new armor cards or gameplay equip/replacement policies were introduced. Existing pending Attack/AOE/Dying, counterclockwise order and opening/DRAW rules are retained.
- F6 now opens MatchSetupMenu before constructing a match. Choose 2–6 players; engine players are P1…Pn, P1 human and the rest manually controlled. New Table opens setup instead of immediately deleting the current session; cancel restores it, including its pending response. Loading/deal-capacity validation happens before session replacement. New Table/CreateMatch remain available after game over. No role distribution is invented for other counts.
- Rebuilt dynamic seat controls retain P1's separate panel; 2–4 seats use the existing circular orientation, while 5–6 use upper/lower side seats without overlap. Engine order remains ascending IDs independently of UI nodes. All seats display the defensive slot beside weapon/range/health information.
- Double-click on a usable hand/modal card selects and confirms through the same existing APIs as Đồng ý. Targets are still required and never auto-selected. The old button is disabled for its release to prevent duplicate submission. Single-click remains a resource-free draft; disabled cards remain inactive. Coverage includes heal, weapon equip, targeted Attack, Dodge, tool victim, AOE response, rescue and hand-limit discard.
- Foundation: weapon and armor slots are recognized in CardDefinition; batch transfers reject a duplicate slot while allowing one weapon plus one armor. EquipmentSystem exposes a shared slot query and get_defense; controller exposes get_defense. Existing weapon APIs/modifiers remain unchanged. CardDatabase accepts inert armor with `category=equipment`, `subcategory=armor`, `equipment_slot=armor`, `effects=[]`, and rejects inconsistent/unknown slots. Armor in hand stays disabled with an unsupported-use tooltip. No defense modifier or automatic armor activation exists.
- Files created: `scripts/dev/match_setup_menu.gd`, `scripts/test/defense_foundation_test.gd`, `scripts/test/menu_interaction_smoke.gd` and generated UIDs. Files modified in this follow-up: `scripts/dev/playable_prototype.gd`, `scripts/cards/card_definition.gd`, `scripts/cards/card_database.gd`, `scripts/core/card_zone_manager.gd`, `scripts/core/equipment_system.gd`, `scripts/combat/combat_controller.gd`, `scripts/test/playable_prototype_smoke.gd`, `scripts/test/aoe_ui_smoke.gd`, and these four docs. Older smoke setup now clicks CreateMatch; winner assertions use P1. Prior workspace changes are preserved. No JSON, scene, main or project-setting edits by this follow-up.
- Remaining: armor equip/replace/cost/timing and specific defensive effects need a later gameplay specification; no mitigation/dodge/extra HP was added. General nested effects/AI/roles and previously recorded engine limitations remain outside scope. No commit/push or next milestone.

**Actual validation:** Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled only in the temporary test project: **15/15 regression suites PASS** (13 original + AOE + defense foundation), plus **all three UI smoke tests PASS**. Inspected each suite completion and final logs: no SCRIPT ERROR, GDScript warning, load failure or leak diagnostic. The intermediate invalid-slot numeric fixture exposed a loader runtime comparison error; the loader now checks slot type before comparing strings, and the final rerun passes. Known root-certificate/global-editor-settings sandbox errors are environmental and unchanged.

Defense regression checks inert metadata loading, malformed slots without partial loading, independent weapon/armor occupancy, duplicate-slot rejection, card conservation and no new armor equip action. Menu smoke verifies all counts 2–6, P1…Pn, opening cards, nonoverlapping seats, full turn order, cancellation preserving the old match/response, restart after victory, and real mouse double-clicks through every existing card confirmation context. Existing combat/rescue/AOE smoke cases remain covered after explicitly starting a default four-seat match from the menu.

Rendered and inspected OpenGL 1280x720 captures of the startup menu and 2-/4-/6-seat tables, including defensive-slot labels. `git diff --check` passed. Temporary project: `C:/Users/Admin/AppData/Local/Temp/tactics-menu-7698e1a703e84433a6d7633111971aec`; captures and helper stay outside the repository. No workspace project-setting changes; all source/data hashes were compared with the tested copy.

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$menuPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-menu-7698e1a703e84433a6d7633111971aec'
# Copy scripts/data/scenes/project.godot/icon.svg into menuPath;
# enable debug/gdscript/warnings/treat_warnings_as_errors in that copy only.
& $godotExecutable --headless --path $menuPath --editor --import --quit --log-file (Join-Path $menuPath 'import-final.log')
& $godotExecutable --headless --path $menuPath --script res://scripts/test/regression_runner.gd --quit-after 1800 --log-file (Join-Path $menuPath 'regression-final.log')
& $godotExecutable --headless --path $menuPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $menuPath 'ui-smoke-final.log')
& $godotExecutable --headless --path $menuPath --script res://scripts/test/aoe_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $menuPath 'aoe-ui-smoke-final.log')
& $godotExecutable --headless --path $menuPath --script res://scripts/test/menu_interaction_smoke.gd --quit-after 1800 --log-file (Join-Path $menuPath 'menu-smoke-final.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

Older AOE results below describe their original snapshot.

## Previous AOE snapshot
- **AOE Tool System v0.1 implemented:** Gatling/Indian use one data-driven `aoe_response_damage` queue, manual per-target responses, Dying-first continuation and engine phase/action guards. **14/14 regression suites (13 existing + AOE) and both UI smoke tests PASS** with warnings-as-errors; implementation and reproducible commands below.

## AOE Tool System v0.1 — 2026-11-06

- Scope: one sequential AOE tool resolution, not the general weapon/nested-decision framework. Gatling requires `block_attack`; Indian requires `deal_attack`. Both use `target_scope=all_other_players`, positive integral JSON damage, no distance check, and counterclockwise `TurnManager.seat_order` starting after the user. Source and ELIMINATED seats are excluded. Response cards must be owned basic hand cards with the requested effect; wrong owner/type/target/stale cards reject without payment.
- New `AoeResolution` captures source/card/name, ordered target IDs, cursor, response effect and damage. The tool is discarded once; a valid explicit response is discarded once OR damage goes through DamagePipeline. Cursor advances before Dying adoption; final-target Dying keeps the AOE lock. Rescue/elimination resumes the correct next response without reapplying damage. External Dying before response preserves that response after rescue or skips it after elimination. Source elimination retains the committed queue; existing turn skipping resumes only after it finishes. Match end clears pending AOE.
- Normal Attack and AOE remain separate APIs/windows. Indian responses do not call use_attack, increment attacks_used, open another Attack Response or activate weapons. DamageContext now distinguishes GENERIC/ATTACK/AOE_TOOL; pipeline has an optional compatible source-kind argument and DamageModifier has an optional source-kind filter. Attack-only weapon effects must filter ATTACK; common damage defenses retain their normal pipeline behavior. Four active weapon abilities remain unimplemented.
- TurnManager's shared guard prioritizes Dying then Attack/AOE. New attacks/tools/heal/equip/turn discard, end-turn, auto-advance and direct phase/start calls cannot bypass pending AOE. No AI or automatic response choice is introduced. A forward-only cursor, finite seat list and synchronous reentry lock bound progress without recursive resolution.
- UI routes AOE through controller APIs and displays source/tool/current target, valid response cards, Đồng ý and Không phản ứng, including when no valid response card exists. Dying temporarily replaces the AOE modal. Pending AOE disables normal hand use/End Turn; draft choices remain outside the Event Log. The existing standalone scene/default startup are unchanged.
- Data: added Gatling/Indian definitions to cards.json; concurrent user edits to names/descriptions and existing weapon fields were preserved. A previously observed `parameterss` typo was corrected in the live workspace before this task patched it; no separate typo rewrite was needed. **This task never wrote standard.json.** The user edited that file during work; final tests used their valid **47-card** snapshot (3 Gatling, 3 Indian, 3 Discard, 3 Steal; other quantities unchanged). An intermediate test copy captured incomplete JSON while it was being edited; that failed run was replaced by a valid snapshot and is not counted as passing evidence.
- Created: `scripts/combat/aoe_resolution.gd`, `scripts/test/aoe_system_test.gd`, `scripts/test/aoe_ui_smoke.gd`, `scripts/test/regression_runner.gd` (and generated Godot UIDs).
- Modified: `scripts/actions/action_executor.gd`, `scripts/actions/action_validator.gd`, `scripts/cards/card_database.gd`, `scripts/combat/combat_controller.gd`, `scripts/combat/damage_context.gd`, `scripts/combat/damage_modifier.gd`, `scripts/combat/damage_pipeline.gd`, `scripts/core/turn_manager.gd`, `scripts/dev/playable_prototype.gd`, `scripts/test/card_database_test.gd`, `data/cards.json`, and GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS. Existing APIs remain compatible through optional arguments; CardDatabaseTest's expected definition count was updated from 10 to 12 with AOE assertions. No edits to existing 13 suite bodies beyond this schema assertion migration.
- Actual validation: Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in the temporary project only. **14/14 regression suites PASS; playable_prototype_smoke and aoe_ui_smoke PASS**. Inspected per-suite completion markers and logs, not just exit code/SUITE_RETURNED. No final SCRIPT ERROR, GDScript warning, load failure or leak diagnostics. Known root-certificate-store and global-editor-settings sandbox errors remain environmental.
- Regression coverage: both response types, independent seat/storage order, wraparound/eliminated skipping, distance independence, wrong/replayed/spent response rejection, payment/card integrity, unchanged Attack count, snapshot isolation, normal/direct guards, first/last target Dying, negative HP with two paid rescues, external target/source elimination, match-end cleanup, common damage cancellation and Attack-only modifier exclusion, malformed JSON parameters, renamed definitions and reentry during discard notifications. UI coverage uses real mouse clicks for both tools, Human/Bot responses, no auto-consumption, draft/no-log behavior, explicit decline, Dying interruption and return to PLAY.
- Visually verified OpenGL captures at 1280x720: aoe-gatling.png, aoe-dying.png and aoe-indian-human.png. Temporary fixtures/capture helper/screenshots stay outside the repository.
- Remaining: general nested/simultaneous effects, AI, weapon active abilities, role-based wins, and the previously recorded negative-HP `GameState.validate_state` discrepancy remain outside v0.1. No new gameplay policy for those systems. Stop after AOE v0.1; no commit/push.

Verification used this temporary copy, preserving workspace project settings:

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$aoePath = 'C:/Users/Admin/AppData/Local/Temp/tactics-aoe-d4edd01033d945d3a5c4d414f337f529'
# scripts/data/scenes/project.godot/icon.svg copied into aoePath;
# append [debug] gdscript/warnings/treat_warnings_as_errors=true in that copy only.
& $godotExecutable --headless --path $aoePath --editor --import --quit --log-file (Join-Path $aoePath 'import-final.log')
& $godotExecutable --headless --path $aoePath --script res://scripts/test/regression_runner.gd --quit-after 1800 --log-file (Join-Path $aoePath 'regression-final.log')
& $godotExecutable --headless --path $aoePath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $aoePath 'ui-smoke-final.log')
& $godotExecutable --headless --path $aoePath --script res://scripts/test/aoe_ui_smoke.gd --quit-after 1800 --log-file (Join-Path $aoePath 'aoe-ui-smoke-final.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The repository runner discovers all `scripts/test/*_test.gd` and prints each suite's return marker. A helper assertion may return control to it, so check suite PASS markers and absence of SCRIPT ERRORs/load failures as done for this verification; its exit code alone is not a verdict. Both UI smoke scripts are separate SceneTree invocations.

## Earlier UI snapshot (before AOE v0.1)
- Latest UI update: selected hand/modal cards rise 12 px; other cards dim while legal alternatives remain clickable. Draft selection/targeting/cancellation stays out of the match log. Human has a separate lower information panel; the adjacent hand still follows the active actor for manual Bot control. **13/13 regression suites and UI smoke PASS** under warnings-as-errors; details below.

## Selection feedback and separate Human panel — 2026-11-06

- Files changed in this follow-up: `scripts/dev/playable_prototype.gd`, `scripts/test/playable_prototype_smoke.gd`, and GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS. Existing workspace edits were preserved. No engine, JSON, scene, startup or project-setting changes in this follow-up.
- Shared hand/modal selection presentation uses a 132 px slot for a 120 px card, lifting the selected card by 12 px and dimming alternatives. Switching/cancelling restores the appropriate appearance without payment. Disabled cards retain their validation guard.
- Draft card/target choices and tool-picker cancellation only update local feedback; opening/selecting/cancelling a tool picker adds no log entry. Confirmed actions, discard transfers, response/rescue resolution and match results retain their logs.
- Human Seat1 is in HumanInfoPanel below BotTable; Bot1/right, Bot2/above and Bot3/left remain unchanged. Human information stays fixed while the hand follows the active Human/Bot for manual testing. Engine turn order is unchanged.
- Actual validation: Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled only in a fresh temporary copy: **13/13 regression suites PASS, UI smoke PASS**. Inspected all completion markers and logs: no SCRIPT ERROR, GDScript warning or load failure. Smoke covers lift/dimming/switch/cancel, draft log/resource preservation, confirmed-action logging, modal selection, panel separation and existing combat/turn/equipment/rescue/winner scenarios.
- OpenGL 1280x720 captures visually verified the raised card, dimmed alternatives, separate Human panel and grouped tool picker. Known root-certificate/editor-settings sandbox diagnostics persist independently of script results. No commit/push or next milestone.
- Evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-selection-ui-f84a2575a2c64d38975c91d51356fd89`. Same temporary copy/runner setup as earlier records. Commands: `--headless --path <project> --editor --import --quit`; `--headless --path <project> --script res://regression_runner.gd --quit-after 1800`; `--headless --path <project> --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800`; OpenGL capture: `--path <project> --rendering-method gl_compatibility --script res://capture.gd --quit-after 600`. Logs: import.log/regression.log/ui-smoke.log/capture.log. Helpers and captures remain outside the repository.

## Earlier snapshot (before this selection update)
- Latest UI refinement: 88x120 cards with uppercase face names, separate labeled hand/equipment/judgment groups in Hủy/Cướp, and validator-driven dimming/disabling of illegal targets for selected Attack/tools. Changing cards clears stale targets; Confirm waits for a valid target. Engine rules/data are unchanged.
- Latest compact presentation: log entries have a single newline and name-only card references; descriptions stay in tooltips. Card rank/suit appears only at the top. Draw/discard counts and total shuffle calls are in a separate panel beside the action buttons, including the opening shuffle.
- Latest UI redesign: no right Debug menu; Event Log is in the top header, table uses full width, card faces are portrait cards, HP uses hearts (negative deficit retained), unavailable cards and eliminated seats are disabled/dimmed. Bots remain manually controllable through the active hand. No engine/data/default-scene change in this UI follow-up.
- Latest authorized basic equipment work is implemented: equip during own PLAY without extra cost, one weapon slot, old weapon to discard on replacement, ranges and Nỏ thần unlimited Attack via RuleModifier. Full weapon-trigger framework/four active abilities remain planned; see [WEAPON_SYSTEM_DESIGN.md](WEAPON_SYSTEM_DESIGN.md) and the latest execution record below.
- Discard transfers log card names; Hủy/Cướp shows equipment face-up while hand cards remain hidden. Exactly one living survivor after Dying resolution now ends the match, announces the winner and locks gameplay until New Table.
- Latest paid-rescue rule: **negative HP is preserved; self or another living player can spend an owned healing card to rescue the active DYING target**. Each use consumes one card; at -1, two +1 uses reach 0 then 1. Dying priority remains until HP > 0. This supersedes earlier simulation-only/clamped-HP records below. Card descriptions and selection text use `data/cards.json`.
- Latest Dying/UI correction: **Dying -> Attack Response -> normal actions/phases**. Existing DYING states are adopted at guard/controller boundaries, and a blocking modal prioritizes paid rescue or explicit no-rescue elimination. Compact hand cards show only name and rank/suit.
- Healing/UI follow-up: healing cards support validated self-healing during the current actor's PLAY, with card payment. The lower hand follows the active Human/Bot (Bot hands explicitly marked DEBUG), with shared **Đồng ý / Huỷ bỏ** controls for card selection. Paid Dying rescue is implemented by the latest follow-up.
- Latest seating correction: **Human/below -> Bot 1/right -> Bot 2/above -> Bot 3/left -> Human**, geometrically counterclockwise on screen. Bot 1 and Bot 3 UI positions are swapped; engine seat order remains `[1, 2, 3, 4]`. This supersedes all earlier left/right layouts recorded below.
- Current opening: **4 cards each, plus normal 2-card DRAW on every turn including the first**; Human enters first PLAY with 6. No first-DRAW skipping remains. All phase labels are Vietnamese. Order remains Human -> Bot 1 -> Bot 2 -> Bot 3. User data now contains 10 definitions and 39 instances, including five weapons; this task preserved those JSON edits.
- Deck JSON now accepts numeric suits: **0 = spades/Bích, 1 = hearts/Cơ, 2 = diamonds/Rô, 3 = clubs/Tép**. `data/decks/standard.json` uses these numbers; existing named suits remain supported. Quantities, ranks, card order and gameplay are unchanged.
- Stage 0.1 — Dying integration is implemented and its scoped regression tests pass.
- Combat v0.5 / Stage 0.2 and Playable Prototype UI v0.2 are implemented under the explicit counterclockwise/auto-phase rules below. Open `res://scenes/dev/playable_prototype.tscn` and press F6; startup/main scene and project settings remain unchanged.
- Latest Card/Deck regression repair: **13/13 suites passed** with GDScript warnings-as-errors enabled in the temporary test project. The previous 11/13 Stage 0.1 result is retained below as historical evidence.
- Latest v0.5 validation: **13/13 regression suites PASS plus UI smoke PASS**, with warnings-as-errors enabled in the temporary project. Stop after v0.5 / UI v0.2; Stage 0.3 has not been started.
- All four handoff documents are updated for v0.5; earlier snapshot findings and test records are explicitly historical.
- No commit or push was performed. Pre-existing workspace edits and handoff files were preserved.

## Compact uppercase cards, tool zones and target filtering — 2026-11-06

- Reduced the shared face/back size from 108x148 to 88x120 and adjusted the hand viewport/fonts. Card titles use to_upper() only for presentation; JSON, tooltips and name-only log text are preserved.
- Hủy/Cướp pickers group nonempty hand/equipment/judgment zones into separate labeled panels with counts. Equipment remains face-up; hand/judgment visibility is unchanged. Choice buttons carry card/zone metadata; cross-group selection deselects the previous choice and commits the correct zone. No payment occurs during selection/cancellation.
- Attack/tool selection filters seats through the existing ActionValidator, using the active actor/card/counter. Illegal self, range, life-state or empty-zone targets are dimmed and cannot be selected. A target that becomes illegal on card/weapon change is cleared; Confirm is disabled until a valid target is selected. Cancel restores normal non-eliminated-seat availability. DISCARD and fixed-target response/rescue flows remain distinct. Final engine validation is unchanged.
- Files changed: `scripts/dev/playable_prototype.gd`, `scripts/test/playable_prototype_smoke.gd`, GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS. No engine, JSON, scene, main or project-settings edits by this task; no commit/push.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in a fresh temporary copy. Final logs have no script errors/warnings/load failures. New smoke cases verify uppercase/small faces; Attack self/out-of-range locks; Steal range/empty-target locks; Discard's unrestricted-distance valid target; stale-target clearing and Confirm readiness; range changes on Rifle/Crossbow equip; Bot target filtering; all three zone groups, source-zone selection and deselection across groups. Existing combat/rescue/equipment/winner scenarios remain covered.
- Mouse helper now finds the nearest ScrollContainer ancestor, supporting cards nested in zone panels. OpenGL captures at 1280x720 visually verified smaller cards, dimmed invalid Attack targets and a tool picker containing all three zones. `git diff --check` passed. Known certificate/editor-settings environment diagnostics remain separate from script results.
- Temporary evidence project: `C:/Users/Admin/AppData/Local/Temp/tactics-target-zones-49d83fe27f194b6681eee98a02ede9ca`. Used the same copy/import/runner setup as previous records; commands: `--headless --path <project> --editor --import --quit`, `--headless --path <project> --script res://regression_runner.gd --quit-after 1800`, `--headless --path <project> --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800`; capture via `--path <project> --rendering-method gl_compatibility --script res://capture.gd --quit-after 600`. Logs: import.log/regression.log/ui-smoke.log/capture.log. Capture helper prepares hand/equipment/judgment fixtures via existing transfer APIs; helpers/images stay outside the repository.

## Compact log, deck counters and top-only card corners — 2026-11-06

- Removed blank lines between Event Log entries. Selection/equip/attack/heal log references use card names, without the JSON description or rank/suit; hover descriptions remain available. Other gameplay results/status messages remain intact.
- Moved draw/discard count display out of the table center into DeckInfoPanel at the right of the bottom action row, alongside the shuffle count. Added Deck.shuffle_count as telemetry incremented by each existing shuffle() call, including the initial GameState shuffle, explicit calls and automatic discard recycling; RNG/draw/recycle rules are unchanged. Merely attempting to recycle with an active draw pile or two empty piles does not call shuffle or increment it.
- Removed the bottom rank/suit and duplicate central suit emblem from the shared portrait-card builder. Top rank/suit and centered name remain consistent across hand/response/rescue/equipment cards.
- Files changed: `scripts/dev/playable_prototype.gd`, `scripts/cards/deck.gd`, `scripts/test/deck_test.gd`, `scripts/test/playable_prototype_smoke.gd`, and GDD/ARCHITECTURE/DEVELOPMENT_PLAN/DEVELOPMENT_STATUS. No card/deck JSON, scene, main or project-setting edits by this task.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS** on Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in a fresh temporary copy. Inspected completion markers and logs; no SCRIPT ERROR, warnings or load failures. DeckTest verifies count 2 after setup + explicit shuffle, unchanged by rejected recycle/empty draw, then 3 after automatic recycling. UI smoke verifies single-newline entries, exact selected-card-name log, only two face labels, separate panel position, draw count and initial shuffle count. Existing gameplay/contextual-disable smoke scenarios retained.
- Rendered/visually inspected the OpenGL 1280x720 equipped-table preview: dense log, simple card faces and independent lower-right counters fit the layout. `git diff --check` passed. Known certificate/editor-settings diagnostics remain unrelated to script validation. No commit/push.

Validation commands (same temporary-copy setup and all-suite runner as earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$compactPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-compact-log-35d903277c834fabaa4ba43f08c590d8'
& $godotExecutable --headless --path $compactPath --editor --import --quit --log-file (Join-Path $compactPath 'import.log')
& $godotExecutable --headless --path $compactPath --script res://regression_runner.gd --quit-after 1800 --log-file (Join-Path $compactPath 'regression.log')
& $godotExecutable --headless --path $compactPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $compactPath 'ui-smoke.log')
& $godotExecutable --path $compactPath --rendering-method gl_compatibility --script res://capture.gd --quit-after 600 --log-file (Join-Path $compactPath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper follows the previous equipment/tool/winner capture workflow using engine APIs only; screenshots/helpers remain outside the repository.

## UI presentation and contextual interaction — 2026-11-06

- Removed the right Debug sidebar, selector/draw/force-response controls and redundant non-modal rescue/finalize row. The Event Log is now in the top header; the four-seat table fills the width with anchored positions preserving Human -> Bot 1/right -> Bot 2/top -> Bot 3/left. Bot turns remain manually playable through the lower hand/Confirm/End Turn, without AI or gameplay changes.
- Added reusable native portrait card faces (108x148) with light paper color, rounded border, top/bottom rank/suit, suit emblem and centered name. Response/rescue/face-up equipment pickers reuse this layout. JSON descriptions stay in tooltips; no image assets or description paragraphs were added to card faces.
- Seat health uses filled/empty hearts; DYING at negative HP shows empty hearts plus the exact negative number. Modal rescue also shows the deficit. Eliminated seats are greyed/disabled, their selection is cleared, and direct UI selection attempts are rejected. Match-end lock/restart still works.
- The hand uses existing ActionValidator queries to determine contextual availability. Dodge is unavailable for normal PLAY; full-HP healing, Attack with no legal target/remaining use, and tools without a valid target are disabled. Required DISCARD still permits any owned card, including Dodge. Target response/rescue modal cards remain selectable in their own context. Executor remains the final authority; no direct HP/phase/window mutations from UI.
- Files changed in this follow-up: `scripts/dev/playable_prototype.gd`, `scripts/test/playable_prototype_smoke.gd`, `docs/GDD.md`, `docs/ARCHITECTURE.md`, `docs/DEVELOPMENT_PLAN.md`, this document. Engine/Card JSON, scenes, main and project settings were preserved.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in a fresh temporary copy. All suite completion output and script-error logs inspected; no script errors/warnings/load failures in final runs. Smoke fixtures now prepare cards through existing engine APIs rather than deleted Debug widgets, and exercise Bot actions through the shared hand. Added assertions for absence of Debug controls, log position, portrait card fields, full/wounded/negative hearts, disabled Dodge/full-HP heal, Dodge selection in DISCARD, and disabled/de-selected eliminated targets.
- During UI testing a real mouse click initially targeted a card outside the horizontal scroll viewport; the smoke helper now waits for layout and uses ensure_control_visible before sending mouse input. The final smoke rerun passes with no SCRIPT ERROR, rather than relying only on its completion print. Existing combat/equip/rescue/tool/winner scenarios remain covered.
- Desktop OpenGL 1280x720 previews were rendered and visually inspected for the active table, mixed hidden/face-up tool cards and match-end disabled state. Seat bounds were adjusted to contain the added text within the table. `git diff --check` passed. Known certificate/editor-settings access diagnostics remain environmental.
- No commit/push. Full weapon active effects and existing engine limitations remain outside this UI-only change.

Validation commands (temporary setup/runner follows the earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$uiPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-table-ui-90042b5f389f440691a3a0f420703ca5'
& $godotExecutable --headless --path $uiPath --editor --import --quit --log-file (Join-Path $uiPath 'import.log')
& $godotExecutable --headless --path $uiPath --script res://regression_runner.gd --quit-after 1800 --log-file (Join-Path $uiPath 'regression.log')
& $godotExecutable --headless --path $uiPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $uiPath 'ui-smoke.log')
& $godotExecutable --path $uiPath --rendering-method gl_compatibility --script res://capture.gd --quit-after 600 --log-file (Join-Path $uiPath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper uses engine transfer/equip/damage/finalize APIs to render equipped.png, face-up-equipment.png and winner.png. Helpers/screenshots remain outside the repository. Regression ran once on the unchanged engine; UI smoke was rerun after the interaction/layout corrections.

## Basic equipment, discard log, survivor victory and visible equipment — 2026-11-06

- Scope authorized after the design handoff: basic weapon equip/replace during own PLAY, no extra payment, old weapon to discard. The subsequent request adds name-only discard notifications, last-survivor victory and face-up equipment for Hủy/Cướp. No additional weapon special-effect rules were invented.
- CardDefinition now reads the user's equipment_slot/range fields; CardDatabase validates positive integral weapon range and weapon slot. New EquipmentSystem queries Player.equipment as the single slot source and applies/removes per-owner/instance RuleModifiers. Range 1–5 and remove_attack_limit are supported; no counter reset or other validation bypass. Modifiers disappear synchronously on replace, discard or steal; stolen weapons go to hand without auto-equip. Character-skill priority remains above equipment.
- CardZoneManager now preflights batch transfers in shadow arrays, enforcing at most one weapon per equipment zone. Original transfer_card API delegates to one-move batch. Equipment replacement and tool payment/victim transfer are atomic. Equipment_changed synchronizes modifiers before returning; cards_discarded emits only successfully added names after commit. Failed/cancelled operations emit no discard notification. Existing non-weapon equipment test fixtures remain compatible.
- UI routes owned equipment through CombatController.equip_weapon without requiring a target. Seats show weapon/effective range; unsupported special effects are explicitly reported. Tool pickers show equipment names/ranks/suits/description, while hand card backs retain hidden text. Discard notifications include Attack/Dodge/heal/rescue, hand-limit/tool discards and replaced weapons; the old rescue/discard action log ID wording was also replaced with names.
- GameState owns match_over/winner_id and a once-only match_finished signal. Startup and Dying resolution check for one non-eliminated living survivor; DYING always prevents premature victory. Match end clears pending attack, blocks normal phase/action/response/damage/draw APIs, skips auto-resume and disables UI gameplay. Winner text appears in header/prompt/log. New Table starts a fresh state and restores controls. Zero eligible survivors does not invent a winner. Role-based victory remains future work.
- Created: `scripts/core/equipment_system.gd` and its UID. Modified engine: `scripts/cards/card_definition.gd`, `scripts/cards/card_database.gd`, `scripts/core/card_zone_manager.gd`, `scripts/core/game_state.gd`, `scripts/core/turn_manager.gd`, `scripts/actions/action_validator.gd`, `scripts/actions/action_executor.gd`, `scripts/actions/effect_resolver.gd`, `scripts/combat/combat_controller.gd`, `scripts/combat/dying_manager.gd`, `scripts/combat/damage_pipeline.gd`. UI: `scripts/dev/playable_prototype.gd`.
- Tests modified: `scripts/test/action_executor_test.gd`, `scripts/test/card_database_test.gd`, `scripts/test/dying_system_test.gd`, `scripts/test/turn_manager_test.gd`, `scripts/test/playable_prototype_smoke.gd`. Docs updated: GDD, ARCHITECTURE, DEVELOPMENT_PLAN, DEVELOPMENT_STATUS and WEAPON_SYSTEM_DESIGN. User JSON and scene/project/main changes were preserved; no cards.json/standard.json/main/default-scene edits by this work, no commit/push.
- Actual validation: **13/13 regression suites PASS + UI smoke PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in the temporary copy. Checked each suite's completion and absence of SCRIPT ERROR/warnings/load failures; exit code alone was not used. New cases cover equip ownership/phase/windows/hold, Crossbow multiple attacks and removal without counter reset, skill precedence, range boundary on 12 seats, Hủy/Cướp modifier detach, slot collision/failed batch atomicity, discard names/no notification on failure, visible equipment selection, and survivor victory/Dying guards/gameplay lock/restart.
- Test fixture repairs during execution: CardDatabaseTest's old count of five definitions was migrated to validate all ten user definitions and weapon metadata; the UI helper's hard cap of 32 selected discards was replaced by a finite budget derived from fixture hand size because the current deck has 39 cards. This does not change the engine's 32-step auto-phase cap. A temporary schema file initially used an unavailable user:// location; the test now creates and cleans a unique res:// fixture in the temporary test project. Final reruns have no script errors.
- Rendered and inspected 1280x720 OpenGL previews: equipped.png, face-up-equipment.png, winner.png. Reduced hand scroll minimum height to keep the added weapon row and controls within the canvas; reran UI smoke after the layout correction. Known certificate/global-editor-settings environment diagnostics remain separate from tests.
- Remaining: four active weapon abilities/general pending framework, voluntary unequip/elimination equipment cleanup rules and centralized nested damage remain unimplemented. The previously identified negative-HP validate_state invariant discrepancy remains recorded for F0; it was not modified as part of equipment/log/win/UI work.

Executed commands (temporary copy with warnings-as-errors and the same all-suite runner as earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$equipPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-equipment-d1bd43917fdf43b8a1effa93101458c7'
& $godotExecutable --headless --path $equipPath --editor --import --quit --log-file (Join-Path $equipPath 'import.log')
& $godotExecutable --headless --path $equipPath --script res://regression_runner.gd --quit-after 1800 --log-file (Join-Path $equipPath 'regression.log')
& $godotExecutable --headless --path $equipPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 1800 --log-file (Join-Path $equipPath 'ui-smoke.log')
& $godotExecutable --path $equipPath --rendering-method gl_compatibility --script res://capture.gd --quit-after 600 --log-file (Join-Path $equipPath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper gathers weapon/tool fixtures through transfer APIs, equips Crossbow, opens a tool picker with a visible weapon alongside hidden hand cards, then resolves three eliminations and renders the winner. Helpers/screenshots remain outside the repository.

## Historical Weapon System v1.0 — design handoff, 2026-11-06

- Read AGENTS, all four handoff docs and relevant Card/Rule/Core/Action/Combat/Prototype source; checked test entry points and affected regression scenarios. Created `docs/WEAPON_SYSTEM_DESIGN.md` in Vietnamese with gap analysis, responsibilities, Attack/event flow, equipment/modifier lifecycle, proposed JSON schema, pending/optional/replacement/multi-target/nested damage design, five-weapon mapping, test matrix, milestones and open gameplay decisions.
- Proposed controlled effect-driven resolution, two behavior services (EquipmentSystem/CombatResolution) and small typed state records; reuse RuleEngine, validators, transfer primitives and DyingManager. This is a proposal, not shipped code. Foundation F0/F1/F2 must precede weapon behavior W1–W7; roadmap added after current foundations in DEVELOPMENT_PLAN.md.
- Source discrepancy identified: `scripts/core/game_state.gd::validate_state()` still rejects all HP < 0, while EffectResolver/DyingManager and the latest approved rescue rule allow DYING at negative HP. Existing tests checked final recovery/conservation and do not establish the intermediate negative-state invariant. Recorded as an F0 blocker; not fixed in this documentation task.
- Other gaps: DamagePipeline bool true includes cancelled/zero damage; pending_attack stores one target; equipment transfers have no slot/modifier lifecycle; DistanceCalculator follows players storage while TurnManager can use an independent seat_order; generic pending weapon decisions/continuations and centralized damage notifications are absent. All are mapped to dependencies and tests in the design.
- Open rules G1–G12 remain explicit: equip/replace destinations and elimination cleanup, Dao shortage/chooser/visibility/timing, Ná eligibility and post-Dying behavior, multi-target resolution order/revalidation, snapshot/live effect lifetime, Súng trường equipment chooser, trigger conflicts and optional cost/opportunity semantics. No defaults were implemented.
- Files changed by this task only: new `docs/WEAPON_SYSTEM_DESIGN.md`, updated `docs/DEVELOPMENT_PLAN.md`, this status document. Existing GDD/ARCHITECTURE, gameplay source, card/deck JSON and scene changes from earlier work were preserved.
- Validation for this task: documentation/diff and source/data/scene hash comparison only; **no regression/UI/weapon tests rerun** for a documentation-only change. Previous 13/13 + smoke evidence below remains historical and does not test unimplemented weapons. No implementation, commit or push; stop at design handoff pending approval.

## Latest follow-up — paid rescue, negative HP and JSON descriptions, 2026-11-06

- Implemented the latest explicit rule: lethal damage preserves negative HP; the target stays DYING until HP > 0. A DYING player may use their own healing card; another living player may use their owned card regardless of whose turn it is. Each confirmation pays exactly one card and reads its positive integral amount from JSON. At -1 with +1 cards, the first use reaches 0 and keeps the modal/guards; the second reaches 1 and resumes the interrupted flow.
- API migration: `CombatController.rescue_player(rescuer_id, target_id, card_id=0)` now takes a healing-card **instance ID**, replacing the old free heal_amount argument. Omitted/zero, spent, wrong-owner/type/target cards reject without cost. It routes through new `ActionExecutor.use_rescue` / `ActionValidator.validate_rescue`; the shared healing-card validation is reused. The low-level `DyingManager.rescue_player(..., heal_amount)` remains the HP/state operation and now permits self-rescue. UI never invokes it directly or writes HP/life state.
- UI modal selects a rescuer (including the target), lists their healing cards and requires card selection plus Đồng ý. Changing rescuer/partial recovery clears the previous card selection. No-card rescuers cannot confirm. Main/Debug rescue buttons now open this paid picker, with no free-rescue UI action. Explicit no-rescue/finalization remains available; no timeout, automatic card use, ordered pass protocol or new AI rule was added.
- `data/cards.json` already owned full descriptions. Updated the healing description for paid self/other rescue and negative HP; removed hardcoded card-description/usage branches from `_card_usage`, which now returns the JSON description. Hand/rescue tooltips and selection messages read that field. Compact card faces still show only name/rank/suit. Gameplay amounts remain in effect parameters, separate from descriptive text.
- Files changed in this task: `data/cards.json`; `scripts/actions/action_validator.gd`, `scripts/actions/action_executor.gd`, `scripts/actions/effect_resolver.gd`, `scripts/combat/dying_manager.gd`, `scripts/combat/combat_controller.gd`, `scripts/dev/playable_prototype.gd`; `scripts/test/dying_system_test.gd`, `scripts/test/turn_manager_test.gd`, `scripts/test/playable_prototype_smoke.gd`; all four handoff docs. Preserved other workspace edits, including deck/scene changes; no commit/push.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in a fresh temporary copy. Inspected each suite completion and error logs; no script errors/warnings/load failures. Tests migrate the old free-rescue fixtures to paid cards and verify negative HP (-2 -> -1 -> 0 -> 1), self/other rescue, ownership/type/missing/spent-card rejection without cost, partial recovery blocking, card conservation, no-card UI state and JSON-backed tooltip/selection descriptions. Existing turn/Attack/Dodge/tool/heal scenarios retained. `git diff --check` passed.
- Desktop OpenGL capture at 1280x720 visually verified the paid self-rescue modal at HP -1 with the two-HP requirement, rescuer selector, card choices and confirmation. Known certificate/editor-settings environment diagnostics remain unrelated to script results. Central damage events, simultaneous/nested damage ordering and rescue pass/timing protocol remain future work.

Validation commands (same temporary-copy setup and regression runner as earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$rescuePath = 'C:/Users/Admin/AppData/Local/Temp/tactics-rescue-cards-d74e6da0b0bd416492f53af0ff2a441c'
& $godotExecutable --headless --path $rescuePath --editor --import --quit --log-file (Join-Path $rescuePath 'import.log')
& $godotExecutable --headless --path $rescuePath --script res://regression_runner.gd --quit-after 600 --log-file (Join-Path $rescuePath 'regression.log')
& $godotExecutable --headless --path $rescuePath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $rescuePath 'ui-smoke.log')
& $godotExecutable --path $rescuePath --rendering-method gl_compatibility --script res://capture.gd --quit-after 600 --log-file (Join-Path $rescuePath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper gathers owned healing-card fixtures through transfer APIs, applies five damage to the four-HP target via EffectResolver, opens self-rescue selection and renders `paid-rescue.png`. Helpers/screenshots stay outside the repository.

## Historical follow-up — Dying priority and compact card faces, 2026-11-06

- Found gaps: transition/status/UI branches checked pending Attack before Dying; response execution did not reject concurrent Dying; unregistered DYING from direct resolver/pipeline calls could block phases without exposing a rescue window; UI had no blocking Dying picker.
- Added `TurnManager.get_dying_block_reason()` before Attack checks and as the response guard. `DyingManager.ensure_pending_dying()` adopts an existing DYING participant if no window is registered, preserving any active window. Controller status/rescue/finalize and transition guards use it. This is boundary discovery, not a centralized damage-event dispatcher or a simultaneous-damage rules implementation.
- Pending Dodge/pass now fails without card/window mutation while Dying is unresolved. Rescue resumes the original response. If its target is eliminated, controller finalization completes the stale attack via the executor without consuming Dodge or applying more damage.
- UI opens a blocking Dying modal before Attack/tool choices, showing the target, HP, living rescuer selector, simulated rescue and explicit no-rescue elimination. Normal actions/phase progression remain blocked. Existing simulation rescue/payment rules are unchanged. HP still clamps to 0 for lethal/overkill damage; negative-HP arithmetic was not introduced.
- Hand cards show only name and rank/suit, with smaller dimensions; the extra usage-description row was removed. Hover descriptions remain available.
- Files changed: `scripts/combat/dying_manager.gd`, `scripts/core/turn_manager.gd`, `scripts/actions/action_executor.gd`, `scripts/combat/combat_controller.gd`, `scripts/dev/playable_prototype.gd`, `scripts/test/dying_system_test.gd`, `scripts/test/playable_prototype_smoke.gd`, and all four docs. No card data/default scene/project settings changes, no commit/push.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS** with Godot `4.7.2.stable.official.ed1daf0bf` and warnings-as-errors enabled in a temporary copy. New cases cover simultaneous pending Attack/Dying, direct damage discovery, rejection without Dodge consumption, resume after rescue, stale attack closure after elimination, Dying modal priority and compact card captions. Existing healing/tool/turn suites retained. No script errors/warnings/load failures; all suite completion markers inspected. `git diff --check` passed.
- Desktop OpenGL capture at 1280x720 verified compact cards and the Dying modal. An initial narrow-label layout issue was corrected, the capture inspected again and UI smoke rerun successfully. Known certificate/editor-settings environment diagnostics remain separate.

Validation commands (same copy setup and regression runner as previous records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$dyingPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-dying-priority-9655226407b64f769c873038579f2ceb'
& $godotExecutable --headless --path $dyingPath --editor --import --quit --log-file (Join-Path $dyingPath 'import.log')
& $godotExecutable --headless --path $dyingPath --script res://regression_runner.gd --quit-after 600 --log-file (Join-Path $dyingPath 'regression.log')
& $godotExecutable --headless --path $dyingPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $dyingPath 'ui-smoke.log')
& $godotExecutable --path $dyingPath --rendering-method gl_compatibility --script res://capture.gd --quit-after 600 --log-file (Join-Path $dyingPath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper renders Human and Bot hands, then uses the existing resolver to inflict lethal damage and renders `dying-modal.png`. Helpers/screenshots stay outside the repository. Centralized notifications and nested/simultaneous lethal-event ordering remain Stage 0.3 work.

## Latest follow-up — healing cards and manual Bot hand controls, 2026-11-06

- Root cause: EffectResolver could restore HP, but there was no card-use API to validate ownership/turn/phase, read the healing amount and pay the healing card; UI therefore reported the card unsupported.
- Added `ActionValidator.validate_heal`, `ActionExecutor.use_heal`, `CombatController.use_heal`. Self-healing requires a living wounded current actor in PLAY and an owned single-effect restore_hp card with positive integral JSON amount. HP caps at max; success discards the healing card once. Invalid/full-HP/out-of-turn/out-of-phase/non-owner/window/effect-hold requests spend nothing. Existing resolver/API names retained. Healing others and card-based Dying rescue were not introduced.
- Lower hand now displays the active player's real cards, with Bot DEBUG labeling. Select a card and any needed target, then Đồng ý. During DISCARD the same button submits the chosen discard. Huỷ bỏ clears local card/target selection without spending cards. Selection clears on actor change or card loss. End Turn follows the active actor; the separate manual Debug sidebar remains. Target response modal retains Đồng ý and explicit Không Né; tool modal uses Đồng ý / Huỷ bỏ.
- Files changed: `scripts/actions/action_validator.gd`, `scripts/actions/action_executor.gd`, `scripts/combat/combat_controller.gd`, `scripts/dev/playable_prototype.gd`, `scripts/test/action_executor_test.gd`, `scripts/test/playable_prototype_smoke.gd`, and all four docs. No deck JSON, default scene, project settings, turn order or DRAW changes. No commit/push; Stage 0.3 not started.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in a fresh temporary copy. Inspected all suite completion outputs, not exit status alone; no script errors/warnings/load failures. New tests cover heal payment/cap/JSON amount and invalid requests, Human/Bot healing through UI, cancellation without cost, each active hand and hidden inactive hands. Existing Attack/Dodge/tool/Dying/discard scenarios retained. `git diff --check` passed.
- Rendered the updated UI using OpenGL compatibility at 1280x720 and visually inspected the Bot-turn hand, active seat, shared buttons and Debug sidebar. Temporary capture outputs: `human-hand.png`, `bot-hand.png`. Known certificate/editor-settings access diagnostics remain environmental.

Validation commands (same temporary-copy setup and regression runner as the earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$uiTestPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-heal-ui-44bb3b7dbb0b4c718a104b4a77892531'
& $godotExecutable --headless --path $uiTestPath --editor --import --quit --log-file (Join-Path $uiTestPath 'import.log')
& $godotExecutable --headless --path $uiTestPath --script res://regression_runner.gd --quit-after 600 --log-file (Join-Path $uiTestPath 'regression.log')
& $godotExecutable --headless --path $uiTestPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $uiTestPath 'ui-smoke.log')
& $godotExecutable --path $uiTestPath --rendering-method gl_compatibility --script res://capture.gd --quit-after 600 --log-file (Join-Path $uiTestPath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper instantiates the prototype, renders the opening hand, ends Human PLAY and submits any required discards via the controller, then renders the Bot hand. No capture/test runner was added to production.

## Latest correction — counterclockwise screen layout, 2026-11-06

- Swapped Bot 1 to the right and Bot 3 to the left; Human remains below and Bot 2 above. The existing named turn sequence now travels counterclockwise on screen. The banner explicitly says `Ngược chiều kim đồng hồ` and displays the engine sequence.
- Changed `scripts/dev/playable_prototype.gd`, `scripts/test/playable_prototype_smoke.gd` and the four handoff docs. No engine/API/card-data changes; opening deal and DRAW behavior preserved. No commit/push.
- UI smoke now checks actual global seat coordinates, in addition to the existing full turn cycle and eliminated-seat skipping.
- Actual validation: **13/13 regression suites PASS and UI smoke PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, fresh temporary copy with warnings-as-errors enabled. All suite completion outputs inspected; no script errors/warnings/load failures. The known certificate/editor-settings environment diagnostics remain separate.
- Temporary test project: `C:/Users/Admin/AppData/Local/Temp/tactics-seats-6881dd39c01a4ba58bb7459f38367d61`. Same copy/import/runner setup as the DRAW correction below. Executed `--headless --path <temporary-project> --editor --import --quit`, then `--headless --path <temporary-project> --script res://regression_runner.gd --quit-after 600` and `--headless --path <temporary-project> --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600`; logs: `import.log`, `regression.log`, `ui-smoke.log`. `git diff --check` passed.

## Latest correction — first-turn DRAW and Vietnamese phases, 2026-11-06

- Removed first-DRAW suppression and its unused tracking from TurnManager; start_match still deals four cards once, then uses the standard DRAW. On the first Human PLAY: Human has 6, other seats have 4; each Bot draws its own 2 on first arrival. Normal hand-limit discard still applies. Resuming PLAY never repeats DRAW.
- Added `TurnManager.get_phase_display_name()` for Giai đoạn bắt đầu / phán xét / rút bài / sử dụng bài / bỏ bài / kết thúc. UI header, card-use hints, relevant validation/wait messages and turn logging use Vietnamese. Enum values/order and gameplay API method signatures are unchanged.
- Source changed in this correction: `scripts/core/turn_manager.gd`, `scripts/combat/combat_controller.gd`, `scripts/actions/action_validator.gd`, `scripts/dev/playable_prototype.gd`; tests: `scripts/test/turn_manager_test.gd`, `scripts/test/playable_prototype_smoke.gd`; all four docs updated. Prior workspace edits retained; no deck/main/project-settings change, no commit/push.
- Actual validation: Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled in a fresh temporary copy: **13/13 regression suites PASS and UI smoke PASS**, with no script errors/warnings/load failures. TurnManagerTest covers first-turn draws for all four seats, second Human turn, no duplicate draw on resume and all six translations. UI smoke asserts Vietnamese active/Discard headers and updated hand counts, while retaining the Attack/Dodge/tool/dying/selection scenarios.
- `git diff --check` passed. Sandbox certificate/editor-settings diagnostics remain unrelated environment limitations.

Exact commands (same temporary-copy/runner setup as earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$drawPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-first-draw-fdca10c56adc4fd3acc2b1bd3e9222a4'
& $godotExecutable --headless --path $drawPath --editor --import --quit --log-file (Join-Path $drawPath 'import.log')
& $godotExecutable --headless --path $drawPath --script res://regression_runner.gd --log-file (Join-Path $drawPath 'regression.log')
& $godotExecutable --headless --path $drawPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $drawPath 'ui-smoke.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

## Historical opening hands and card-choice interactions — 2026-11-06

The first-DRAW skip in this earlier record has been superseded by the correction above; the tool/response behavior is unchanged.

- User clarification retained the named order Human/below -> Bot 1/left -> Bot 2/above -> Bot 3/right -> Human. Its geometric screen-direction ambiguity is documented in GDD; the UI now displays the exact named sequence and explicitly explains manual Bot turns, rather than changing the order contrary to the user's choice.
- GameState now owns a once-only, validated four-card opening deal; CombatController.start_match uses it. Too few cards or a non-pristine/duplicate deal fails before mutation. The current 34-card user deck supplies 16 opening cards, leaving 18 in draw. The deck JSON was preserved.
- Each player's first turn skips DRAW. Human and all Bots enter their first PLAY with 4; Human returns to PLAY with 6 at their next turn if no cards were used. Legacy `start_game()` remains available for existing engine fixtures without initial dealing.
- Attack still uses the existing range/turn/card checks. A modal overlay opens for the actual victim. It shows their Dodge options, selection alone does not spend anything, and Đồng ý commits the chosen Dodge. Không Né explicitly resolves damage; no automatic Bot response was added.
- Hủy/Cướp now use their existing JSON effects through new validator/executor/controller APIs. The source card and target are validated before showing face-down cards in allowed zones. Only zone labels are visible; names/suits/ranks/tooltips are absent. Confirm revalidates and pays the source tool once; cancelling or stale/out-of-range/invalid selection costs nothing. Steal uses JSON distance 1; Discard has no added distance restriction. No additional counter/response rules were invented.
- UI is still presentation/API calls only. Actual table order, turn skipping and phase guards remain in the engine. Default scene and project settings are unchanged. Stage 0.3, AI, victory and paid rescue were not implemented.
- Changed source: `scripts/core/game_state.gd`, `scripts/core/turn_manager.gd`, `scripts/combat/combat_controller.gd`, `scripts/actions/action_validator.gd`, `scripts/actions/action_executor.gd`, `scripts/dev/playable_prototype.gd`.
- Tests updated: `scripts/test/game_state_test.gd`, `scripts/test/turn_manager_test.gd`, `scripts/test/action_executor_test.gd`, `scripts/test/playable_prototype_smoke.gd`. The same 13 suite classes remain. All four docs updated; prior workspace edits retained. No commit/push.

### Validation
- **13/13 regression suites PASS**, Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled only in a fresh temporary copy. DeckTest verifies 34 cards; opening tests cover 4 each, no redeal, insufficient-deck rejection without mutation, first-cycle order/no draws and second-turn DRAW. Tool tests cover Discard/Steal across hand/equipment/judgment, range, ownership, wrong phase/actor/zone, stale choices, pending Attack, payment and conservation.
- **UI smoke PASS**, including actual mouse events for card backs and confirmation, four opening hands, the full named turn cycle, selection-before-Dodge-confirm with no premature consumption, explicit no-Dodge, tool cancellation/hidden information/commit, and the existing lethal/rescue/elimination/phase/discard scenarios.
- Each suite's completion output and the UI completion marker were inspected. Final logs have no SCRIPT ERROR, GDScript warning or suite-load failure. Sandbox certificate/editor-settings diagnostics remain environment limitations, distinct from test failures.
- Desktop OpenGL previews of the opening four-card table, face-down tool picker and target Dodge picker were rendered at 1280x720 and visually inspected. `git diff --check` passed.

Exact validation commands (temporary setup and regression runner follow the earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$interactionPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-interactions-ad5d4521b7314152a1465738fc78ab78'
& $godotExecutable --headless --path $interactionPath --editor --import --quit --log-file (Join-Path $interactionPath 'import.log')
& $godotExecutable --headless --path $interactionPath --script res://regression_runner.gd --log-file (Join-Path $interactionPath 'regression.log')
& $godotExecutable --headless --path $interactionPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $interactionPath 'ui-smoke.log')
& $godotExecutable --path $interactionPath --script res://capture.gd --quit-after 600 --log-file (Join-Path $interactionPath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary capture helper instantiates the UI, saves `opening-four.png`, prepares owned tool/Attack/Dodge fixtures via existing transfer APIs, invokes the UI selection controls and saves `hidden-tools.png` and `dodge-confirm.png`. It stays outside the repository. To try the changes, open `scenes/dev/playable_prototype.tscn`, press F6 or Bàn mới, select a source card/target, and use Dùng bài đã chọn.

## Historical Combat v0.5 / Stage 0.2 + Playable Prototype UI v0.2 — 2026-11-06

The following milestone records predate the opening-hand and card-choice follow-up above.

### Approved rules and implemented behavior
- **Counterclockwise turns:** Human/below -> Bot 1/left -> Bot 2/above -> Bot 3/right -> Human. TurnManager uses a validated seat-ID order (prototype `[1, 2, 3, 4]`), not node positions or player storage indices.
- **Automatic phases:** empty START/JUDGMENT, normal DRAW, satisfied DISCARD and empty END run automatically to the next decision. PLAY stops for Human **and** manually controlled Bots; only a valid explicit End Turn request exits it.
- ELIMINATED seats are skipped when starting/advancing and when the current actor is eliminated during PLAY/DISCARD. Seat search is bounded; with no eligible player, current player is null and progression stops without inventing a winner. A single survivor may continue because role victory is not implemented.
- Pending Attack Response / Dying Window (or unresolved DYING state) blocks direct TurnManager advance/restart, end turn, discard payment, and automatic progression. Executor binding uses a WeakRef; turn_started resets attack counters and synchronizes the controller tracker even for guarded low-level callers. A regression verifies that mixing direct executor/controller calls cannot grant an extra Attack by resetting that counter twice.
- Auto-advance has a hard maximum of 32 transitions, rejects budgets outside 1..32, detects no progress, and never automatically exits PLAY. A phase reached on the last permitted step is recognized as a valid decision stop.
- DISCARD queries RuleEngine, including personal/global hand-limit modifiers. The current actor selects an owned hand card and calls `CombatController.discard_for_turn()` -> ActionExecutor -> ActionValidator -> GameState. Invalid/duplicate/out-of-phase/non-owner requests fail; no card is selected or dropped automatically. When within the limit, progression resumes immediately.
- A nonempty judgment zone stops with an unsupported-effect message before DRAW. `set_phase_wait(phase, reason)` holds other unresolved effects/choices; an empty reason explicitly clears a hold. Missing/invalid hand-limit data also stops safely. Attack/discard actions cannot bypass an effect hold.
- Valid response/rescue/finalization resumes automatic phases; a completed action remains valid if a later phase is held. `get_status_message()` exposes the waiting/budget/no-player reason.

### UI v0.2
- Same F6 scene and four seat positions; visible counterclockwise order and highlighted active seat.
- Starts automatically in Human PLAY after the normal 2-card DRAW, with no opening-deal rule added.
- Normal **Kết thúc lượt** replaces Next Phase. During excess-hand DISCARD, the selected Human card can be submitted with **Bỏ lá đã chọn**; the wait prompt states how many remain. Buttons reflect current actor, phase and windows.
- Separate Debug controls select a Bot/card and offer Attack, Dodge/pass, simulated rescue, End Turn, selected-card discard, draw and automatic resume. Bots do not act automatically.
- UI only reads game state and calls engine APIs; no assignments to HP, life_state, pending_attack or current_phase. Unsupported card actions and judgment effects are reported. Roles, victory, skills, real rescue payment/order and AI are unchanged/unimplemented.

### Modified files
- Engine: `scripts/core/turn_manager.gd`, `scripts/combat/combat_controller.gd`, `scripts/actions/action_validator.gd`, `scripts/actions/action_executor.gd`.
- UI: `scripts/dev/playable_prototype.gd` (existing scene remains unchanged).
- Tests: `scripts/test/turn_manager_test.gd`, `scripts/test/combat_system_test.gd`, `scripts/test/dying_system_test.gd`, `scripts/test/playable_prototype_smoke.gd`.
- Docs: `docs/GDD.md`, `docs/ARCHITECTURE.md`, `docs/DEVELOPMENT_PLAN.md`, this file. Pre-existing edits were preserved. No commit/push.

Existing constructor signatures remain usable through optional arguments; `TurnManager.advance_phase() -> void` is preserved. Controller start now auto-progresses, and its old advance entry point resumes without ending PLAY. Affected tests were deliberately migrated to these approved semantics, retaining the same 13 regression suite classes and earlier card/combat/damage assertions.

### Actual validation results
- Godot `4.7.2.stable.official.ed1daf0bf`, fresh temporary project with `debug/gdscript/warnings/treat_warnings_as_errors=true`.
- **13/13 regression suites PASS**: ActionExecutor, ActionValidator, CardDatabase, CardModel, CardZone, CombatSystem, DamageRegistry, Deck, DyingSystem, GameState, RuleContext, RuleEngine, TurnManager.
- TurnManagerTest adds counterclockwise 2–5 seats with reversed player storage, adjacent/nonadjacent/current/last-player elimination, empty table, auto START/JUDGMENT/DRAW/PLAY, no implicit PLAY exit, explicit actor validation, no extra draws on resume, empty DISCARD skipping, selected/invalid/duplicate discards, unlimited hand modifiers, current-player elimination during DISCARD, direct transition/restart window guards, signal-driven attack reset, unsupported judgment/explicit holds, and budget boundary/invalid-budget stops.
- **UI smoke PASS**: actual mouse selection, Bot selector, Human/Bot Attack and Dodge, no-Dodge, blocked End Turn/windows, unsupported-card/range messages, interactive Human/Bot DISCARD, rescue/finalize, skipped eliminated Bot, restart and state integrity. No UI gameplay-state assignment.
- Passing logs have explicit suite/smoke completion output and no SCRIPT ERROR, GDScript warning, or suite-load failure; exit code alone was not used as proof.
- Rendered and visually inspected the v0.2 desktop OpenGL view at 1280x720, including active-seat highlight, order banner and a real DISCARD decision. `git diff --check` passed.
- Sandbox certificate/global-editor-settings diagnostics remain environment limitations, distinct from script errors. No permanent project setting was changed.

Exact commands for this run:

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$v05Path = 'C:/Users/Admin/AppData/Local/Temp/tactics-v05-36bb4c5e718f441aac16b36b9b086e70'
& $godotExecutable --headless --path $v05Path --editor --import --quit --log-file (Join-Path $v05Path 'import.log')
& $godotExecutable --headless --path $v05Path --script res://regression_runner.gd --log-file (Join-Path $v05Path 'regression.log')
& $godotExecutable --headless --path $v05Path --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $v05Path 'ui-smoke.log')
& $godotExecutable --path $v05Path --script res://capture.gd --quit-after 600 --log-file (Join-Path $v05Path 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

Temporary setup copies the workspace source/data/scenes/project into the recorded path and enables warnings-as-errors only in that copy. `regression_runner.gd` uses the same discovery/static-call runner reproduced in the historical record below. `capture.gd` instantiates the prototype, draws four extra Human cards through Debug, presses End Turn, waits for rendering, and saves `prototype-v02-preview.png`. Both helpers remain temporary. The permanent smoke command is `godot --headless --path . --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600` after editor import; inspect its explicit completion marker and errors.

**Remaining boundary:** Stage 0.3 non-attack lethal notification/nested events, judgment resolution, role/victory lifecycle, real rescue rules, equipment/skills/AI and complete MVP presentation. Do not start these without a new instruction.

## Implemented and verified for Stage 0.1 (historical milestone)
- [x] `ActionExecutor.respond_to_attack()` reaches `begin_dying()` after successful lethal attack damage and before returning success; the unreachable duplicate block is removed.
- [x] Lethal unblocked attacks leave the target at HP 0 / DYING and open the Dying Window.
- [x] `ActionExecutor.use_attack()` rejects new attacks during pending dying, including calls made directly to the executor.
- [x] Existing `CombatController.advance_phase()` and `start_game()` guards reject progression/restart during pending dying.
- [x] `DistanceCalculator` keeps DYING seats and excludes only ELIMINATED; its loop variables have explicit types.
- [x] Simulated rescue restores ALIVE, closes the window, and allows normal actions/phase progression to resume.
- [x] Finalizing dying sets ELIMINATED, closes the window, and removes that seat from distance counting.
- [x] `DyingSystemTest.run_all()` is invoked from `main.gd` alongside `DamageRegistryTest`.
- [x] Dying tests use controlled hands and disable automatic fixture draws, so shuffled deck order does not affect their assertions.

Turn-order removal was deliberately not part of Stage 0.1 acceptance; it is now implemented in Stage 0.2 above. Distance behavior remains unchanged.

## Existing engine foundations
- Card definitions/instances, JSON card/deck loaders, and a 12-card test deck.
- GameState, Player, card-zone transfers, and card-conservation checks.
- Six-phase TurnManager: START/JUDGMENT/DRAW/PLAY/DISCARD/END.
- RuleEngine, RuleModifier, RuleContext, circular distance, and source priority 300 > 200 > 100.
- Attack validation, response windows, Dodge, damage/healing primitives, and DamagePipeline modifier registry.
- Player ALIVE/DYING/ELIMINATED states and DyingManager simulated rescue/finalization.

## Historical Playable Prototype UI v0.1 — 2026-11-06

The controls/limits below describe v0.1 only; the current v0.2 behavior and commands are recorded above.

### Files and scope
- Added `scenes/dev/playable_prototype.tscn`: independent Control root, runnable with F6; no change to default startup.
- Added `scripts/dev/playable_prototype.gd` and its Godot UID: builds the Control-node layout at runtime, presents state, and connects mouse/button input to existing engine APIs.
- Added `scripts/test/playable_prototype_smoke.gd` and its UID: a separate SceneTree smoke script, not a replacement for any of the 13 regression suites.
- Updated this status document, preserving earlier records and pre-existing edits.
- No production engine, card JSON, `main.gd`, existing test, or `project.godot` change. No commit or push. Stop after Prototype v0.1.

### Playing the scene
1. Open `scenes/dev/playable_prototype.tscn` in Godot and press **F6**. The scene uses a 1280x720 canvas with aspect-preserving scaling; no image assets are required.
2. The dev table starts with four players at 4 HP and the current standard 12-card deck. No opening deal is invented. Press **Chuyển phase** three times to enter PLAY; the existing DRAW phase draws 2 cards for Human. Explicit **Debug: Rút 1** controls are also available.
3. Click a Human card and a seat, then **Tấn công**. Engine errors (wrong phase/turn/range/limit/ownership) are shown in the event log. Cards without an action API display an unsupported message and do not execute effects.
4. When Human is targeted, select a Dodge card and press **Né bằng bài đã chọn**, or choose **Không Né**. For a targeted Bot, select that Bot in the Debug panel, select its Dodge card if desired, and use **Bot: Né / Không Né**.
5. To control a Bot's turn, advance phases normally, select that Bot and an Attack card in Debug, click a target seat, then press **Bot: Attack**. Bots never decide or act automatically. Their cards are visible only in the explicitly labeled Debug selector.
6. At DYING, the victim becomes the selected target. Human or a selected Bot can request **Cứu +1 · mô phỏng** through the existing rescue API; **Finalize Dying** invokes finalization. Rescue does not consume cards because payment/order/self-rescue rules are still OPEN.
7. **Bàn mới** constructs a fresh dev table. Pending attacks/dying are not edited or cleared directly; replacing the dev session is separate from changing its gameplay state.

### API boundary and limits
- Attacks, responses, phase changes, rescue and finalization call `CombatController` APIs. Debug draws call `GameState.draw_card()`. No UI writes to HP, life state, pending attack, turn counters, or phase.
- Debug draws are blocked during pending response/dying and for non-ALIVE players. All normal phase progression goes through the existing controller guards.
- Seats show HP/max HP, ALIVE/DYING/ELIMINATED, hand counts, current turn, and selected target. The header shows phase/turn; the center shows pending response/dying and draw/discard counts. The event log retains the latest 100 entries.
- Healing-card use, Discard/Steal actions, opening deal, full JUDGMENT/DISCARD behavior, roles/victory, and AI are unavailable. The UI explains these limits instead of adding mechanics.
- Stage 0.2 remains unimplemented: an ELIMINATED seat may still receive a turn. The prototype displays this limitation and permits manual phase advance or a fresh table; it does not silently skip turns or implement victory logic.

### Validation
- Godot `4.7.2.stable.official.ed1daf0bf`; warnings-as-errors enabled only in a fresh temporary copy. Final UI smoke log has its completion marker and no SCRIPT ERROR or GDScript warning.
- UI smoke covers actual mouse events for Human card/target selection, Bot selector changes, unsupported-card feedback, invalid range, Human/Bot Attack, Human/Bot Dodge, no-Dodge, phase locks, lethal damage, rescue, finalization, restart and card conservation. Fixture preparation uses existing card-transfer APIs; no direct HP/phase/window mutation.
- **13/13 existing regression suites PASS**, with no script warnings/errors or load failures. Suites were checked by their own completion output, not process exit code alone. Existing test files were not changed.
- Rendered the scene using the desktop OpenGL compatibility renderer, saved and visually inspected its 1280x720 screenshot. Table seats, scrollable cards, action buttons and sidebar fit within the canvas.
- `git diff --check` passed. Sandbox certificate/editor-settings/shader-cache access diagnostics are environment limitations; they are distinct from script compilation/test results.

Exact validation commands (fresh temporary copy, with warnings-as-errors set in its copied `project.godot`):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$prototypePath = 'C:/Users/Admin/AppData/Local/Temp/tactics-prototype-3b46643394594523b9921a203bb19bdb'
& $godotExecutable --headless --path $prototypePath --editor --import --quit --log-file (Join-Path $prototypePath 'import.log')
& $godotExecutable --headless --path $prototypePath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $prototypePath 'ui-smoke.log')
& $godotExecutable --headless --path $prototypePath --script res://regression_runner.gd --log-file (Join-Path $prototypePath 'regression.log')
& $godotExecutable --path $prototypePath --script res://capture.gd --quit-after 600 --log-file (Join-Path $prototypePath 'capture.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary regression runner discovers all `scripts/test/*_test.gd` and calls their static `run_all()` methods as documented below. `capture.gd` instantiates the prototype, advances to PLAY through UI signals, draws four additional Human cards through the Debug control, waits for a rendered frame and saves `prototype-preview.png` under the temporary project. Both helper scripts stay outside the repository. The permanent UI smoke can also run with `godot --headless --path . --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600` after normal editor import; inspect its explicit completion marker and errors.

## Latest verification — 2026-11-06: Card/Deck test API migration

Only `scripts/test/card_zone_test.gd`, `scripts/test/deck_test.gd`, and this status document changed in this task. No production APIs, gameplay rules, card data, Combat code, or TurnManager behavior changed.

### Follow-up verification of the current workspace

The repeated Card/Deck repair request was checked against the current files: both API migrations were already present, so no additional code changes were needed. A fresh temporary copy was imported and all 13 suites were run again with Godot `4.7.2.stable.official.ed1daf0bf` and warnings-as-errors enabled. **13/13 PASS**, including CardZoneTest and DeckTest, with no SCRIPT ERROR, suite load failure, or GDScript warning. Each suite's completion output was inspected. Only this status document changed in the follow-up; Stage 0.2, gameplay, and public APIs remain untouched. No commit or push was performed.

Exact follow-up commands (same temporary-copy setup and runner as the historical Stage 0.1 runner reproduced below, named `recheck_runner.gd`):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$recheckPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-recheck-cf022aa4cc1c4b8983cc2f11d268f830'
& $godotExecutable --headless --path $recheckPath --editor --import --quit --log-file (Join-Path $recheckPath 'import.log')
& $godotExecutable --headless --path $recheckPath --script res://recheck_runner.gd --log-file (Join-Path $recheckPath 'regression.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The runner asserted and printed `WARNINGS_AS_ERRORS=true`. The same sandbox certificate-store and global-editor-settings diagnostics occurred; they are environment diagnostics, not script test failures. Workspace `project.godot` was not modified.

### Reproduced root causes

1. **CardZoneTest runtime error:** the old line 83 called `CardZoneManager.validate_unique_cards()`, which does not exist. The current API is `validate_integrity()`: it checks duplicate IDs, membership in the original deck, and card conservation across every tracked zone. The test now calls this API initially and after successful/rejected transfers, and checks the physical card reference and zone counts. No assertion was removed to bypass integrity verification.
2. **DeckTest parse failure:** the old lines 66 and 89 inferred variables from `Deck.draw()`, a method that no longer exists, so GDScript could not determine their types. The test also called nonexistent `Deck.discard()`. Adding annotations alone would leave invalid runtime calls. Drawing/discarding now belongs to `GameState.draw_card()` / `discard_card()` through CardZoneManager. DeckTest now constructs a real GameState and Player, retains its seven original test stages, and uses those transfers. It verifies empty draws, unknown-player rejection, duplicate-discard rejection, ownership, recycling, the original ID set, and integrity throughout. Touched variables and loops use explicit types and TAB indentation; shuffle assertions do not depend on random card order.

### Fresh regression results

| Suite | Latest result |
|---|---|
| ActionExecutorTest | PASS |
| ActionValidatorTest | PASS |
| CardDatabaseTest | PASS |
| CardModelTest | PASS |
| CardZoneTest | PASS |
| CombatSystemTest | PASS |
| DamageRegistryTest | PASS |
| DeckTest | PASS |
| DyingSystemTest | PASS: all 7 test groups |
| GameStateTest | PASS |
| RuleContextTest | PASS |
| RuleEngineTest | PASS |
| TurnManagerTest | PASS for its existing scenarios; Stage 0.2 remains unimplemented |

Engine: `4.7.2.stable.official.ed1daf0bf`. Before changing the tests, both failures were reproduced in a fresh temporary project with warnings-as-errors enabled. After copying only the two repaired tests into that project, all 13 suites emitted their own successful completion output, with **no SCRIPT ERROR, load failure, or GDScript warning**. The runner asserted the warnings-as-errors project setting and printed `WARNINGS_AS_ERRORS=true`. Process exit code was 0, but the result was verified from the complete suite output, not exit code or `SUITE_RETURNED` alone.

### Commands and evidence

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$cardDeckPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-carddeck-71c45390a8f344268234c5ba7bd52b33'
& $godotExecutable --headless --path $cardDeckPath --editor --import --quit --log-file (Join-Path $cardDeckPath 'import.log')
# Reproduce both failures before replacing the temporary tests.
& $godotExecutable --headless --path $cardDeckPath --script res://carddeck_runner.gd --log-file (Join-Path $cardDeckPath 'before.log') -- card_zone_test.gd deck_test.gd
# Copy the repaired tests from the workspace, then run every suite.
Copy-Item -LiteralPath scripts/test/card_zone_test.gd,scripts/test/deck_test.gd -Destination (Join-Path $cardDeckPath 'scripts/test')
& $godotExecutable --headless --path $cardDeckPath --script res://carddeck_runner.gd --log-file (Join-Path $cardDeckPath 'after.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

Temporary project setup is the same as the earlier record below, with `debug/gdscript/warnings/treat_warnings_as_errors=true` appended only to the copied project. `carddeck_runner.gd` uses the reproduced runner below with the suite-list declaration replaced by:

```gdscript
	var suites: PackedStringArray = OS.get_cmdline_user_args()
	if suites.is_empty():
		suites = DirAccess.get_files_at("res://scripts/test")
```

This permits the two-suite reproduction and the full 13-suite run without skipping any failing suite. Logs are `before.log` and `after.log` at the recorded temporary path; no runner was added to production. The sandbox's root-certificate-store diagnostic and global-editor-settings save error during import remain environment limitations, not script failures. Workspace project settings were not changed. `git diff --check` passed.

## Historical Stage 0.1 testing record — 2026-11-06

Tests ran against a temporary copy of the current source, data, and scene using the installed Godot CLI. Only the temporary project enabled `debug/gdscript/warnings/treat_warnings_as_errors=true`; the workspace's project settings were not changed.

| Suite | Result |
|---|---|
| ActionExecutorTest | PASS |
| ActionValidatorTest | PASS |
| CardDatabaseTest | PASS |
| CardModelTest | PASS |
| CardZoneTest | FAIL: runtime call to nonexistent `validate_unique_cards()` at line 83 |
| CombatSystemTest | PASS |
| DamageRegistryTest | PASS |
| DeckTest | FAIL: parse/type-inference errors at lines 66 and 89; test still references removed `Deck.draw()` / `discard()` APIs |
| DyingSystemTest | PASS: all 7 test groups |
| GameStateTest | PASS |
| RuleContextTest | PASS |
| RuleEngineTest | PASS |
| TurnManagerTest | PASS for its existing scenarios; does not verify Stage 0.2 behavior |

DyingSystemTest covers nonlethal damage, Dodge, reduced/cancelled damage, repeated invalid responses, overkill, lethal damage/rescue, and elimination/distance. It also checks pending-window guards and rejected rescue/finalization requests. Overkill retains the existing HP-at-zero model; no negative-HP rescue rule was introduced.

The scene smoke test executed both selected suites through `main.gd` successfully. `git diff --check` passed.

### Exact commands executed

PowerShell variables used for the recorded run:

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$stage01Path = 'C:/Users/Admin/AppData/Local/Temp/tactics-stage01-b60109f09ecb4c7fa57c8f963aadc73e'
& $godotExecutable --headless --path $stage01Path --editor --import --quit --log-file (Join-Path $stage01Path 'import.log')
& $godotExecutable --headless --path $stage01Path --script res://stage01_runner.gd --log-file (Join-Path $stage01Path 'regression.log')
& $godotExecutable --headless --path $stage01Path res://scenes/main.tscn --quit-after 1 --log-file (Join-Path $stage01Path 'scene.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

The temporary `stage01_runner.gd` is reproduced below so the regression invocation can be recreated in a fresh temporary project. Copy `scripts/`, `data/`, `scenes/`, `project.godot`, `main.gd`, `main.gd.uid`, and `icon.svg`; enable warnings-as-errors in that copy, save this script at its root, import, and run the commands with the new path. On a machine without this executable path, substitute its installed Godot binary.

```gdscript
extends SceneTree

func _initialize() -> void:
	assert(ProjectSettings.get_setting("debug/gdscript/warnings/treat_warnings_as_errors"))
	print("WARNINGS_AS_ERRORS=true")
	var suites: PackedStringArray = DirAccess.get_files_at("res://scripts/test")
	suites.sort()
	for suite_path: String in suites:
		if not suite_path.ends_with("_test.gd"):
			continue
		print("SUITE_BEGIN: ", suite_path)
		var suite: Script = load("res://scripts/test/" + suite_path)
		if suite == null or not suite.can_instantiate():
			print("SUITE_LOAD_FAILED: ", suite_path)
			continue
		suite.call("run_all")
		print("SUITE_RETURNED: ", suite_path)
	quit()
```

This temporary runner attempts every suite; `SUITE_RETURNED` is **not** a pass marker because GDScript runtime errors can return control to the caller. Results above were determined by inspecting each suite's completion output and SCRIPT ERROR entries in `regression.log`, including the two failures despite process exit code 0.

The sandbox also reported root-certificate-store access errors and could not save global Godot editor settings during import. These environment diagnostics are separate from the two script-test failures; no GDScript warnings/errors were reported for the passing suites.

## Remaining work after Combat v0.5
- **Stage 0.2 completed:** guarded transitions, eliminated-seat skipping, current-player elimination and bounded no-eligible-player handling are verified above.
- **Stage 0.3:** centralize lethal-damage notification. The Dying-priority follow-up now discovers direct DamagePipeline/EffectResolver DYING at guard/controller boundaries; immediate damage-event registration and nested/simultaneous lethal events still need an explicit contract.
- **Resolved test debt:** the approved CardZoneTest/DeckTest migration above now passes against existing production APIs; obsolete APIs were not restored.
- **Paid rescue implemented:** self/other eligibility, card payment and negative HP are now covered above. Ordered rescue passes/timing remain OPEN; simultaneous/nested damage still needs a contract.
- **Later milestones:** role/victory lifecycle, initial deal, judgment, equipment/tool actions, approved characters, bots, and complete MVP UI. Selected-card hand-limit discard and the manual Prototype v0.2 are now available.
- Workspace `project.godot` still has no default main scene or warnings-as-errors setting. The explicit scene/script commands above were used; most optional test calls in `main.gd` remain commented out.

## Change log

### 2026-11-06 — Numeric suit values in deck JSON
- Files changed: `data/decks/standard.json`, `scripts/cards/deck_database.gd`, `scripts/test/deck_test.gd`, this status document. Pre-existing workspace edits were preserved.
- Converted only suit values in the current standard deck to integers 0..3. Example: `{"suit": 1, "rank": 7}` represents 7 hearts. Each copy is still one physical card; add/remove copies to change quantities. No deck expansion or balance change.
- DeckDatabase validates finite whole numbers in 0..3 and retains legacy strings (`spades`, `hearts`, `diamonds`, `clubs`), including mixed files. It normalizes accepted values to the existing string-based entries format, preserving public APIs and CardInstance enum/display behavior.
- DeckTest adds loader/instance coverage for all four numeric and named suits, JSON numeric representation, red/black mapping, mixed input, and rejection of fractions, out-of-range values, booleans, null, unknown/numeric strings and containers. Invalid loads expose no partial deck. Temporary fixture files are removed after loading.
- Validation: Godot `4.7.2.stable.official.ed1daf0bf`, warnings-as-errors enabled only in a fresh temporary copy; **13/13 regression suites PASS and UI smoke PASS**, no script errors/warnings/load failures. `git diff --check` passed. The known sandbox certificate/editor-settings diagnostics are unchanged.
- Exact validation commands (temporary setup/runner follows the earlier records):

```powershell
$godotExecutable = 'E:/Projects/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe'
$suitPath = 'C:/Users/Admin/AppData/Local/Temp/tactics-suits-b616ec612e8b417c8386a4295dc72fdd'
& $godotExecutable --headless --path $suitPath --editor --import --quit --log-file (Join-Path $suitPath 'import.log')
& $godotExecutable --headless --path $suitPath --script res://regression_runner.gd --log-file (Join-Path $suitPath 'regression.log')
& $godotExecutable --headless --path $suitPath --script res://scripts/test/playable_prototype_smoke.gd --quit-after 600 --log-file (Join-Path $suitPath 'ui-smoke.log')
git -c safe.directory=E:/Projects/Godot/tactics diff --check
```

- Commit/PR: none. No further milestone was started.

### 2026-11-06 — Combat v0.5 / Stage 0.2 and Playable Prototype UI v0.2
- Scope/files/commands/results: recorded in the current milestone above. Approved counterclockwise and automatic-decision-phase rules are reflected in all four docs.
- Result: 13/13 regression suites and UI smoke PASS under warnings-as-errors; desktop visual verification complete.
- Remaining risks: Stage 0.3 and OPEN gameplay rules remain outside this change. No automatic winner or rescue payment was added.
- Commit/PR: none. Stop after Combat v0.5 / UI v0.2.

### 2026-11-06 — Stage 0.1: stabilize attack-driven Dying integration
- Scope: lethal attack -> Dying Window -> rescue/elimination, pending-window guards, DYING seat distance, and regression evidence. Existing Stage 0.1 fixes were retained rather than rewritten.
- Milestone files: `scripts/actions/action_executor.gd`, `scripts/rules/distance_calculator.gd`, `scripts/test/dying_system_test.gd` (with its existing UID), `main.gd`, and this status document.
- This completion pass added repeated-invalid-response and overkill tests, explicit distance-loop types, and the current status/testing record. DyingManager, CombatController, TurnManager, card data, and unrelated tests were not modified.
- Tests/commands/results: recorded above; Stage 0.1 tests pass, full regression remains 11/13 due to two pre-existing failures.
- Remaining risks: direct turn bypass and turn skipping (Stage 0.2), non-attack lethal notification (Stage 0.3), and OPEN rescue rules.
- Commit/PR: none. Stop after Stage 0.1; Stage 0.2 requires a separate instruction.

### 2026-11-06 — Repair Card/Deck regression API drift
- Scope: resolve the reproduced CardZoneTest runtime error and DeckTest parse failure by migrating tests to the current card-ownership APIs while preserving and strengthening their assertions.
- Files changed: `scripts/test/card_zone_test.gd`, `scripts/test/deck_test.gd`, `docs/DEVELOPMENT_STATUS.md`.
- Tests run: targeted pre-fix reproduction, then all 13 suites under warnings-as-errors; exact commands recorded in the latest verification section.
- Result: 13/13 PASS; no GDScript errors/warnings. The historical Stage 0.1 run remains 11/13 and has not been relabeled as passing.
- Remaining limitations: sandbox certificate/editor-settings diagnostics, no permanent full-suite headless runner, direct-turn bypass/turn skipping (Stage 0.2), and non-attack lethal notifications (Stage 0.3).
- Commit/PR: none. Stage 0.2 was not started; gameplay and public APIs are unchanged.
