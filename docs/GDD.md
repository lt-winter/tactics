# Tactics — Game Design Document (Combat v0.5 / Prototype UI v0.2)

**Status:** Working design handoff, consolidated 2026-11-06. This document preserves previously agreed direction, but is **not** a claim that every rule is fully specified or implemented.

**Approved update, 2026-11-06:** counterclockwise seat order and automatic progression through phases without decisions are settled rules. Other items explicitly marked proposed/OPEN remain provisional.

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
- Approved prototype opening: **4 cards for each of the four players**, dealt once before turns begin. **Every turn, including each player's first turn, includes the normal 2-card DRAW.** Human therefore enters the first PLAY with 6 cards; Bots hold 4 until their turn and then draw 2. This latest correction supersedes the earlier first-DRAW skip. A deck too small for the full opening deal is rejected before any card moves.
- Approved prototype win rule: when exactly one non-eliminated player remains alive and no player is DYING, stop the match and announce that survivor as winner. Resolve Dying/rescue first; zero survivors does not invent a winner. Role-based victory below remains a future proposal. Deck exhaustion alone does not decide the match.

## 3. Role objectives — provisional interpretation
- **Sheriff:** eliminate all opposing roles while remaining alive.
- **Outlaws:** win if the Sheriff is eliminated.
- **Renegade:** be the sole survivor after the Sheriff is eliminated.
- **Open decision:** exact resolution priority if Sheriff and Renegade are eliminated in one effect, and whether the Sheriff wins immediately when all others are eliminated. These must be expressed as deterministic tests before implementation.
- Do not infer the final role/identity system from current `Player`: role storage is not implemented yet.

## 4. Turn structure
Phase enum remains `START -> JUDGMENT -> DRAW -> PLAY -> DISCARD -> END -> next player`.
- **Confirmed counterclockwise seat order:** Human below, Bot 1 right, Bot 2 above, Bot 3 left; turns follow **Human -> Bot 1 -> Bot 2 -> Bot 3 -> Human**. The latest user correction swaps Bot 1 and Bot 3 positions so this sequence is geometrically counterclockwise on screen. Engine seat IDs determine the order independently of nodes. ELIMINATED players are skipped, including when the current actor is eliminated during a turn.
- **Settled rule 2 — automatic phases:** phases without an effect, reaction, or decision advance automatically. Normal play never requires Next Phase clicks for empty START/JUDGMENT/END or the standard DRAW.
- START: reset per-turn counters when an eligible player's turn starts.
- JUDGMENT: skip only when empty. A nonempty judgment zone currently stops with an unsupported-effect message; its effects are not silently discarded or resolved.
- DRAW: draw the default 2 cards through GameState on **every** turn, including the first, then stop at PLAY. Drawing only the available cards when the deck is exhausted retains existing engine behavior. Resume at PLAY does not draw again.
- Vietnamese phase display: START = Giai đoạn bắt đầu; JUDGMENT = Giai đoạn phán xét; DRAW = Giai đoạn rút bài; PLAY = Giai đoạn sử dụng bài; DISCARD = Giai đoạn bỏ bài; END = Giai đoạn kết thúc. Internal enum names and ordering remain unchanged.
- PLAY: always waits for actions or an explicit valid **Kết thúc lượt / end_turn(actor_id)** request. Auto-advance never ends Human PLAY; Bots also wait for manual debug control until AI exists.
- DISCARD: normally limit = current HP, resolved through RuleEngine including modifiers. Stop only if cards must be selected, a rule is unavailable, or an effect needs resolution. The current actor chooses one owned hand card at a time; the engine validates and moves it. No automatic selection/card loss. Once within the limit, continue automatically.
- END: advance to the next eligible counterclockwise seat, then process its empty phases through PLAY. No eligible seat means a safe stopped state, **not** a newly invented win condition.
- Priority is **Dying Window -> Attack Response -> normal actions/phases**. A pending attack cannot consume Dodge or resolve damage while anyone is DYING; rescue resumes the response, while elimination of its target closes the stale attack without spending Dodge. Both windows block phase transitions, end-turn/discard requests and auto-advance, including direct TurnManager calls. DYING seats still count for distance.
- Unsupported effects/choices stop with a reason. Auto-advance has a hard maximum of 32 transitions per invocation and stops on lack of progress; it never loops through PLAY unattended.
- **OPEN:** triggered ability timing and role-based victory remain undefined. The current-player elimination transition is now implemented as skipping that eliminated seat once pending windows are resolved.

## 5. Combat and distance
- Approved basic weapon equip: during their own PLAY, a living player may equip a weapon from their hand onto themselves without an extra card cost. One weapon slot; replacing discards the old weapon and equips the new one as one batch. Attack/Dying windows and unresolved phase effects block equip. No voluntary unequip rule is added.
- Weapon ranges 1–5 and Crossbow/Nỏ thần's unlimited Attack count are implemented via CARD_EFFECT RuleModifiers, preserving character-skill priority and all other validation. Moving a weapon out of equipment removes its passive effect immediately, including Hủy/Cướp; stealing it into hand does not equip it. The four other weapon special effects remain unimplemented and UI reports this limit.
- Base attack range: 1 seat.
- Base limit: one attack card per turn.
- Circular distance = minimum clockwise/counterclockwise seat separation among participants who still occupy seats.
- `ELIMINATED` players are removed from distance counting.
- `DYING` players still occupy their seats until elimination; their only supported card action is using their own healing card to rescue themselves.
- Attack opens a response window. A valid Dodge cancels the attack; otherwise damage enters DamagePipeline.
- Healing-card use: a living, wounded player may use their own `restore_hp` card during their own PLAY to heal themselves by the JSON `amount`, capped at max HP. It consumes exactly one card on success; full HP, wrong turn/phase/ownership, unresolved effects and Attack/Dying windows reject without cost. During Dying, the separate paid-rescue action below takes priority over normal healing.
- Prototype manual controls: the lower hand follows the current actor, explicitly marked DEBUG for Bots. Select a card and any required target, then **Đồng ý** to use it (or discard it during DISCARD); **Huỷ bỏ** clears the selection without cost. Attack responses retain their separate target Dodge confirmation and explicit **Không Né** choice. The debug hand display is not a final hidden-information/AI policy.
- Interaction: select an Attack and a target, then submit. Range/turn/ownership/limits are validated before consuming the Attack. The target's response overlay shows only their Dodge cards; selecting one does not spend it. **Đồng ý** submits that specific Dodge; **Không Né** explicitly declines. Bots remain manually controlled in the prototype.
- Discard/Steal interaction: select the tool and another player, then select one card from the JSON-allowed zones. **Equipment is face-up** with its name/rank/suit; hand cards remain face-down without those details. Judgment visibility is unchanged. Cancelling costs nothing. Commit revalidates ownership/phase/windows/range and the chosen card, then moves victim and played tool in one batch. Steal transfers the victim into hand; Discard moves it to discard. Steal has max distance 1; Discard has no added distance restriction.
- Every successful card transfer into the discard pile emits a notification listing **card names only**, including Attack/Dodge/heal/rescue, hand-limit discards, discarded tool/victim cards and replaced weapons. Failed or cancelled transfers do not generate discard notifications.
- Damage modifiers may reduce/increase/cancel damage before HP is changed.
- Damage that leaves HP at 0 or below enters DYING and **preserves negative HP**. The player remains DYING until HP is **strictly above 0**: at -1, two uses of a +1 healing card produce -1 -> 0 -> 1. Partial rescue consumes the used card but does not close the window or resume normal actions/phases.
- The DYING player may use their own healing cards, or any other living player may use their owned healing card to rescue them, regardless of whose turn it is. Each confirmed use consumes exactly one selected card and applies its JSON amount. Wrong owner/type/target, spent or missing cards, eliminated rescuers and another DYING rescuer are rejected without payment. A blocking modal lets the operator select rescuer and card, confirm each use, or explicitly choose no rescue to finalize elimination. No automatic card selection, timeout, rescue-order protocol or AI policy is introduced.
- Card faces show only name and rank/suit. Full descriptions and selection messages read the `description` field in `data/cards.json`; gameplay values remain in effect `parameters`. Editing descriptive text does not change effect values.

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
`data/cards.json` currently defines **ten** card IDs (the five weapon definitions were added by the user):
- `attack` / `deal_attack`
- `dodge` / `block_attack`
- `heal` / `restore_hp`
- `discard` / `discard`
- `steal` / `steal_card`
- `crossbow`, `butchers_knife`, `slingshot`, `pistol`, `rifle`: equipment_slot=weapon, range 1..5. Only passive range and remove_attack_limit are executed in the current basic equip implementation.

`data/decks/standard.json` now contains the user's **39 instances**: 16 attack, 7 dodge, 7 heal, 2 discard, 2 steal and one each of the five weapons, with numeric suit codes 0=spades, 1=hearts, 2=diamonds, 3=clubs. It is not the final 48-card MVP distribution. The basic equip/win/UI changes preserve the user's JSON quantities, descriptions, suits, ranks and order.

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
- Ordered pass/timing protocol for multiple potential rescuers; eligibility, one-card payment and self-rescue are now implemented as specified above.
- Equipment slots, weapon range, armor timing and duration.
- Judgment/delayed card semantics.
- Character ability wording, limits and trigger priority.
- Bot knowledge and difficulty parameters.
Mark these as `OPEN` in task proposals rather than inventing final rules.
