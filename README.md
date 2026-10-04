# hacker_pen

A Hacker News reader built with Flutter for phones, iPad, and Mac.

## Apple platforms

The iPhone app, iPad app, and native Flutter macOS app use the existing
`dev.suica.hackerPen` identity. iOS supports iPhone and iPad from iOS 15; the
macOS target starts at macOS 12 to match the installed Xcode toolchain. These
deployment targets do not replace testing on supported devices and current
operating systems.

Phones retain the original reading interface in portrait and landscape: the
collapsible feed and article headers, hideable floating action dock, and
Comments/Summary bottom sheets. iPad uses the same presentation below 840 logical
pixels and a reading workspace at larger widths. macOS uses desktop controls at
every supported window width.

The Mac/iPad workspace adapts to the available width in logical pixels:

| Available width | Layout |
| --- | --- |
| Below 840 | News → Article; iPad uses the original draggable bottom sheets, Mac an attached inspector |
| 840–1119 | News + Article, or Article + Inspector when the inspector is open |
| 1120 or more | News + Article + optional Inspector |

News is the entry point. Selecting a story opens its linked article or self-post.
Comments and summary belong to that article and open from its header in an
optional inspector, initially closed. The article stays visible while its
inspector is open; it has no independent visibility toggle. Closing the article
also closes the inspector and returns to News.

News and the inspector can each be collapsed. At intermediate widths, opening
the inspector temporarily hides News; closing it restores News only if it was
previously enabled. Selecting another story keeps an open inspector and its
selected Comments/Summary tab, following the new article. A newly selected
article's summary requires the explicit Generate action.

Desktop panes share one aligned toolbar row. News keeps its directly clickable
Top/New/Best/Ask/Show category strip below that row. The article toolbar owns
Comments/Summary actions; the inspector shows its tabs without repeating the
article title. Larger windows use denser story rows.

Resizing an iPad converts an open bottom sheet into the article inspector and
back, preserving the selected article, mounted WebView, panel content, and scroll
positions. Sidebar choices last for the current session and are not synced or
saved between launches.

On Mac, **Hacker Pen → Settings…** and **Command + comma** open a dedicated
settings window, leaving the reading window intact. Settings use desktop forms
and dialogs. The phone-only status-bar extension preference remains on iOS.

The Mac window starts with 1200 × 800 points of content and can shrink to
360 × 480 points. iPad supports portrait, landscape, and resizing; this release
does not promise independent state across multiple app windows. Existing
reading, comments, profiles, optional AI, and settings remain in scope.

On Mac and iPad hardware keyboards, use Command for the shortcuts below. Other
platforms use Control. Escape also goes back without a modifier.

| Shortcut | Action |
| --- | --- |
| Command + R | Refresh the story list |
| Command + , | Open settings |
| Command + B | Toggle News |
| Command + Shift + B | Toggle the article inspector |
| Command + [ or Escape | Dismiss the inspector, then close the article |

Mac View menu commands keep shortcuts available while web content has focus.
**File → Close Window** uses **Command + W**, including in Settings.

Apple submission material is drafted in [docs/app-store-metadata.md](docs/app-store-metadata.md).
Open requirements and device validation are tracked in
[docs/app-store-readiness.md](docs/app-store-readiness.md). This is preparation
work, not a submitted or submission-ready release.

## Source layout

- `lib/src/core/`: shared API clients, AI configuration, platform bridges,
  reading preferences, design-system components, and utilities.
- `lib/src/features/*/data/` and `domain/`: feature repositories and models.
- `lib/src/features/*/presentation/views/`: screens and layout orchestration.
- `lib/src/features/*/presentation/widgets/`: focused UI components, including
  article headers, WebView, summary, feed tabs, and settings controls.
- `lib/src/features/*/presentation/cubit/`: feature state and async operations.
- `test/`: matching core/feature tests and shared fakes in `test/support/`.

## Development checks

Use the Flutter SDK pinned in `.fvmrc`:

```sh
fvm install
fvm flutter pub get
fvm dart format lib test tool
fvm flutter analyze
fvm flutter test
```

VS Code formats Dart files on save when the Dart extension is installed.
CI checks formatting, static analysis, and tests. To check formatting without
modifying files, run:

```sh
fvm dart format --output=none --set-exit-if-changed lib test tool
```

## AI setup

1. Open **Settings → Providers & keys → Add API key**.
2. Choose **OpenAI**, **Anthropic**, or **Gemini** and save that provider's key.
3. Return to **Active model**, choose a configured provider, then select a model
   from the available fast and lightweight recommendations. The active selection changes only after selecting a model.

Each provider's key is stored separately in secure storage. Adding or replacing a
key does not switch the active model. Anthropic uses the native Messages API;
Gemini uses the native generateContent API. API Trust remains hidden.

Only one key is stored per provider. Providers with a saved key are omitted from
the add-key picker; use the saved entry to replace or remove a key. The model
picker prioritizes Luna, Mini/Nano, Haiku, and Flash/Flash-Lite, showing only models
returned by the provider and collapsing dated duplicates.
