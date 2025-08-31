# AI Agent Instructions

## 1. Initial Setup (Bootstrap)
When you start a new session in this project, you MUST perform the following steps first:
1.  Use the `glob` tool to find all markdown files in `docs/guidelines/`.
2.  Read all files found in the previous step using the `read_many_files` tool.
3.  These files contain all the rules for development. You must follow them at all times.

## 2. Key Commands
- **Linter Command:** `flutter analyze`
- **Test Command:** `flutter test`

## 3. Key Prohibitions
- Do not use `print()` statements in the application code (`lib/`). Use `debugPrint` or the project-specific `DebugLogger` instead.
