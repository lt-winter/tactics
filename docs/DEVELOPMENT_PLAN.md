# Tactics — Development Plan

**Principle:** incremental, tested milestones. No milestone is complete merely because its files exist. Progress is recorded in `DEVELOPMENT_STATUS.md`.

## Stage 0 — Stabilize existing Combat v0.4 (highest priority)
**0.1 Dying integration fix**
- Remove unreachable Dying Window logic from `ActionExecutor.respond_to_attack`.
- Open `DyingManager.begin_dying()` after lethal attack damage and before returning.
- Block `use_attack` while a Dying Window is pending.
- Update distance calculation to exclude only ELIMINATED.
- Add `scripts/test/dying_system_test.gd`, invoke it in a test runner.
- Test: lethal hit -> DYING -> phase blocked -> rescue -> resume; lethal hit -> elimination -> distance changes.
- Test: nonlethal attack, dodge, canceled damage and repeated invalid responses.
- Run previous regression tests.

**0.2 Turn Guard & Elimination Handling (Combat v0.5)**
**Implemented with Prototype UI v0.2, 2026-11-06; see DEVELOPMENT_STATUS.md for executed checks.**
- Approved rule: counterclockwise Human/below -> Bot 1/right -> Bot 2/above -> Bot 3/left -> Human, represented by engine seat IDs independently of UI nodes. The latest UI correction swaps Bot 1/Bot 3 positions while retaining the named turn sequence.
- Approved rule: automatically process phases without decisions; stop at PLAY until explicit End Turn, at excess-hand DISCARD until validated card choices, and at unresolved effects/windows.
- Ensure direct `TurnManager` phase changes cannot bypass pending windows.
- Skip ELIMINATED seats, including when current player is eliminated.
- Handle no eligible next player / game-over without loops.
- Preserve compatibility with existing `TurnManagerTest` and `CombatSystemTest`.
- Test 2–5 seats, adjacent and nonadjacent elimination, direct bypass attempt.
- Bound auto-advance to 32 steps, reject invalid budgets, and detect lack of progress. No eligible seat is a stopped state, not a victory rule.
- Add validated end-turn and selected-card discard APIs. Respect RuleEngine hand-limit modifiers; do not select discards automatically.
- UI v0.2: show direction/active seat, replace normal Next Phase with End Turn, present DISCARD choices, preserve a separate manual Bot Debug area and the existing F6 scene.
- Run the same 13 regression suites plus the separate UI smoke with warnings-as-errors; update GDD/ARCHITECTURE/STATUS. Stop before Stage 0.3.

**0.3 Centralized damage/dying event**
- Dying-priority follow-up now discovers existing DYING states at guard/controller boundaries and displays a blocking modal. This targeted fix is implemented; centralized damage events and simultaneous/nested damage semantics below remain planned.
- Any lethal damage source must open dying processing, not just attack responses.
- Define event/transition order and ensure at most one unresolved dying window per current MVP contract.
- Explicitly design nested lethal events before implementation.

## Stage 1 — Complete core game rules
- Healing/UI follow-up implemented: owned healing-card self-use during the actor's PLAY, current-actor hand display for manual Bot debug, and shared Đồng ý / Huỷ bỏ card controls. The latest follow-up adds paid self/other Dying rescue with preserved negative HP; normal healing of another living player and AI remain outside scope.
- Opening/interaction follow-up implemented: four opening cards each, normal 2-card DRAW on every turn including the first (latest correction), explicit target Dodge confirmation, and face-down Discard/Steal selection using the existing JSON effects. All six displayed phase names are Vietnamese. See STATUS for current verification; centralized Stage 0.3 damage events remain planned.
- Role data and assignment (1 Sheriff, 2 Outlaws, 1 Renegade).
- Role visibility and victory evaluator.
- Verify opening-deal and hand-limit-discard behavior as game setup expands to roles/characters.
- Finish judgment phase and game-end transitions.
- Paid healing-card rescue implemented under the latest approved rule: self or another living player, one owned card per use, preserve negative HP, close only above zero. Ordered pass/timing protocol remains OPEN. Descriptions use cards.json; effect values remain in JSON parameters.

## Stage 2 — Full approved MVP card deck
- Finalize 48-card distribution with designer approval.
- Implement remaining tool/equipment effects and weapon range.
- Ensure action validation, card movement and effect resolution are consistent.
- Add equipment slot and target-selection tests.

## Stage 3 — Characters and abilities
- Finalize Cole, Rose, Jack and Morgan skill wording.
- Implement character skill lifecycle (registration, activation, removal).
- Test rule override priority 300 > 200 > 100 and damage triggers.
- Avoid duplicating character-specific branches in generic engine code.

## Stage 4 — Offline bots
- Action enumerator and legal move generator.
- Deterministic baseline bot.
- Role-aware scoring, tactical resource decisions, hidden-information discipline.
- Automated bot-vs-bot simulation and deadlock detection.

## Stage 5 — Playable PC interface
- Hand/deck/discard UI, four seats, HP, role, active phase, action log.
- Target selection and reaction/rescue prompts.
- Game setup, end screen, pause/restart.
- Basic usability and accessibility review.

## Stage 6 — Balance, packaging, polish
- Test complete matches and rule edge cases.
- Tune deck and characters using match simulations.
- Add audio/art assets with clear rights.
- Export Windows build and perform smoke tests.

## Codex task contract
For each task:
1. Identify exact files and existing tests.
2. State acceptance criteria before changes.
3. Implement minimal patch, not a sweeping rewrite.
4. Run test command (or report why unavailable).
5. Update status with evidence.
6. Stop and wait for approval before the next milestone.

## Next milestone boundary
Stage 0.1, Stage 0.2 / Prototype UI v0.2 and subsequent explicitly requested UI/healing/paid-rescue follow-ups are implemented. Read `AGENTS.md` and `docs/` for future tasks; **do not start centralized Stage 0.3 or other milestones without a new instruction**. Ordered rescue passes/timing, roles/victory and skills remain outside this change.
