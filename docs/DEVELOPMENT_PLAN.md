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

## Weapon System v1.0 — sau các milestone nền tảng

**Latest authorized exception to the full-trigger roadmap:** basic equip/replace, range modifiers and Nỏ thần passive are implemented independently of F1/F2, under the approved rule: equip during own PLAY, no extra cost, replaced weapon to discard. The user already added five weapon definitions/copies; this change preserves that data. No voluntary unequip or four active weapon abilities are implemented. Full W3–W7 still require the pending/damage foundations and remaining gameplay decisions below.

**Additional approved prototype work completed:** discard-pile notifications by card names, face-up equipment in Hủy/Cướp pickers, and last-survivor match termination after Dying is resolved. This is a survivor win rule, not role-based victory implementation. See DEVELOPMENT_STATUS.md for current executed checks.

**Thiết kế đầy đủ vẫn đang chờ duyệt; phần trang bị cơ bản đã được duyệt và triển khai như ghi ở trên.** Tham chiếu: [WEAPON_SYSTEM_DESIGN.md](WEAPON_SYSTEM_DESIGN.md). Không tự bổ sung bản sao hoặc sửa JSON bộ bài.

Thứ tự phụ thuộc: Stage 0.3 và các sửa nền tảng F0 → F1 → F2 → các mốc W. Các follow-up hồi máu/cứu bằng bài hiện có phải được giữ nguyên; không cần chờ toàn bộ roles/AI hoàn tất mới thiết kế equipment.

| Mốc | Phạm vi nhỏ và điều kiện bắt đầu |
|---|---|
| D0 — tài liệu | Đối chiếu API/source, thiết kế slot/Attack/event/decision/replacement, ghi các luật OPEN; nhiệm vụ hiện tại dừng ở đây |
| F0 — nền tảng trước vũ khí | Sửa `GameState.validate_state()` phù hợp DYING âm; thống nhất distance theo ghế authoritative; hoàn tất contract damage/Dying Stage 0.3. Hiện chỉ ghi nhận và đề xuất, chưa sửa code |
| F1 — nền tảng trước vũ khí | AttackContext một target, DamageResult/source kind; giữ `use_attack`, `respond_to_attack`, `process_damage` compatibility adapters |
| F2 — nền tảng trước vũ khí | PendingDecision, continuation stack có giới hạn, controlled checkpoints và guard chung cho direct calls/Debug; resume combat trước auto-phase |
| W1 | Weapon slot + equip/replace/unequip/destroy lifecycle và batch transfers; modifier theo instance/activation. Cần chốt luật equip/đích đến trước khi bật gameplay |
| W2 | Nỏ Thần: range và remove_limit bằng RuleModifier; không bypass validation và không reset count khi tháo |
| W3 | Dao Phây: generic damage replacement; chốt thiếu hai lá, người chọn/visibility và timing defense trước coding nhánh B |
| W4 | Ná Cao Su: optional cost/target, actual damage trigger, range từ primary, child damage/Dying; chốt lifetime/target policies |
| W5 | Súng lục: một payment/count, hai target/response; chốt resolution order và revalidation giữa targets |
| W6 | Súng trường: chọn/discard equipment và detach modifier cùng commit; chốt chooser và target/Dying timing |
| W7 | UI slot/range/optional/multi-target/cost/equipment picker và tích hợp; cập nhật tài liệu và kiểm chứng đầy đủ |

Mỗi mốc phải giữ 13 regression suites, thêm test nền tảng/vũ khí theo design và UI smoke với warnings-as-errors. Mốc sau chỉ bắt đầu khi dependency đạt và được phê duyệt; thông số OPEN không có default ngầm. Test fixture có thể dùng definition tạm/in-memory; thêm bản sao vũ khí vào bộ bài thật là một thay đổi riêng cần yêu cầu.

Các quyết định còn thiếu được đánh số G1–G12 trong thiết kế: equip/cleanup; Dao thiếu bài/người chọn/timing; Ná eligibility và trạng thái sau Dying; thứ tự Súng lục; hiệu lực snapshot/live; người chọn equipment; trigger ties và commit cost. Danh sách này không thay đổi các luật đã chốt trong GDD.

## Stage 2 — Full approved MVP card deck
- **AOE Tool System v0.1 completed (2026-11-06):** data-driven Gatling/Indian tools, counterclockwise all-other-player queue without distance, manual typed card responses, one payment, no Attack count/weapon activation, distinct damage source and Dying-first continuation. Pending AOE blocks normal actions/phase transitions; UI has source/target, valid cards, Đồng ý/Không phản ứng. See ARCHITECTURE for schema/API and STATUS for executed tests.
- Added AoeSystemTest and AOE UI smoke; all-suite runner now discovers 14 suites (13 existing plus AOE). Keep both UI smoke scripts. `standard.json` composition/order remains designer-controlled; live user edits were preserved.
- Stop after AOE v0.1. General nested effects/weapon decisions, AI responses, role rules and simultaneous-AOE effects remain outside this milestone; this queue does not complete weapon F1/F2 or Stage 0.3.
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
- Setup/input/defense follow-up implemented: initial/new-match menu for 2–6 named P1…Pn, adaptive seats, cancel preserving the old session, double-click through existing confirms, and defensive-slot metadata/query/UI foundation only. Added defense regression and menu/input smoke. Armor effects, armor use/replacement rules, bots and expanded role allocation remain unimplemented; no deck changes are authorized by this work.
- Selection/personal-panel follow-up completed: selected hand/modal cards rise and other cards dim; draft selection/cancellation is absent from the match log. Human information is separate from the Bot table, while manual Bot hands still follow the current turn. No gameplay change; execution evidence is in STATUS.
- Target-selection follow-up completed: smaller uppercase card faces, labeled tool-card zones and validator-driven target dimming/locking with stale-selection clearing. No new weapon ability or targeting rule was introduced.
- Compact-log follow-up completed: single-spaced name-only card logs, rank/suit only at the top of each card, and an independent draw/discard/shuffle information panel. Shuffle count instruments existing shuffle calls, including match setup; gameplay unchanged.
- Latest UI follow-up completed: remove right Debug menu, place Event Log in the top header, use portrait card faces and heart health, disable unusable cards/eliminated seats. Manual Bot turns use the same lower hand and action buttons. Existing gameplay/weapon limits remain unchanged; regression/UI evidence is in STATUS.
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

Weapon System v1.0 đầy đủ vẫn là roadmap. Sau nhiệm vụ thiết kế, người dùng đã duyệt và nhận phần equip/replace cơ bản, range và Nỏ thần, cùng discard log/survivor win/equipment visibility. Dừng ở phạm vi đã duyệt này; không tự bắt đầu F0/F1/F2, voluntary unequip hoặc W3–W7. Giữ nguyên JSON do người dùng đã bổ sung.
