# Tactics — Development Status

**Workspace verified:** `E:\Projects\Godot\tactics`, 2026-11-06, Godot `4.7.2.stable.official.ed1daf0bf`.
**Evidence standard:** implemented behavior, executed tests, and future work are recorded separately. A zero Godot process exit code alone does not establish a test pass.

## Current snapshot
- Stage 0.1 — Dying integration is implemented and its scoped regression tests pass.
- Latest Card/Deck regression repair: **13/13 suites passed** with GDScript warnings-as-errors enabled in the temporary test project. The previous 11/13 Stage 0.1 result is retained below as historical evidence.
- Stage 0.2 / Combat v0.5 has **not** been started. Wait for explicit approval before proceeding.
- `AGENTS.md` and all four handoff documents are present locally. `ARCHITECTURE.md` retains the earlier GitHub snapshot; its unreachable-code, pending-dying attack, distance, and missing-DyingSystemTest findings are resolved in this workspace as recorded below.
- No commit or push was performed. Pre-existing workspace edits and handoff files were preserved.

## Implemented and verified for Stage 0.1
- [x] `ActionExecutor.respond_to_attack()` reaches `begin_dying()` after successful lethal attack damage and before returning success; the unreachable duplicate block is removed.
- [x] Lethal unblocked attacks leave the target at HP 0 / DYING and open the Dying Window.
- [x] `ActionExecutor.use_attack()` rejects new attacks during pending dying, including calls made directly to the executor.
- [x] Existing `CombatController.advance_phase()` and `start_game()` guards reject progression/restart during pending dying.
- [x] `DistanceCalculator` keeps DYING seats and excludes only ELIMINATED; its loop variables have explicit types.
- [x] Simulated rescue restores ALIVE, closes the window, and allows normal actions/phase progression to resume.
- [x] Finalizing dying sets ELIMINATED, closes the window, and removes that seat from distance counting.
- [x] `DyingSystemTest.run_all()` is invoked from `main.gd` alongside `DamageRegistryTest`.
- [x] Dying tests use controlled hands and disable automatic fixture draws, so shuffled deck order does not affect their assertions.

Turn-order removal is deliberately **not** part of Stage 0.1 acceptance: DEVELOPMENT_PLAN.md assigns it to Stage 0.2. Distance removal is verified here; turn skipping remains incomplete.

## Existing engine foundations
- Card definitions/instances, JSON card/deck loaders, and a 12-card test deck.
- GameState, Player, card-zone transfers, and card-conservation checks.
- Six-phase TurnManager: START/JUDGMENT/DRAW/PLAY/DISCARD/END.
- RuleEngine, RuleModifier, RuleContext, circular distance, and source priority 300 > 200 > 100.
- Attack validation, response windows, Dodge, damage/healing primitives, and DamagePipeline modifier registry.
- Player ALIVE/DYING/ELIMINATED states and DyingManager simulated rescue/finalization.

## Latest verification — 2026-11-06: Card/Deck test API migration

Only `scripts/test/card_zone_test.gd`, `scripts/test/deck_test.gd`, and this status document changed in this task. No production APIs, gameplay rules, card data, Combat code, or TurnManager behavior changed.

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

## Remaining work — not implemented in Stage 0.1
- **Stage 0.2:** guard direct `TurnManager.advance_phase()` access, skip ELIMINATED seats, define current-turn elimination and no-eligible-player behavior without loops. Public signatures remain unchanged.
- **Stage 0.3:** centralize lethal-damage notification. Direct DamagePipeline/EffectResolver damage outside the attack-response path does not automatically register pending dying. Nested lethal events need an explicit contract.
- **Resolved test debt:** the approved CardZoneTest/DeckTest migration above now passes against existing production APIs; obsolete APIs were not restored.
- **Simulation only:** rescue payment, order, pass/self-rescue rules, and real healing-card use are OPEN in GDD. Existing rescue behavior was preserved.
- **Later milestones:** role/victory lifecycle, initial deal, hand-limit discard, judgment, equipment/tool actions, approved characters, bots, and playable UI.
- Workspace `project.godot` still has no default main scene or warnings-as-errors setting. The explicit scene/script commands above were used; most optional test calls in `main.gd` remain commented out.

## Change log

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
