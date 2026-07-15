# Model Lifecycle Contract

## Purpose

Define the user-visible contract for obtaining, loading, unloading, retrying, and inspecting the fixed local voice model.

## Status Contract

| State | Title intent | Secondary information | Trailing control |
|---|---|---|---|
| Not downloaded | Download required | Model identity, approximate size, local-processing notice | Download |
| Downloading | Transfer active | Percentage and approximate size | Determinate progress |
| Downloaded | Files available | Model identity | Load |
| Loading | Memory initialization active | Model identity and loading intent | Indeterminate progress |
| Ready | Model usable | Model identity | Unload |
| Failed | Lifecycle problem | Phase-specific diagnostic | Retry |

Exactly one primary control or progress indicator is visible for each state.

## Download Contract

1. Download begins only from an explicit user action.
2. Snapshot retrieval reuses valid local files after interruption.
3. Meaningful progress updates reach the status surface; insignificant repeated callbacks are suppressed.
4. The tokenizer asset is ensured after the primary snapshot returns.
5. Completion evidence is written atomically and must succeed.
6. Only then may the lifecycle proceed to downloaded and loading.

## Loading Contract

1. A successful first download proceeds directly to loading.
2. A complete snapshot detected at launch is loaded automatically.
3. Loading cannot begin again while already loading or ready.
4. Success stores an engine and reaches ready.
5. Failure clears the engine and exposes a load-specific message.

## Unload Contract

1. Unload asks the engine to release resources.
2. The engine reference is cleared.
3. The resulting state reflects whether a complete snapshot remains on disk.
4. Downloaded files are not deleted.

## Retry Contract

- Complete local snapshot: retry loading.
- Incomplete local snapshot: retry resumable download.
- The active retry state replaces the stale failure presentation.

## Finder Contract

The reveal action always targets an existing app-owned location:

- select the model snapshot directory when present;
- otherwise select the models root so partial or pre-download storage remains inspectable.

## Privacy and Security Contract

- Repository identities remain fixed by the application.
- Files remain under user Application Support.
- No credentials are stored by this feature.
- Model files are not uploaded or shared.
- Network access is limited to acquiring the fixed model and compatible tokenizer assets.
