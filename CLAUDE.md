# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

macOS 14+ menu bar app. Swift 5.9+, SwiftUI.

## Patterns

- `@Observable` for state classes
- `@AppStorage` for persistence
- `@FocusState` for focus management
- `MenuBarExtra` for menu bar integration
- Native SwiftUI components (no NSViewRepresentable wrappers)
- `#Preview` macro for previews
- `.animation(_:value:)` with explicit value

## Git Workflow

- New task = new branch from main
- Branch naming: `feature/description` or `fix/description`
- Delete branches after merge (local and remote)
- Force push on feature branches when amending

```bash
# Starting a new task
git checkout main && git pull
git checkout -b feature/add-dark-mode

# After PR is merged
git checkout main && git pull
git branch -d feature/add-dark-mode
git push origin --delete feature/add-dark-mode
```
