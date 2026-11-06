# Project Instructions

## Technology

- Godot 4
- GDScript
- Offline PC card game

## Coding Rules

- Use TAB indentation, never spaces.
- Use explicit type annotations.
- Treat GDScript warnings as errors.
- Preserve existing class names and public APIs.
- Do not rewrite working systems unnecessarily.
- Keep game content in JSON where appropriate.

## Architecture

- GameState owns game state.
- TurnManager manages turn phases.
- RuleEngine resolves gameplay rules.
- ActionValidator validates actions.
- ActionExecutor executes validated actions.
- DamagePipeline resolves damage.
- DyingManager handles dying and elimination.

## Workflow

1. Read relevant files before proposing changes.
2. Check dependencies between classes.
3. Make minimal, targeted modifications.
4. Add or update tests.
5. Run available tests when possible.
6. Report modified files and test results.
