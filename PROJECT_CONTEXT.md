# PROJECT CONTEXT — LOGIC QUEST
## Graduation Project Handoff

### 1. Project Identity

**Project Name:** Logic Quest  
**Project Type:** Educational Programming Game  
**Academic Context:** Computer Science Graduation Project  
**Developer:** Computer Science student at New Mongol Kosen College of Technology, Mongolia.

Logic Quest is an educational game designed to teach programming fundamentals through interactive gameplay, visual problem-solving, and progressively challenging levels.

The main idea is to transform abstract programming concepts into something learners can understand by interacting with them rather than simply reading explanations or memorizing syntax.

This is an educational software project, not just a conventional puzzle game.

### 2. The Problem

Many beginners experience difficulties when learning programming for the first time.

Some common problems include:

- Difficulty understanding programming logic.
- Difficulty visualizing how instructions are executed.
- Confusion about conditions and loops.
- Difficulty understanding how variables store and change values.
- Lack of practical interaction when learning from traditional materials.
- Difficulty connecting theoretical explanations with actual problem-solving.

Programming beginners often need to understand how a program thinks and executes before they can comfortably write code themselves.

Logic Quest aims to address this learning gap.

### 3. Proposed Solution

Logic Quest uses game-based learning to introduce programming fundamentals.

Instead of immediately requiring learners to write conventional programming syntax, the game presents interactive challenges where players must apply programming concepts to solve problems.

The player learns by:

1. Understanding a problem.
2. Identifying the programming concept required.
3. Constructing a logical solution.
4. Executing or testing the solution.
5. Observing the result.
6. Learning from mistakes and improving the solution.

The game should make the relationship between player actions and programming logic clear.

### 4. Main Educational Topics

The primary learning topics discussed for the project are:

**A. Variables**
- Understanding what variables are.
- Storing values.
- Changing and retrieving values.
- Understanding how values affect program execution.

**B. Conditions**
- Understanding conditional statements.
- True and false evaluations.
- Making decisions based on conditions.
- Understanding branching logic.

**C. Loops**
- Understanding repetition.
- Executing instructions multiple times.
- Recognizing loop conditions.
- Understanding when a loop starts and terminates.

These concepts should form a progressive learning experience, where earlier knowledge supports later challenges.

Other advanced topics such as recursion, binary trees, graphs, and dynamic programming were previously discussed as possible educational topics, but they should not automatically be treated as confirmed implemented features or core project requirements.

### 5. Educational Game Design Philosophy

The most important design principle is:

**Every gameplay mechanic should have an educational purpose.**

For example:

- A variable challenge should help the player understand value storage and modification.
- A condition challenge should demonstrate how decisions change program behavior.
- A loop challenge should demonstrate repetition and termination.

The player should understand WHY a solution works, not merely discover which button or action produces the correct answer.

The game should ideally provide meaningful feedback when a player makes a mistake.

Feedback should help explain the underlying programming concept instead of simply displaying "Wrong Answer."

### 6. Existing Educational Games and Research

Several existing games were considered during the research phase:

- Human Resource Machine
- 7 Billion Humans
- Lightbot
- The Farmer Was Replaced

These games are useful references for understanding how programming concepts can be represented through gameplay.

However, Logic Quest should not simply copy their mechanics.

The goal is to identify useful educational design principles and develop an appropriate learning experience for the project's intended audience.

Previous research discussions also covered six academic papers.

Two studies were particularly important in the seminar discussions:

- NoBug's SnackBar and its approach to programming education and learner errors.
- A second research study discussed using clear learner-progress visualization, including a GitLab example in the presentation.

The research was organized around this relationship:

Research findings → Game features → Learner workflow → Evaluation

The intended outcome is to justify game design decisions through educational research rather than making arbitrary gameplay decisions.

### 7. Target Audience

The intended audience is beginner-level programming learners.

The game should be accessible to people who are new to programming and may not yet understand conventional programming syntax.

The experience should prioritize:
- Understandable instructions.
- Gradually increasing difficulty.
- Visual representation of programming logic.
- Interactive learning.
- Meaningful feedback.
- Clear learning progression.

### 8. Academic Objectives

Logic Quest should aim to:

1. Help beginners understand fundamental programming concepts.
2. Improve understanding of programming logic through interactive challenges.
3. Represent abstract concepts visually.
4. Provide progressive learning activities.
5. Help learners identify and correct logical mistakes.
6. Evaluate whether the game supports learning and understanding.

### 9. Important Distinction: Prototype vs. Planned Features

Not every idea discussed during research or seminar preparation is necessarily implemented.

Previous planning included draft learning levels for variables, conditions, and loops. The loop-level design was not yet completed in that planning discussion.

Therefore, do not assume that every discussed feature exists in the current application.

You must inspect the actual source code and distinguish:

- Fully implemented features.
- Partially implemented features.
- Prototype or experimental features.
- Planned but unimplemented features.
- Features discussed only as research or design ideas.

Never describe a planned feature as an existing feature.

### 10. Your Role as Claude Code

You are assisting with a Computer Science graduation project.

Your job is not simply to make the application work. You must understand the educational purpose and help develop the software in a way that supports that purpose.

When analyzing or modifying the code:

1. Preserve the existing project architecture unless there is a good technical reason to change it.
2. Understand the current implementation before proposing major modifications.
3. Avoid unnecessary rewrites.
4. Keep the code maintainable and understandable for a student developer.
5. Prioritize functionality and educational value over decorative UI improvements.
6. Make sure game mechanics correctly represent the programming concepts they teach.
7. Consider the learner's experience when designing features.
8. Explain important technical decisions clearly.

Do not invent features, research findings, or implementation details.

### 11. First Task: Understand the Existing Repository

Before implementing anything, perform a comprehensive project audit.

Inspect:

- Project structure.
- Programming languages and frameworks.
- Main entry points.
- Application architecture.
- Game systems and mechanics.
- Existing levels and their logic.
- User interface.
- Player interaction.
- Progression and level management.
- Data storage.
- Error handling.
- Existing educational feedback.
- Dependencies and external libraries.

Then produce a report containing:

**A. What the application currently does**

Explain the actual user experience from launching the application to completing its available activities.

**B. Existing implementation**

List the major systems, their responsibilities, and how they interact.

**C. Educational functionality**

Explain which programming concepts are currently taught and how the game teaches them.

**D. Missing functionality**

Identify incomplete systems, bugs, and important missing educational features.

**E. Recommended next steps**

Prioritize improvements based on:
- Graduation project objectives.
- Educational effectiveness.
- Technical importance.
- Development complexity.

Finally, create or update `PROJECT_CONTEXT.md` with the verified technical architecture and implementation status. Keep this document synchronized with future development.

> **Status:** First audit completed 2026-11-23. Results are in sections 13–18 below.

### 12. Overall Project Direction

The ultimate goal is to develop a functional educational game that demonstrates how game-based learning can help beginners understand programming fundamentals.

A successful Logic Quest should demonstrate three things:

1. It works as a software application.
2. It provides a meaningful and structured learning experience.
3. Its game mechanics are directly connected to programming education.

**Always remember: Logic Quest is an educational programming game, and its primary purpose is to make programming logic easier to understand through interactive gameplay.**

---

# VERIFIED IMPLEMENTATION (from source code)

Sections 1–12 describe intent. Sections 13–18 describe what the code actually does. They were verified by reading the source on **2026-11-23** (first audit of commit `9039ab8`), then updated the same day after the C++ conversion and bug fixes (section 18), updated **2026-11-25** (route map, save, stars, bus-world renames), and last updated **2026-11-27** (Paper Diorama visual redesign, chapter screen). Update these sections whenever the code changes.

### 13. Technical Architecture

**Engine and language:** Godot 4.7 (tested with 4.7.2), GDScript only. No C#, no external libraries used by the game.

**Learner-facing language:** **C++** (decided 2026-11-23). All code the player sees, and the rules the interpreter enforces, follow C++.

**Game code (all at repository root):**

| File | Size | Role |
|---|---|---|
| `main.tscn` | 1 node | Bare full-screen `Control` with `main.gd` attached. Only scene in the project. |
| `main.gd` | ~2,300 lines | Builds the entire UI in code, owns all game state, level flow, every mode's logic, animations, and feedback text. |
| `ui_theme.gd` (`UiTheme`) | ~380 lines | The single visual identity («Paper Diorama», chosen 2026-11-27): the colour palette (cream background, ink outlines, dark code panels, yellow `GLOW`, chapter accents in `CHAPTERS`), fonts (`font(kind)`: Nunito for UI, JetBrains Mono for code with ligatures off, Segoe UI Symbol fallback for ✓ ✗ ◇ ★), `make_theme()` (the Godot Theme for buttons, inputs, popups, tooltips, `CodeEdit`), StyleBox factories (`paper`, `code_panel`, `tag`, `box_style`, `chip`) and `_draw()` helpers (`poly`, `circ`, `chip_text`, `text_in`, `star`, `diorama`, `person`, `bataa`, `bus`). Other scripts take colours from here by name. |
| `assets/fonts/` | 2 fonts | `Nunito.ttf` and `JetBrainsMono.ttf` (variable fonts, both contain Ө Ү ₮) with their SIL OFL 1.1 licence files. |
| `levels.gd` (`Levels`) | ~150 lines | Level definitions as data, plus `make()` which fills in random numbers for each attempt. |
| `interp.gd` (`Interp`) | ~155 lines | Mini C++ interpreter that runs one statement at a time and produces a Mongolian explanation of each step. |
| `guard_view.gd` (`GuardView`) | ~210 lines | Paper-diorama bus door for the `&&`/`||` level (8). The rule (C++ condition) hangs above the bus on a dark sign, Bataa (mascot, no dialogue) sits in the windshield, and the card reader on a pole lights green or red. Each verdict is a paper chip, not a speech bubble. Passengers hold the same blue card as in level 9. Internal names still say `ticket`/`guard_stop`; the player sees `card`. |
| `flow_view.gd` (`FlowView`) | ~230 lines | Custom-drawn `if` / `if-else` flowchart for levels 6–7 (paper style): condition diamond, F (left) / T (right) paths, block boxes, a value token that travels a path (`point_on`), and click-to-choose a branch (`side_chosen`). |
| `challenge.gd` (`ChallengePanel`) | ~940 lines | Optional challenge level: opens straight in the editor (Bataa's 4-line dialogue was removed 2026-11-27); fare rules as 3 chips, a feedback note beside them (`_note`), draggable block palette, inspector for the selected block, editable C++ (`CodeEdit`) with live two-way sync (blocks → `to_cpp`; typed code → `parse_cpp` after 0.5 s, Mongolian parse errors), a tree-walk runner with C++ rules (`run`), and 8 boundary test cases (`check`). |
| `flow_canvas.gd` (`FlowCanvas`) | ~300 lines | Flowgorithm-style flowchart editor on a white dotted paper canvas (`if` drawn as a diamond): auto-lays out the program top to bottom (Эхлэл → blocks → Төгсгөл; `if` T right / F left). An input parallelogram «Оролт: age, card» follows Эхлэл. Variable blocks use the level 1–5 box design (name tag / value box / yellow `int` tag; assign = tag + box with «← value»). Mouse wheel zooms around the cursor (40–220%), and holding the middle button pans. Drop palette blocks onto arrows, drag existing blocks to another arrow, click to select; the view pans automatically while dragging near an edge. |
| `bus_view.gd` (`BusView`) | ~200 lines | Paper-diorama bus scene for the challenge: Bataa in the windshield (mascot), a card reader on a pole showing the charged price, passengers with age tags and price ✓/✗ chips boarding (`run_test`). `bubble_text` still draws a note but the challenge no longer uses it. |
| `route_view.gd` (`RouteView`) | ~380 lines | Chapter select screen (replaced «Батаагийн маршрут» on 2026-11-27; class name kept). Top: «Logic Quest» and the star total. Middle: one paper card per chapter (from each level's `chapter`) with a mini diorama, chapter stars and level dots, plus a locked «Давталт · Удахгүй» teaser card. Bottom: the selected chapter's level path: cleared stops in the chapter colour with stars, the open stop with a pulsing yellow ring, locked stops grey, the optional challenge tagged «нэмэлт», Bataa as a silent mascot, and a small bus that drives between stops (`travel`). Clicking a card switches chapter; clicking an open stop emits `stop_chosen`. Setting `selected` also switches `view_chapter`. |
| `progress.gd` (`Progress`) | ~50 lines | Saved progress in `user://progress.cfg` (ConfigFile): `unlocked` (number of open levels) and best `stars` per level (0–3). `record(i, stars)` keeps the best and unlocks the next level. `stars_for(mistakes)`: 0 mistakes = 3, 1–2 = 2, more = 1. |

**What `Interp` supports (C++ subset):**
- `int x;`: declare without a value. The memory box is drawn empty (a deliberate simplification, see section 18), and reading it is an error ("garbage value").
- `int x = expr;`: declare and assign. `x = expr;`: assign to an already-declared variable.
- `if (cond) x = expr;`: single-statement `if`. A non-zero int counts as true, as in C++.
- Expressions use Godot's `Expression`, which matches C++ for `int` here: `/` truncates toward zero, `%` keeps the sign of the left operand, and `&&` / `||` / `!` work.
- Errors, each with a Mongolian explanation: missing `;`, use of an undeclared variable, redeclaration, reading an uninitialized variable, a non-int value into an `int`, division by zero. An error ends the program. Where real C++ would refuse to compile the whole program, the message says so.
- **Not supported:** blocks `{ }`, `else`, loops, functions, types other than `int`.

**Not game code:**
- `addons/godot_ai/` is a third-party MCP editor plugin, used for AI-assisted development. It registers an autoload (`_mcp_game_helper`) that is included in exported builds but stays idle when no debugger is attached.
- `.godot/` is the editor cache, and `*.exe` files are Windows exports. Both are ignored by `.gitignore` since 2026-11-23.

**How the systems connect:**
1. `main.gd._ready()` applies `UiTheme.make_theme()` and the cream clear colour, then `_build_ui()` creates **every** panel at once: a top bar («← Бүлэг», chapter chip, «N · title», best-stars label, «?» hint button that shows `cur.hint`), the story line, then program + memory boxes, guard panel, cinema panel, tutorial panel, prediction row, buttons, message label, and a top "fly layer" for animated values.
2. `_load_level(i)` calls `Levels.make(template)`, which replaces `{A}`, `{B}`… with random numbers from `params` ranges. For `arrange` levels it also runs the correct program through `Interp` to compute the goal `{G}`, then shuffles the lines.
3. `_setup_level()` shows or hides the panels based on `mode` and resets state.
4. **predict / arrange:** the buttons call `Interp.step()`. `main.gd` splits each line into tokens (`_split_tokens`, with `;` as its own token), colors the code rows, animates values flying from boxes into the expression and the result back into a box (`_animate_assign`), and shows `Interp`'s short step line. Memory boxes are labeled boxes (name tag + `int` sticker). `_update_glow()` highlights the next control to use, instead of instruction text. In predict mode, Start is blocked until the player enters a guess. When the program ends, `_finish()` compares the result with the guess (predict) or the goal (arrange).
5. **guard:** dropdowns and spin boxes build a C++ condition, for example `age >= 18 && card == 1`, displayed as a full `if (...) { openDoor(); } else { keepClosed(); }`. Spin boxes update on every keystroke (`update_on_text_changed` + `_on_spin_key`, which also maps physical digit keys for the Mongolian layout), so no Enter is needed. Godot's `Expression` evaluates it for each person, and `GuardView.run_test()` animates each decision. The correct answer is hard-coded in `main.gd` (`age >= T && card == 1`). Test crowds always contain T−1, T, T+1, one person well below T, and one well above. Two-rule levels also include people without a card.
6. **cinema:** the player fills in blanks in a fixed C++ template: `double price = 0;`, `if / else if / else`, then two `if`s. `main.gd` evaluates it natively in GDScript (not through `Interp`) on 8 test customers and compares against `_cinema_expected()`.
7. **tutorial:** a scripted 3-step animation (`_tut_step1..3`) built around a labeled box: a name tag on top (`tut_name_tag`), the box (`tut_box`), and a yellow `int` type sticker (`tut_type_tag`). Code tokens light up and fly into the part of the box they create. Captions are 2–4 words.
8. Progression is linear: the "Next level" button appears only after success, and is hidden again when a re-test fails. The last level shows "Part 1 done. Next: Part 2 (Loops)."
9. **Keyboard** (`_unhandled_input`, using `physical_keycode` so it works on a Mongolian Cyrillic layout): Esc = back to the route map. On the map: ← / → (A / D) = select an open stop, Enter / Space = go. In levels: → / D = next (tutorial step or next level), Enter = Start or one step, Space = run all, F = skip animation, W / ↑ and S / ↓ = move the selected line (level 5). Buttons have `focus_mode = NONE`, so Enter/Space never re-press the last clicked button. Key hints are in button tooltips.
10. **Skip (F):** every animation tween and wait goes through `_anim_tween()` / `_wait()`. `_on_skip()` speeds running and new ones up ×60 (`SKIP_SCALE`) and makes `GuardView` fast. `_begin_action()` resets it when the player starts the next action.
11. **Predict answer area** (`_build_guess_area`): a dashed "Таны таамаг" labeled box (`DashedBox` inner class, digits-only `guess_edit`, Enter = Start). At the end, the real value flies from the memory box into a "Жинхэнэ" box beside it, with ✓/✗ between them. Digits are read by **physical key** (`_on_guess_key`), because the Mongolian Cyrillic layout's number row types symbols and letters, not digits. The box focuses automatically on predict levels.
12. **Three tries (predict):** Start first checks the guess with a silent `Interp` run. A wrong guess on try 1–2 shakes the box, shows ✗ and "N оролдлого үлдлээ", and keeps the same numbers. The program actually runs (revealing the answer) only on a correct guess or the 3rd wrong try. Reset then rolls new numbers and resets `wrong_tries`.
13. **Code rows** are slot + card: the slot holds the row's place in `code_box`, and the card is the visible row. In level 5 a card can be dragged: it lifts (`top_level`, shadow, ×1.03), follows the mouse, leaves a placeholder ("Ghost"), and other cards slide (`_reorder`). On release it settles back into its slot, and line numbers are renumbered. W/S use the same `_reorder`. A "≡" grip marks draggable rows.
14. **Flow mode (levels 6–7)**, layout like level 1: the C++ `if` block on top (`flow_code`, rows colored current/ran/skipped), the `FlowView` flowchart below, and labeled variable boxes on both sides (input `temp`/`score`, output `fan`/`pass`). **Explanation:** three steps via «Дараагийн алхам» (condition; a true example; a false example), each animated by `_flow_run()`: the value flies into the oval, `35 > 30 → true/false`, the token travels the real path, and the block's value flies into the output box. **Mini test:** each round has a random value (round 2 is always the boundary value) and an operator from `ops`. The player picks a branch (click or ←/→), then the computer runs it and shows ✓/✗ plus a why line. 3 correct answers pass.
15. **Dev shortcut:** F9 = next level (and unlocks it), only in debug builds (`_input`), for testing.
16. **Chapter screen and stars:** the game starts on the chapter screen (`_show_map`). «← Бүлэг» (top bar) or Esc returns to it, but not while an animation runs (`_is_animating`). `level_ui` (the MarginContainer holding every level panel) and `route_view` swap visibility. Choosing a stop drives the bus there (`_on_stop_chosen`), then `_load_level`. «Дараагийн түвшин» does the same for the next stop, and after the last level the map shows «1-р хэсэг дууслаа!». `level_mistakes` counts wrong predict guesses, arrange failures or runtime errors, wrong flow answers, and failed guard tests. The challenge uses `challenge.fails`, and the tutorial always gives 3 stars. `_offer_next()` (the common success point of every mode) records the stars once per visit and updates the top-bar stars (`_update_stars`).

**Extending:** a new level of an existing mode is one dictionary entry in `levels.gd` (`params` ranges, `{KEY}` placeholders, `nonzero_rem` to force a non-zero remainder). Lines must be valid statements in the C++ subset above. A new *mode* needs a panel in `_build_ui()`, a visibility branch in `_setup_level()`, and handling in `_reset_state()` / `_finish()` or its own test function. `Interp.step()` returns `{ok, line, skipped, var, note, error}`.

**State and async:** flags `started`, `finished`, `busy`, `tut_busy`, and `guard_view.running` gate input. `run_token` cancels running "Run all" loops on reset. All animations use `await` with tweens or timers.

**Visual layout per mode (since 2026-11-27):** predict/arrange = dark C++ panel (left, syntax-coloured tokens, current row with a yellow left stripe and «»») + paper «Санах ой» card (right: cardboard variable boxes `CardboardBox`, guess box below). Tutorial and flow code sit in dark panels; variable boxes everywhere are cardboard with a white name tag and the yellow `int` tag. The next-action glow (`_set_glow`) turns a button yellow with an ink border and a pulsing yellow halo.

**Data storage:** `user://progress.cfg` holds the unlocked level count and best stars per level (`Progress`). No settings and no learning logs yet.

### 14. Level Inventory (as implemented)

| # | Title (Mongolian, shortened) | Mode | Concept taught | Player action |
|---|---|---|---|---|
| 1 | Хайрцаг | tutorial | Variable = named box. `int people;`: `int` becomes the type sticker, `people` the name tag, box drawn empty ("утга өгөөгүй"). `people = V;` puts V in. `people = people + K;`: `=` briefly shows as `←`, old V is replaced by V+K (V, K random each view) | Watches 3 animated steps |
| 2 | Хуулбар | predict | Assignment copies a value; boxes are not linked (Bataa copies the count to his notebook: `int note = people;`, then `people` changes) | Predicts final `note`, then steps through |
| 3 | Шинэчлэх | predict | Updating a variable from its own old value (Bataa's passenger clicker, `people = people + 1;`) | Predicts final `people` |
| 4 | / ба % | predict | C++ `int / int` drops the remainder, `%` gives the remainder (`people` into minibuses of D: `full = people / D`, `left = people % D`) | Predicts `int ans = full * 10 + left;` |
| 5 | Дараалал | arrange | Statement order; a variable must be declared before it is used | Reorders 3 lines by mouse drag or W/S (↑/↓) to reach goal `{G}` |
| 6 | if | flow (`if`) | `if`: true → block runs, false → skipped; difference between `>`, `>=`, `==` (number line) | Watches 3 flowchart steps + 3 number-line steps (one per operator), then a mini test: 3 correct, one per operator, values T−1/T/T+1 |
| 7 | if / else | flow (`ifelse`) | `if / else`: exactly one of two blocks runs; `>=`, `>`, `<=`, `<` | Same: explanation + mini test |
| 8 | Хоёр дүрэм (&& / \|\|) | guard (2 rules) | Combining conditions with `&&` / `\|\|` | Bataa's night-route door rule: builds `age OP N &&/\|\| card OP M`, then passengers are tested at the bus door (mechanic still the old dropdown design) |
| 9 | Сорилт ⚔ (нэмэлт) | challenge (optional) | Applying `if`, `&&`, boundaries in a real problem; debugging | Bus driver Батаа's card reader program is broken (`>` instead of `>=`, `||` instead of `&&`, a missing `price = 250;`). The player fixes it with blocks (C++ shown live) and tests it on 8 passengers. The correct price shows only from the 3rd failed test. It can be skipped. |

Numbers are randomized per attempt in levels 2–7. A failed predict attempt re-rolls the numbers, so memorized answers don't work.

### 15. Implementation Status vs. Intent

| Intended (sections 4–8) | Status | Notes |
|---|---|---|
| **Variables** | **Implemented** (levels 1–5) | The strongest part of the project. Step-by-step execution with animated memory boxes directly shows declaration, assignment, copying, and overwriting. |
| **Conditions** | **Partly redesigned** (levels 6–9) | Levels 6–7 (new): `if` and `if / else` explained with an animated flowchart and checked by a mini test that includes boundary values. Levels 8–9 are still the old dropdown design: `\|\|` is offered but never *required*, and `else if` appears only in the boss level. |
| **Loops** | **Not implemented** | No levels, no interpreter support (`Interp` only runs straight-line code, with no blocks or jumps), and no design in the repo. Only the end-of-game text mentions "Part 2 (Loops)". |
| Accurate representation (C++) | **Implemented** | Since 2026-11-23 all learner-facing code is consistent C++. |
| Meaningful feedback on mistakes | **Partial** | Good: per-step explanations, C++ errors (undeclared, uninitialized, missing `;`), guard boundary warnings, cinema edge-age and coupon hints. Weak: a wrong prediction shows the correct value plus a fixed hint and does not diagnose *which* misconception the guess shows. |
| Progressive difficulty | **Partial** | Smooth through levels 1–7 (`if` → `if/else`). Level 9 (boss) still jumps to `else if`, `double`, and sequential ifs at once. |
| Learner-progress visualization (research topic) | **Partial** | Chapter screen with cleared/open/locked stops per chapter, stars per level and per chapter, and a star total. Not yet linked to a specific finding of the cited study. |
| Save progress / level select | **Implemented** (2026-11-25; chapter screen 2026-11-27) | `progress.gd` + `route_view.gd`. |
| Consistent visual identity | **Implemented** (2026-11-27) | «Paper Diorama» through `ui_theme.gd` for every screen. Level-specific scenes exist for levels 8–9 (bus) only; levels 1–7 have no illustrated scene yet. |
| Evaluation of learning (objective 6) | **Not implemented** | No attempt counts, timings, or error logs are recorded. No pre/post test. |
| Traceability Research → Features | **Not documented** | No document in the repo links research findings to specific mechanics. |
| Advanced topics (recursion, trees, graphs, DP) | Not implemented; not planned as core | Do not describe them as features. |

### 16. Known Issues (open)

**Visual (after the 2026-11-27 redesign)**
- ✓ is drawn by the Segoe UI Symbol fallback and looks like «√». A symbol font with a proper check mark (or drawing it) would fix it. On non-Windows systems the fallback list may find no symbol font.
- Some player text is still longer than the 4-word rule: story lines (level 8 especially), the level 8 verdict line, the challenge feedback note (`_hint`) and the wrong-passenger list. They were restyled, not rewritten.
- Level 8's scene leaves a lot of empty sky above the bus (the view expands to fill its column).
- Not built yet from the approved mockups: a scene strip in variable levels 2–5, the yellow path trace of a failing passenger in the challenge flowchart, the live `60 > 60 → false` label beside the code line, the ≠ «not linked» mark and the crossed-out old value in level 2.

**Concept and teaching**
- Level 8 (bus door `&&/||`) still uses the old "change dropdowns until green" mechanic (now in the bus world); `||` is offered but never required. Planned rework: 8 = "debug the bouncer", 9 = else-if chain boss drawn as a flowchart cascade (it shows why `else if` is not the same as two separate `if`s).
- Flow levels evaluate conditions with `Expression`, not `Interp`. That's fine for single comparisons; `Interp` still has no `{ }` blocks or `else`.
- The cinema template uses `double` but no level introduces types other than `int`.
- The C++ shown is a simplification: the game runs line by line and stops at the first error, whereas a real compiler rejects the whole program before it runs. The error messages state this.

**Code**
- The old cinema-boss code in `main.gd` (`_setup_cinema`, `_test_cinema`, `cinema_panel`…) is unused since the challenge level replaced it, and can be removed.
- Unused code: the `if` branch of `Interp` and its "skipped row" state (no level uses `if` lines in the step view), and the guard `free` mode (level 9 "Өөрийн клуб" was removed).
- `main.gd` holds all modes in one file with UI built in code. That is manageable at the current size, but adding loops there will make it hard to maintain.

**Repository**
- 54 files under `addons/godot_ai/` are modified but not committed (plugin self-update). Not touched by the 2026-11-23 work.
- Old commits still contain the 98 MB exe and the `.godot/` cache. Untracking only removes them from future commits.
- No README and no automated tests in the repo.

### 17. Recommended Next Steps (prioritized)

1. **Design and build Loops (Part 2):** this is the biggest missing core topic. It requires extending `Interp` with blocks and jumps (`while` / `for` in C++ syntax) and visualizing the loop condition check and iteration count in the existing step view. High effort, core requirement.
2. **Add evaluation instrumentation:** record per-level attempts, time, and wrong answers to `user://`, and plan a pre/post test. Needed for academic objective 6 and the thesis evaluation chapter. Medium effort.
3. **Finish the condition section:** rework level 8 (`&&`/`||`, ideally reusing the flowchart with a compound condition or a "debug the bouncer" task where `||` is sometimes the correct answer) and level 9 (else-if chain boss as a flowchart cascade with drag-to-order rules). Medium effort.
4. **Misconception-specific feedback:** detect common wrong guesses (for example, guessing `A+B` on level 2 indicates the "linked boxes" misconception) and explain that specific mistake. Connect this to the error-focused research in section 6 only where the paper actually supports it. Medium effort.
5. ~~Progress and persistence~~: done 2026-11-25 (route map, save, stars); chapter screen + Paper Diorama redesign done 2026-11-27. Next visual-explanation extras (approved in the mockups, not built): scene strip for variable levels, failing-passenger path trace, live condition evaluation label. Next in the same direction: «Be the CPU» drag-and-drop execution for levels 2–4 (agreed design: fetch value from box → code, then drop result into the target box; wrong drops explain the specific misconception, such as "linked boxes" in level 2).
6. **Repository:** commit the cleanup, decide on the addon update, put builds on GitHub Releases, and add a README. Low effort.

### 18. Change Log

**2026-11-27: «Paper Diorama» visual redesign + chapter screen; no narrator**
- Direction chosen by the user from 3 options and approved from Godot-rendered mockups: a level-based game with real-life scenes per concept, one consistent look (cream paper UI, ink outlines, soft shadows, dark code panels, yellow next-action glow), no storyline, no hacker theme, no dialogue. Bataa stays only as a silent mascot.
- New `ui_theme.gd` (palette, fonts, Theme, StyleBox and drawing helpers) and `assets/fonts/` (Nunito + JetBrains Mono, OFL). Every screen restyled: top bar with «← Бүлэг» / chapter chip / title / stars / «?» hint; dark syntax-coloured code panels; cardboard variable boxes; paper flowcharts with a diamond condition; paper-diorama bus scenes (levels 8–9).
- `route_view.gd` rewritten as the chapter screen (chapter cards + level path), same API. Levels got a `chapter` field («var» levels 1–5, «cond» 6–9).
- Narration removed: the challenge's 4-line dialogue is gone (it opens in the editor; rules are 3 chips; the symptom hint is a note beside them), speech bubbles removed from the map and scenes, story lines no longer name Bataa, «Сорилт ⚔ (нэмэлт)» → «Сорилт» (no emoji), «Засъя ⚔» removed. Game logic, C++ semantics, tests and stars unchanged.
- Bug fixed on the way: the «Маршрут» button was clipped off-screen in the challenge level; navigation now lives in the top bar.
- Verified: all scripts load headless; existing tests pass (map/save/stars 16 checks, flow + guard stars, level 8 typing 6 checks) and a new challenge test (9 checks: opens in build mode, glow on «Турших», failed test shows the note outside the scene, typed C++ fix solves it with 2 stars, skip works). Screenshots at 1152×648 of both chapter views and levels 1, 2 (guess and running), 4, 5, 6, 7 (test), 8 (idle and running), 9 (build and failed test). **Not tested:** real mouse play (chapter cards, drag-and-drop in level 5 and the challenge), on a second PC / non-Windows fonts.

**2026-11-25: Level 8 moved to Bataa's bus door; spin box typing fix**
- Bug (user report): a number typed into a level 8 spin box was ignored until Enter or a focus change, so «Турших» tested the old value. Now `update_on_text_changed` is on, and `_on_spin_key` builds the text itself, keeping the caret at the end (otherwise the second digit was lost, «20» → 2). It also maps physical digit keys for the Mongolian Cyrillic layout. `_physical_digit()` is shared with the guess box.
- Level 8 reskin: the nightclub became Bataa's bus (`guard_view.gd`); `ticket` → `card`; `letIn()`/`turnAway()` → `openDoor()`/`keepClosed()`; header «ХААЛГАНЫ ДҮРЭМ»; story «Шөнийн рейс…». Same test logic.
- Verified: headless test typing real key events (Mongolian layout symbols and Latin digits, two-digit values, no Enter) → value and code update live, and the correct rule passes with 3 stars. Map and flow tests re-run, and screenshots of level 8 idle and mid-test.

**2026-11-25: Bataa's route map, saved progress, stars, bus-world variable names**
- Goal (user feedback: the game felt boring, with no world and nothing to chase): a level select map «Батаагийн маршрут» (`route_view.gd`) that the game opens on. A Batbus drives between stops, cleared levels get 1–3 stars, and progress is saved (`progress.gd`, `user://progress.cfg`).
- New «Маршрут» button and Esc to return. Map keys: ← / → and Enter. «Дараагийн түвшин» now drives the bus to the next stop before the level opens.
- Variable names chosen by the user to fit the bus story: level 1 `a` → `people`; level 2 `a`, `b` → `people`, `note`; level 3 `count` → `people`; level 4 `x`, `y`, `z`, `w` → `people`, `full`, `left`, `ans` (`result`/`buses` made line 4 wider than the code column). Stories of levels 1–4 and 5–7 now mention Bataa or the bus. Levels 8–9 are unchanged (level 8 is still the old club design).
- No emoji on the map: the optional challenge stop shows its number (⚔ rendered as a color emoji).
- Verified: headless test (fresh save shows only stop 1 open, a locked stop is ignored, Enter opens level 1, tutorial gives 3 stars + unlock, Next drives the bus to level 2, one wrong guess gives 2 stars, Esc returns to the map, save/reload round trip, levels 2–5 run for 200 random rolls, arrow keys stop at the last open stop), plus flow (1 wrong → 2 stars) and guard (3 stars). Screenshots at 1152×648 of the map and levels 1, 2 and 4. A real mouse play-through of the map is still pending.

**2026-11-24: Challenge canvas: zoom/pan, input block, box-style variables**
- The canvas fills its whole column (no scroll box). Mouse wheel zooms around the cursor, and the middle button (mouse 3) drags the view. During building the bus scene shrinks (`BusView.set_compact`) so the program area is larger.
- Inputs are now clear in the flowchart too: a parallelogram «Оролт: age, card» after Эхлэл (Flowgorithm's input symbol).
- Variable blocks follow the user's sketch: name tag on top, value box, yellow `int` tag below (the same box as levels 1–5), also in the palette.

**2026-11-24: Challenge editor rebuilt as Flowgorithm-style + fullscreen**
- Based on the user's sketch: bus scene on top; palette (left), flowchart canvas (middle), C++ code (right).
- Blocks are dragged from the palette onto arrows and snap in; the chart re-lays itself out (`flow_canvas.gd`). Existing blocks can be dragged to another arrow (an `if` can't be dropped into itself). Clicking a block opens its fields in a strip under the canvas (variable, operator, value, optional `&&`/`||` part, add/remove else, delete).
- Two-way sync, as the user chose: block changes rewrite the code; typing code rebuilds the blocks 0.5 s after typing stops. Parse errors are shown in red with a line number (e.g. «2-р мөр: ';' дутуу байна», «Харьцуулахад '==' хэрэглэнэ»), and the blocks keep the last valid version. `else if` becomes an `if` inside `else`.
- Fullscreen: the game starts fullscreen (`display/window/size/mode=3`) and F11 toggles it. The challenge level hides the title, story and message rows to use the whole window.

**2026-11-24: Optional challenge level «Сорилт ⚔» (replaces the cinema boss)**
- The story is the user's idea. Bus driver Батаа (drawn in `bus_view.gd`) explains in 4 short lines that his card-reader program is broken and gives the fare rules (60+ free, student card and under 18: 250₮, others 500₮; simplified example prices). The player can accept («Засъя ⚔») or skip («Сорилтыг алгасах»).
- The broken program is the hint: 3 planted faults (`age > 60`, `card == 1 || age < 18`, missing body shown as `// ???` in C++). Flowgorithm-style block editor (`challenge.gd`) with live C++, as the user chose. Several solutions pass, because grading uses 8 test passengers (boundaries 17/18, 59/60).
- On a test: passengers board and the reader shows the charged price. Wrong ones line up with ✗ and their price, and Bataa gives a symptom hint (not the answer). The correct prices are shown only from the 3rd failed test. Solved: ★ in the title + «Дуусгах».
- In this level the animation-skip button is hidden (F still works), so there aren't two «Алгасах» buttons.
- Verified: headless challenge test (dialogue/keys, broken program fails, the 3 fixes pass, alternative nested solution, errors, 3-try reveal, solved/skip) plus the full regression, and screenshots.

**2026-11-24: Level 6 teaches `>` / `>=` / `==`**
- Three more explanation steps: the flowchart is replaced by a number line (T−3…T+3) where the numbers that make the condition true turn green (`FlowView.numline_*`, `op_true`). Captions: «>» тэнцүү нь орохгүй / «>=» тэнцүү нь орно / «==» зөвхөн нэг тоо (= нь хадгалах, == нь харьцуулах!).
- The test stays short (user: avoid boredom): 3 correct answers, operators asked in a shuffled queue (one each when all answers are right), with values T−1, T or T+1, where the operators differ. A wrong `==` answer explains «== зөвхөн яг T үед үнэн».

**2026-11-24: Flow mini test UX**
- Players didn't notice the test question (plain white text). Now there is a large yellow question «temp = 37 → ҮНЭН үү, ХУДАЛ уу? ○○○» (`_show_question`), and two pulsing answer buttons «← ХУДАЛ» (red) / «ҮНЭН →» (green) appear only while choosing. The flowchart paths pulse red/green, the edges are labeled «худал F» / «T үнэн», and hovering shows a hand cursor. The wrong-answer line uses ҮНЭН/ХУДАЛ words.

**2026-11-24: Condition section phase 1, flowchart levels 6–7**
- Based on the user's sketches: code + flowchart (condition oval, F left / T right, block box(es), paths merge). Layout follows level 1 (code on top, animation below), as the user chose. The example code uses small real stories, also the user's choice: `temp`/`fan`, `score`/`pass`.
- New `flow_view.gd`; new mode `flow` in `main.gd` (explanation of 3 steps + mini test of 3 correct answers, with the boundary value always asked). `_make_var_box` helper factored out of `_refresh_boxes`.
- Levels: the old 1-rule bouncer level was removed (its `>`/`>=` boundary lesson is now in the 6/7 tests), and level 9 "Өөрийн клуб" was removed (user's choice). Part 1 still has 9 levels.
- Dev shortcut F9 (debug builds only) skips to the next level.
- Verified: headless flow test (explanation, wrong/right picks, keys, boundary round, skip, F9) plus the full regression, and screenshots of levels 6–7 from a short windowed run.

**2026-11-24: Typing fix, random tutorial, three tries, card dragging (levels 1–5)**
- Bug: the guess box could not be typed into on the Mongolian Cyrillic keyboard layout. Its number row types "№", ":", "е"… instead of digits, and the digits-only filter removed them. Fixed by mapping physical number-row and numpad keys to digits. The box also focuses automatically, and clicking anywhere on it focuses it.
- Level 1 tutorial numbers are random on each view and replay (`tut_v` 2–9, `tut_k` 1–5). Levels 2–7 were already random per run (checked across 3 launches). Levels 8–9 are unchanged by the user's choice ("fixing until level 5").
- Predict levels hide the answer until a correct guess or the 3rd wrong try (section 13, item 12). The per-step message clearing was removed so the "3 удаа буруу" note stays visible during the run.
- Level 5 dragging redone as a lifted card with placeholder and sliding neighbors (section 13, item 13), replacing Godot's text-only drag preview.
- Verified headlessly: Cyrillic key events through the real input path type digits; the 3-try flow; drag lift/follow/reorder/drop/renumber; and the full regression suite. Visual check of level 5 dragging in the running game is still pending (the editor test tool cannot type guesses to reach level 5).

**2026-11-24: Controls, skip, guess box (levels 1–5, keys global)**
- Per-step explanation messages removed in levels 2–5. The animation shows the step, and only errors and the final result are written. (`Interp` still produces `note`, now unused by the UI.)
- Level 5: the Up/Down buttons were removed. Lines move by mouse drag (`set_drag_forwarding`) or W / S / ↑ / ↓. Clicking a row only updates its border, so dragging can start.
- Keyboard shortcuts added (see section 13, item 9), plus a skip button «Алгасах »» (F).
- The predict answer area was redesigned by the user's choice (option A): dashed guess box → real box with ✓/✗. The wrong-answer text is now just the one-sentence hint, because the boxes show both values.
- The glow system now restores a control's own style after glowing, and the guess box has an explicit margin so it does not grow when it glows.
- Verified with headless tests (keyboard, skip timing, drag/move, guess filter, reveal/reset, glow, sizes, levels 1–8 regression) and visually in the running game (keyboard play-through to level 2).

**2026-11-23: Levels 2–5 UX, same approach as level 1**
- Titles shortened: Хуулбар / Шинэчлэх / / ба % / Дараалал. Each story is one line (for example "b хайрцаг a-г дагах уу?"; level 4 shows the rule by example "int: 17 / 3 = 5, 17 % 3 = 2"). Hints cut to one sentence.
- Memory boxes now use the level 1 labeled-box look: name tag on top, yellow `int` sticker below (`_refresh_boxes`). A box waiting for its value is drawn empty (was `?`).
- Instruction text ("press Start", "press Step…") removed. A shared glow system (`_update_glow` / `_set_glow`) highlights the next control instead: the guess box, then Start, then Step, then Next on success or Reset on a wrong answer. Level 1 uses the same system. The condition levels (6–9) have no glow. The glow reuses the control's own inner margins, so buttons don't change size.
- Step messages are short math lines chosen by the user: `шинэ: y = x / 4 = 7`, `a: 7 → 10`, `(cond) үнэн → …`. C++ error messages are unchanged, because they are the teaching feedback.
- Result messages: success "ЗӨВ ✓" + one-sentence hint. Wrong prediction "Таны таамаг: N. Жинхэнэ: b = M" + one-sentence why. Wrong order "total = X, зорилт: G".
- Headers shortened to "C++" / "Санах ой", and the prediction prompt to "Төгсгөлд b = [ ]".
- Verified headlessly (glow sequence, button sizes, levels 1–8 regression, interpreter tests) and visually in the running game (level 2 full flow).

**2026-11-23: Level 1 UX, the labeled box**
- Goal: let visuals carry the explanation instead of long text (the user's observation that polished apps avoid 4–6 instruction sentences per screen). The "variable = labeled box" metaphor matches the Transcode video "Coding Basics: Variables".
- Level 1 title shortened to "Хайрцаг". Text cut from about 75 words to about 15: story "Хувьсагч = нэртэй хайрцаг.", captions Хайрцаг бэлэн, утга өгөөгүй / 2 хадгалагдлаа / «=» нь «хийх, олгох» / Хуучин 2 → шинэ 3.
- **Deliberate simplification:** after `int a;` the tutorial box is drawn *empty*. A `?` was tried first but confused learners ("is a value hidden?"). In real C++ the box holds an unknown leftover value, not nothing, so the caption only says "no value given" and never claims the box is empty or 0. `Interp` still treats reading such a variable as an error and explains the garbage value.
- The start hint text was replaced by a visual cue: the «Дараагийн алхам» button gets a yellow border and a pulsing glow until its first press (now part of the shared `_update_glow` system). It comes back on «Дахин үзэх».
- Added the name tag and `int` sticker widgets plus helpers `_tag_style`, `_fade_in`, `_mark` in `main.gd`. No other level changed.
- Verified with a headless test of steps, replay, and the regression of levels 1–8, and visually in the running game (screenshots of each step).

**2026-11-23: C++ conversion, accuracy and bug fixes, repo cleanup**
- Learner-facing code converted to C++: level lines (`int x = ...;`), tutorial (`int a;` shows `?`, explained as an unknown value), guard rules (`&&`, `||`, `if (...) { ... } else { ... }`), cinema template (`double`, `else if`, `;`).
- `Interp` rewritten for the C++ subset in section 13, with declaration rules and Mongolian error messages.
- Level 4's `/` lesson is now correct for the stated language, since C++ `int / int` truncates.
- Guard test crowds always include someone well below and well above the age limit. A headless check of 1,000 crowds confirmed the wrong rule `age != T-1` no longer passes.
- Prediction box resets to 0 for each level and attempt, and Start is blocked until a guess is entered.
- Cinema: the coupon hint now explains the program's fixed order instead of telling the player to change it, and "Next level" is hidden when a re-test fails.
- Removed unused `inst.solution`.
- Added `.gitignore` (`.godot/`, `*.exe`, `*.pck`, `*.zip`) and untracked the cache and exe files. The files remain on disk. Not yet committed.
- Verified headlessly with Godot 4.7.2: every level's program runs for 200 random rolls, the C++ error cases behave as described, and the real scene was driven through levels 1–8 (correct answers solve; wrong orders, wrong rules, and wrong coupon values fail).
