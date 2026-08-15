# Contributing to Itsypad

Contributions are welcome – bug reports, fixes and features alike. Recent releases have shipped community fixes, and more are appreciated.

## Before you start

- For bug fixes, just open a PR – an issue first is nice but not required.
- For new features or larger changes, open an issue first so we can agree on the approach before you invest time.

## Getting set up

```bash
xcodegen generate
open itsypad.xcodeproj
```

Requires macOS 14+, Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen). Run `xcodegen generate` again after changing `project.yml` or adding/removing source files.

## Rules

1. **Tests pass and new logic is tested.** Run the full suite (`xcodebuild -scheme itsypad -configuration Debug test` or ⌘U) before opening a PR. Bug fixes include a regression test; new behaviour includes coverage.
2. **Fix root causes, not symptoms.** If a fix only patches the reported path, check the sibling paths too.
3. **Localize all user-facing strings.** Use `String(localized:defaultValue:)` with structured `{area}.{context}.{name}` keys (see the localization section in the README). Build once so Xcode populates `Localizable.xcstrings` – translations into the other languages are handled after merge, so English is enough in a PR.
4. **No dead code, no speculative abstractions.** Remove unused code; don't add flexibility nothing uses yet.
5. **Keep PRs focused.** One fix or feature per PR, with a description of the root cause and how you verified the change. Don't bump the version or edit the changelog – that happens at release time.
6. **Match the house style.** European-style titles (not American Title Case), en dashes (–) not em dashes (—), and code that reads like the surrounding code.
7. **No co-authorship lines** in commit messages.

## Both distribution flavours

The app builds as two schemes from one codebase: `itsypad` (direct/DMG) and `itsypad-appstore` (App Store, `APPSTORE` compilation condition). If your change touches entitlements, sandboxing or platform APIs, make sure both still build.
