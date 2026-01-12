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

## Testing

- All code changes must have unit tests
- Run tests before creating PR: `swift test` or `xcodebuild test`
- Tests must pass before PR can be merged

## PR Workflow

An issue can only be closed when ALL of these are complete:
1. PR is created and linked to the issue
2. Claude Code Review has commented on the PR
3. Review feedback is evaluated and addressed
4. All tests pass
5. PR is merged
6. Branches are deleted (local and remote)

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
