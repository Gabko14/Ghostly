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
xcodebuild -project Notebar.xcodeproj -scheme Notebar -configuration Debug build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

open ~/Library/Developer/Xcode/DerivedData/Notebar-*/Build/Products/Debug/Notebar.app
```

### Interact with the App

```bash
# Click menu bar icon (menu bar 2 = status bar area)
osascript -e 'tell application "System Events" to click menu bar item 1 of menu bar 2 of application process "Notebar"'

# Type text into focused element
osascript -e 'tell application "System Events" to keystroke "text here"'

# Press Enter
osascript -e 'tell application "System Events" to key code 36'

# Cmd+W to close
osascript -e 'tell application "System Events" to keystroke "w" using command down'

# Get UI hierarchy for debugging
osascript -e 'tell application "System Events" to tell application process "Notebar" to get entire contents'
```

### Take and View Screenshots

```bash
screencapture -x /tmp/screenshot.png
```

Then use the Read tool on the PNG to see the app's visual state. SwiftUI popovers may not expose all elements via accessibility, so use screenshots to verify UI.

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
