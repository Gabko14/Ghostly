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

**Nothing ships without thorough testing.** Before creating a PR, you must:

1. Write unit tests for all code changes
2. Run unit tests: `swift test` or `xcodebuild test`
3. Build and launch the app
4. Manually verify affected UI using screenshots
5. Confirm all functionality works as expected

Do not skip manual testing. If you change UI code, visually verify it. If you change behavior, test it in the running app.

## UI Testing

Visually verify the app by interacting with it and taking screenshots.

### Build and Run

```bash
xcodebuild -project Ghostly.xcodeproj -scheme Ghostly -configuration Debug build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

open ~/Library/Developer/Xcode/DerivedData/Ghostly-*/Build/Products/Debug/Ghostly.app
```

### Interact with the App

```bash
# Click menu bar icon (menu bar 2 = status bar area)
osascript -e 'tell application "System Events" to click menu bar item 1 of menu bar 2 of application process "Ghostly"'

# Type text into focused element
osascript -e 'tell application "System Events" to keystroke "text here"'

# Press Enter
osascript -e 'tell application "System Events" to key code 36'

# Cmd+W to close
osascript -e 'tell application "System Events" to keystroke "w" using command down'

# Get UI hierarchy for debugging
osascript -e 'tell application "System Events" to tell application process "Ghostly" to get entire contents'
```

### Take and View Screenshots

```bash
screencapture -x /tmp/screenshot.png
```

Then use the Read tool on the PNG to see the app's visual state. SwiftUI popovers may not expose all elements via accessibility, so use screenshots to verify UI.

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
