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

**Nothing ships without automated tests.** Before creating a PR, you must:

1. Write unit tests for all logic/model changes
2. Run tests: `xcodebuild test -project Ghostly.xcodeproj -scheme Ghostly -destination 'platform=macOS' -only-testing:GhostlyTests`
3. All tests must pass

Note: UI tests are not used because MenuBarExtra apps have severe XCUITest limitations (menu bar owned by system, no accessible elements). Instead, extract logic into testable utilities.

### What to Test

- Business logic, state management, data transformations
- Extract UI logic into testable utilities (e.g., `TextStatistics` for word/char counting)

## PR Workflow

An issue can only be closed when ALL of these are complete:
1. PR is created and linked to the issue
2. Wait for checks: `gh pr checks <number> --watch`
3. Read review: `gh pr view <number> --comments`
4. Review feedback is evaluated and addressed (see below)
5. Merge and cleanup: `gh pr merge <number> --merge --delete-branch`
6. Delete local branch: `git checkout main && git pull && git branch -d <branch>`

Complete this entire workflow yourself, including merge and branch cleanup.

**Review feedback:** Not all suggestions are worth implementing. Assess critically. Implement legit fixes (bugs, security, logic). Ignore noise (style nitpicks, "optional" suggestions). LGTM = merge.

**Non-code changes:** Skip testing if no code/UI changed. Still need PR review.

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
