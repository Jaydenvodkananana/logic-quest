# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 1. Project Context
- This repository contains Logic Quest, a Godot-based educational programming game and Computer Science graduation project.
- The primary goal is to teach programming fundamentals through interactive gameplay and visual problem-solving.
- The game targets Mongolian-speaking learners: **all player-facing text and most code comments are in Mongolian**. Keep new UI strings in Mongolian and match the existing tone.
- Read `PROJECT_CONTEXT.md` before making significant development decisions. It contains the project's academic background, educational objectives, research context, and overall direction.
- Treat this as an educational software project, not simply a puzzle game.
- **All code shown to learners is C++** (decided 2026-11-23): `int x = 5;`, semicolons, `if (cond)`, `else if`, `&&` / `||` / `!`. Its behavior must match real C++, for example `int / int` truncates and using an undeclared variable is an error. Never mix in Python- or GDScript-style syntax in learner-facing code or text. Where the game simplifies C++ (for example, running line by line where a real compiler would reject the whole program), say so in the player-facing message.

## 2. Running and Building
- Engine: Godot **4.7** (`config/features` in `project.godot`). Verify before using version-specific APIs.
- Run: open the folder in the Godot editor and press F5, or `godot --path .` (editor: `godot -e --path .`).
- Export (Windows preset in `export_presets.cfg`, PCK embedded): `godot --headless --path . --export-release "Windows Desktop" "Logic Questv3.exe"`. The committed `Logic Questv3.exe` / `.console.exe` are build outputs.
- Headless check that all scripts load: `godot --headless --path . --quit-after 300` (no output except the godot_ai line means no script errors).
- There is no test suite or linter in the repo. Verify changes by running the game, or by driving `main.tscn` from a temporary `extends SceneTree` script run with `godot --headless --path . -s <script>`. Keep such scripts outside the repo unless asked. The `godot-ai` MCP tools (`project_run`, `editor_screenshot`, `logs_read`, etc.) can drive the editor through the `addons/godot_ai` plugin.

## 3. Where Project Knowledge Lives
- This file holds **permanent development instructions** only.
- `PROJECT_CONTEXT.md` holds **evolving project knowledge**: intent and objectives (sections 1–12), and the verified architecture, level inventory, implementation status, known issues, and next steps (sections 13–18).
- After any change to game code, levels, or features, update the relevant sections 13–18 of `PROJECT_CONTEXT.md` and their verification date in the same task.
- `addons/godot_ai/` is a third-party MCP editor plugin, not game logic. Do not edit it for gameplay changes.

## 4. Development Rules
- Always inspect existing code and architecture before making changes.
- Do not rewrite existing systems without a clear technical reason.
- Preserve existing functionality unless the requested change requires modifying it.
- Prefer simple, readable, maintainable code over unnecessary abstractions.
- Use strict typing in GDScript wherever practical.
- Follow the naming conventions and coding style already established in the project.
- Avoid unnecessary dependencies and plugins.
- Do not create duplicate systems when an existing implementation can be extended.

## 5. Godot-Specific Rules
- Understand the relationship between scripts, scenes, nodes, signals, and resources before modifying them.
- Be especially careful when modifying `.tscn`, `.tres`, and `.godot` files.
- Do not restructure scenes or change node paths without checking their dependencies.
- Before modifying scenes or other interconnected resources, explain the intended changes and ask for approval when the changes are potentially destructive or extensive.
- Check for broken node references, signal connections, resource paths, and runtime errors after changes.

## 6. Educational Design Rules
- Every gameplay mechanic should have a clear educational purpose.
- Programming concepts must be represented accurately.
- Prioritize understanding over memorization.
- Feedback should explain why an answer or solution is incorrect, not merely display success or failure.
- Introduce concepts progressively, from simple to complex.
- Avoid adding gameplay features that do not support the learning objectives without a clear reason.

## 7. Research and Academic Integrity
- Keep the implementation aligned with the objectives described in `PROJECT_CONTEXT.md`.
- Do not invent research results, academic references, or implementation claims.
- Distinguish implemented features from planned features.
- When proposing a feature based on educational research, explain the connection between the research finding and the proposed implementation.
- Keep technical documentation consistent with the actual code.

## 8. Working Workflow
Before implementing a significant feature:
1. Understand the requested functionality.
2. Inspect related existing files.
3. Identify dependencies and possible side effects.
4. Explain the proposed implementation.
5. Wait for approval when the change is large, destructive, or affects interconnected scenes.

After implementation:
1. Explain what was changed.
2. List modified and created files.
3. Explain important technical decisions.
4. Identify anything that still needs testing.
5. Check for errors and regressions where possible.

## 9. Important Restrictions
- Do not modify files unrelated to the requested task.
- Do not remove existing functionality without permission.
- Do not assume planned features are already implemented.
- Do not make large architectural changes without discussing them first.
- Do not prioritize visual decoration over functionality and educational value.

## 10. Main Development Principle
Logic Quest must successfully combine three things:

1. Functional and maintainable software.
2. Meaningful game-based learning.
3. Accurate representation of programming concepts.

## 11. UI & UX Rules 
- Keep all player-facing UI text under 4 words (use icons, color highlights, and visual cues instead of tutorial paragraphs).
- Never write multi-sentence popups or text boxes to explain mechanics.
- Teach new coding/algorithm concepts through progressive disclosure (one mechanic per micro-level), step-by-step execution highlighting, and visual ghost previews.
- Put optional detailed explanations behind a `?` Hint button rather than forcing them on screen.

Always consider the educational purpose behind every technical decision.
