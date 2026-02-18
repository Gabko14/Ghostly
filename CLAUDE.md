# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

macOS 14+ menu bar app. Swift 5.9+, SwiftUI.

## Patterns

- `@Observable` for state classes
- `@MainActor` on state classes that drive UI (`AppState`, `SettingsManager`, `TabManager`)
- `@Bindable` in views when mutating `@Observable` models (`SettingsView`, `TabBarView`)
- `UserDefaults` via manager classes for persistence
- `@FocusState` for focus management
- `MenuBarExtra` for menu bar integration
- Native SwiftUI components (no NSViewRepresentable wrappers)
- `#Preview` macro for previews
- `.animation(_:value:)` with explicit value

## Dependencies

- `KeyboardShortcuts` `2.4.0`
- `MenuBarExtraAccess` `1.2.2`

## Keyboard Shortcuts

This project uses both SwiftUI `.keyboardShortcut()` and the `KeyboardShortcuts` library. Use one or the other per shortcut, never both (causes duplicate triggers):

- **Global shortcuts** (work when app unfocused): Set up in `AppState.init()` via `KeyboardShortcuts.onKeyDown()`/`onKeyUp()`. Configurable via `KeyboardShortcuts.Recorder` in Settings.
- **In-app shortcuts** (fixed, only when focused): Use SwiftUI `.keyboardShortcut()` on hidden buttons.

## Testing

Tests use a mixed framework setup:

- Swift Testing (`import Testing`) for most suites (`AppStateTests`, `KeyboardShortcutTests`, `SettingsManagerTests`, `TabTests`, `TextStatisticsTests`)
- XCTest (`import XCTest`) for `MarkdownTransformerTests`

**Nothing ships without automated tests.** Before creating a PR, you must:

1. Write unit tests for all logic/model changes
2. Run tests: `xcodebuild test -project Ghostly.xcodeproj -scheme Ghostly -destination 'platform=macOS' -only-testing:GhostlyTests CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`
3. All tests must pass

Note: UI tests are not used because MenuBarExtra apps have severe XCUITest limitations (menu bar owned by system, no accessible elements). Instead, extract logic into testable utilities.

### What to Test

- Business logic, state management, data transformations
- Extract UI logic into testable utilities (e.g., `TextStatistics` for word/char counting)

## Architecture Notes

- Color system is Catppuccin Mocha via `Color.cat*` tokens in `CatppuccinColors.swift`
- Document model is tab-based (`TabManager` owns tabs + active tab persistence)
- Inline markdown rendering is symbol-transformation based (`MarkdownTransformer`), not rich text

## PR Workflow

An issue can only be closed when ALL of these are complete:
1. PR is created and linked to the issue
2. Wait for checks: `gh pr checks <number> --watch`
3. Read review: `gh pr view <number> --comments`
4. Review feedback is evaluated and addressed (see below)
5. Merge and cleanup: `gh pr merge <number> --merge --delete-branch`
6. Delete local branch: `git checkout main && git pull && git branch -d <branch>`

Complete this entire workflow yourself, including merge and branch cleanup.

**Review feedback:** Not all suggestions are worth implementing. Assess critically. Implement legit fixes (bugs, security, logic). Ignore noise (style nitpicks, "optional" suggestions).

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

Before ending a work session, run `bd doctor` and fix all reported problems.

## Running the App

After implementing a behavior/UI change and building, always kill any running instance and relaunch so the user can test immediately:

```bash
killall Ghostly 2>/dev/null; sleep 1
open /path/to/DerivedData/Ghostly.app
```

Do this after each implementation step that changes app behavior and at minimum when work is finished, so the user can test whenever they want.

## Releasing

Manual process. No CI automation for releases.

1. **Bump version** — update `MARKETING_VERSION` in both Debug and Release build configs in `project.pbxproj`, and increment `CFBundleVersion` in `Info.plist`
2. **Commit via PR** — branch `release/vX.Y`, commit version bump, push, PR, wait for CI, merge
3. **Build release** from main:
   ```bash
   git checkout main && git pull
   xcodebuild build -project Ghostly.xcodeproj -scheme Ghostly -configuration Release -destination 'platform=macOS' -derivedDataPath .derivedData CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
   ```
4. **Create DMG**:
   ```bash
   hdiutil create -volname "Ghostly" -srcfolder .derivedData/Build/Products/Release/Ghostly.app -ov -format UDZO /tmp/Ghostly-X.Y.dmg
   ```
5. **Create GitHub release**:
   ```bash
   gh release create vX.Y /tmp/Ghostly-X.Y.dmg --title "Ghostly vX.Y" --notes "release notes here"
   ```

App is not code-signed. Users must run `xattr -cr /Applications/Ghostly.app` after install.
