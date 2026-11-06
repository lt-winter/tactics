# Tactics — Codex Instructions

## Project identity
- Game: **Tactics** (working project name; earlier design references may use Huyền Ấn).
- Target: Windows PC, offline single-player against three bots.
- Engine: Godot 4, GDScript. Current theme: Western / Viễn Tây.
- Design direction: BANG!-like setting and accessibility, with deeper tactical interactions inspired by Tam Quốc Sát.
- Read `docs/GDD.md`, `docs/ARCHITECTURE.md`, `docs/DEVELOPMENT_PLAN.md`, and `docs/DEVELOPMENT_STATUS.md` before modifying gameplay code.

## Non-negotiable engineering rules
1. Use literal **TAB** indentation for every GDScript block. Do not reformat existing scripts to spaces.
2. Use explicit GDScript types where inference could yield `Variant`. Treat warnings as errors.
3. Preserve working public APIs, `class_name` declarations, resource paths, and existing tests unless a deliberate migration is approved.
4. Do not prepend `Huyen` to class names. Follow existing naming (`GameState`, `TurnManager`, etc.).
5. Separate game rules, state transitions, card data, AI decisions, and presentation.
6. Prefer minimal, reviewable changes. Avoid unrelated refactoring.
7. For changes to a mechanic, add regression tests and test edge cases.
8. Do not silently invent rules. Mark unresolved decisions and ask.
9. Do not claim tests passed unless they were actually run. If Godot CLI is unavailable, state this explicitly.
10. Never commit, push, delete substantial code, or modify the repository's default branch without explicit instruction.

## Source of truth and conflicts
- The repository code describes **implemented behavior**, not necessarily final intended rules.
- `docs/GDD.md` describes **target gameplay** and clearly labels proposals/open questions.
- `docs/DEVELOPMENT_STATUS.md` distinguishes implemented, tested, and planned work.
- If code and docs conflict, report the discrepancy and propose a migration; do not silently rewrite either.
- Historical chat summaries and speculative design are not authoritative over these docs.

## Standard task workflow
1. Read relevant docs and code, including call sites and tests.
2. State the scope, expected behavior, and files to touch.
3. Implement one cohesive change.
4. Run available checks/tests; inspect errors and warnings.
5. Report diff summary, test evidence, remaining limitations.
6. Update `docs/DEVELOPMENT_STATUS.md` when work changes the implementation state.
7. Wait for approval before starting the next milestone.

## Testing notes
- Tests currently live in `res://scripts/test/` (singular), **not** `scripts/tests/`.
- Test classes expose static `run_all()` methods; `res://main.gd` selects which tests to invoke.
- Current `main.gd` has most test calls commented out. Do not interpret this as evidence that they all pass.
- If adding automated headless test invocation, ensure project startup scene/test runner is configured and document the command.
- Keep tests deterministic where practical; seed or control randomness.

## First task for Codex
Audit and fix Dying System integration **before** implementing Turn Guard:
- Remove unreachable code in `ActionExecutor.respond_to_attack()`.
- Ensure lethal attack damage opens a Dying Window.
- Prevent new attacks and phase changes during pending dying.
- Confirm the intended distance behavior for DYING players.
- Add `DyingSystemTest` and run regression tests.
- Do not implement Turn Guard until the Dying integration tests pass.
