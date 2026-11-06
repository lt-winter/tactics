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
- Ensure direct `TurnManager` phase changes cannot bypass pending windows.
- Skip ELIMINATED seats, including when current player is eliminated.
- Handle no eligible next player / game-over without loops.
- Preserve compatibility with existing `TurnManagerTest` and `CombatSystemTest`.
- Test 2–5 seats, adjacent and nonadjacent elimination, direct bypass attempt.

**0.3 Centralized damage/dying event**
- Any lethal damage source must open dying processing, not just attack responses.
- Define event/transition order and ensure at most one unresolved dying window per current MVP contract.
- Explicitly design nested lethal events before implementation.

## Stage 1 — Complete core game rules
- Role data and assignment (1 Sheriff, 2 Outlaws, 1 Renegade).
- Role visibility and victory evaluator.
- Initial draw and hand-limit discard.
- Finish judgment phase and game-end transitions.
- Implement real healing-card rescue with correct payment/turn order after rule approval.

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

## Recommended first Codex task
Read `AGENTS.md` and `docs/` then fix **Stage 0.1 only**. Do not start Stage 0.2 automatically.
