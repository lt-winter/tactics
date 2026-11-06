# Tactics — Game Design Document (GDD v0.3 handoff)

**Status:** Working design handoff, consolidated 2026-11-06. This document preserves previously agreed direction, but is **not** a claim that every rule is fully specified or implemented.

## 1. Vision
- Platform: Windows PC first.
- Mode: offline, one human and three AI bots; online/multiplayer is outside MVP.
- Theme: Western (Viễn Tây) as the current working theme, replacing an earlier original-fantasy theme.
- Experience: social-deduction roles, hidden information, cards, reactions, character abilities, and tactical decisions.
- Inspiration: BANG! for Western flavor and approachable roles; Tam Quốc Sát for tactical depth. Do not copy protected artwork, text, or characters.

## 2. MVP match setup
- Four seats arranged around a circular table.
- One human, three bots.
- Proposed MVP role set: **1 Sheriff, 2 Outlaws, 1 Renegade**; no Deputy at four players.
- Sheriff role is public; other roles hidden until the applicable reveal rule is implemented.
- Proposed Sheriff bonus: +1 maximum HP.
- Initial hand: cards equal to starting maximum HP (design intention, not yet implemented).
- Match ends by role victory conditions, not simply by running out of cards.

## 3. Role objectives — provisional interpretation
- **Sheriff:** eliminate all opposing roles while remaining alive.
- **Outlaws:** win if the Sheriff is eliminated.
- **Renegade:** be the sole survivor after the Sheriff is eliminated.
- **Open decision:** exact resolution priority if Sheriff and Renegade are eliminated in one effect, and whether the Sheriff wins immediately when all others are eliminated. These must be expressed as deterministic tests before implementation.
- Do not infer the final role/identity system from current `Player`: role storage is not implemented yet.

## 4. Turn structure
Current engine phase enum: `START -> JUDGMENT -> DRAW -> PLAY -> DISCARD -> END -> next player`.
- START: begin turn, reset per-turn counters.
- JUDGMENT: resolve delayed effects (planned; no complete judgment mechanics yet).
- DRAW: default draw 2 cards.
- PLAY: play legal cards and open reaction windows.
- DISCARD: hand limit normally equals current HP; automatic/interactive discard behavior is not complete.
- END: end-of-turn effects, move to next eligible player.
- **Open decision:** handling of zero HP / current-turn elimination mid-turn and timing of triggered abilities.

## 5. Combat and distance
- Base attack range: 1 seat.
- Base limit: one attack card per turn.
- Circular distance = minimum clockwise/counterclockwise seat separation among participants who still occupy seats.
- `ELIMINATED` players are removed from distance counting.
- `DYING` players still occupy their seats until elimination; they cannot normally act.
- Attack opens a response window. A valid Dodge cancels the attack; otherwise damage enters DamagePipeline.
- Damage modifiers may reduce/increase/cancel damage before HP is changed.
- Reaching 0 HP enters DYING. Rescue must be resolved before normal play resumes; unresolved DYING becomes ELIMINATED.
- Rescue card payment, rescue order, and timing are **not yet implemented**. Existing `rescue_player(..., heal_amount)` is a simulation API only.

## 6. Rule override precedence — agreed
Priority is **source-based**, not an arbitrary 0–3 level:
1. Character skill (`CHARACTER_SKILL = 300`)
2. Card/equipment effect (`CARD_EFFECT = 200`)
3. Base rule (`BASE_RULE = 100`)

Example: a 'Liên kích' skill may remove the per-turn attack count limit, but **does not** automatically waive range, target, phase, card ownership, or other independent validations.

Current `RuleModifier` operations: `set`, `remove_limit`. Additional operations must be designed explicitly.

## 7. Cards
### Planned 48-card MVP pool (historical GDD v0.3 proposal)
| Card | Copies | Intended role |
|---|---:|---|
| Bắn! | 16 | Attack |
| Né! | 12 | Reaction defense |
| Bia | 6 | Healing / rescue |
| Cướp bóc | 4 | Steal |
| Do thám | 4 | Information or tactical interaction; precise effect **not finalized** |
| Súng lục | 2 | Equipment |
| Súng trường | 2 | Equipment |
| Áo giáp | 2 | Defensive equipment |
| **Total** | **48** | |

**Design conflict requiring approval:** A later planning summary proposed **18 Bắn!, 12 Né!, 6 Bia, 4 Cướp bóc, 4 Do thám, 2 weapons, 2 armor** (also 48). This handoff uses the earlier eight-entry breakdown as a **working baseline, not a final signed-off deck**. Ask before expanding the JSON deck.

### Actual repository state (2026-11-06)
`data/cards.json` currently defines **five** card IDs:
- `attack` / `deal_attack`
- `dodge` / `block_attack`
- `heal` / `restore_hp`
- `discard` / `discard`
- `steal` / `steal_card`

`data/decks/standard.json` contains **12 instances**: 4 attack, 3 dodge, 2 heal, 1 discard, 2 steal. This is an **engine test deck**, not the planned 48-card MVP deck.

**Mapping warning:** Planned 'Do thám' does not have an agreed one-to-one mapping to implemented `discard`. Do not silently rename or conflate them.

## 8. MVP characters — working roster
These were proposed in the earlier v0.3 design and need ability wording/balance confirmation before coding:
- **Cole**, 4 HP: at low HP (historical wording: <=2 HP), can play up to 2 Bắn! in a turn.
- **Rose**, 3 HP: when rescuing another player with Bia, draws 1 card.
- **Jack**, 4 HP: when his Bắn! is blocked by Né!, draws 1 card.
- **Morgan**, 4 HP: reduces the first damage received each turn by 1.
- The separately discussed **Liên kích** is an example of rule override; do not automatically assign it to one of these four characters.
- No character-skill implementation is currently verified in the repository.

## 9. AI bot requirements
The bots must use the **same validated action interfaces** as human players; no direct mutation of HP, hands, or game phase.
Suggested implementation order:
1. Legal action generation.
2. Simple baseline policy (play heal if beneficial, attack a valid opponent, react to lethal threats).
3. Role-aware target scoring and hidden-information constraints.
4. Card-value / resource conservation.
5. Difficulty levels, reproducible tests, and balance simulations.

Do not let bots access hidden roles or unseen hands unless explicitly allowed by a documented rule. Avoid introducing heavyweight ML/LLM dependencies for MVP.

## 10. MVP completion criteria
- Complete four-player setup, role assignment and win checks.
- Full turn cycle and legal actions, including discard limit.
- Cards and equipment needed by the approved MVP deck.
- Reactions, dying/rescue/elimination and correct turn skipping.
- Four approved characters and their abilities.
- Three functioning bots that finish matches.
- Playable PC interface with visible hand, phase, targets, logs and game-over state.
- Repeatable regression tests and basic balancing.

## 11. Unresolved design decisions
- Final 48-card composition and precise semantics of Do thám / Hủy bài.
- Role reveal timing and win-resolution edge cases.
- Rescue order, who may rescue, Bia consumption, self-rescue conditions.
- Equipment slots, weapon range, armor timing and duration.
- Judgment/delayed card semantics.
- Character ability wording, limits and trigger priority.
- Bot knowledge and difficulty parameters.
Mark these as `OPEN` in task proposals rather than inventing final rules.
