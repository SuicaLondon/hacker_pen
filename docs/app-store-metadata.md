# App Store metadata drafts

Updated: October 5, 2026.

These English drafts cover the existing reading and optional AI features on
iPhone, iPad, and native macOS. They have not been uploaded. Do not submit until
the requirements in `app-store-readiness.md` are resolved and the text matches
the final signed build.

## Product fields

| Field | Draft |
| --- | --- |
| App name | Hacker Pen |
| Subtitle | Hacker News for every screen |
| Primary category | News |
| Keywords | news,technology,programming,startups,reader,comments,summary,translation |
| Copyright | 2026 Suica; confirm the legal rights holder before submission |
| Support URL | Pending a public HTTPS page with a direct support contact |
| Privacy Policy URL | Pending publication of `assets/privacy_policy.txt` |
| Pricing and availability | Pending owner confirmation |
| Age rating | Pending questionnaire based on public content and embedded browsing |

Use the existing `dev.suica.hackerPen` bundle ID. iPad belongs to the iOS platform;
the native Mac build can be added as macOS under the same app record. The
developer-account registrations and existing App Store Connect record must be
checked before making any account changes.

## Description

Read Hacker News with Hacker Pen, an independent reader for iPhone, iPad, and Mac.

Browse public stories, follow comment threads, and explore user profiles. Read
linked articles inside the app and keep the discussion close by. On larger
windows, the reading workspace can show the story list, article, and comments
together. Collapse the story list or article inspector to focus on reading.
Comments and summary follow the selected article. iPhone keeps its familiar
floating controls and bottom sheets. Narrow iPad windows use the same reading
interface, with open panels adapting as the window is resized.

Optional AI tools summarize linked articles and translate comments into your
selected language. Connect your own OpenAI, Anthropic, or Google Gemini API key,
then choose an available model. Requests go directly to your chosen provider and
may incur charges under your provider account. Reading Hacker News does not
require an AI key or a Hacker Pen account.

Hacker Pen stores preferences on your device and saves API keys in the operating
system's secure storage. It does not operate an analytics service or a backend
for your reading activity or AI requests. Hacker News, article websites, and AI
providers process network requests under their own policies.

Hacker Pen is an independent application and is not affiliated with Y Combinator
or Hacker News.

## Promotional text

Follow Hacker News stories and discussions on iPhone, iPad, and Mac. Optional AI
summaries and translations use your chosen provider.

## What's New

- Adapt the reading workspace for iPad and Mac windows.
- Keep the story list, article, and comments available together when space allows.
- Collapse the story list and article inspector while preserving the article.
- Use denser story rows and contextual article controls in larger windows.
- Open Mac settings in a dedicated window with desktop controls.
- Align desktop pane toolbars and keep directly clickable news categories.
- Preserve the original phone controls and adapt iPad sheets when resizing.
- Improve keyboard and pointer access to existing reading and settings actions.
- Keep focused reading usable on narrow windows.

Use these notes only for an update. Omit the What's New field for an initial
release if App Store Connect does not request it.

## Review notes draft

The text below needs final device/build details, public URLs, and working AI
review credentials before use. It must not be used to claim that deferred AI
consent or content-control requirements have been completed.

```text
Hacker Pen is an independent, read-only client for public Hacker News content.
There is no Hacker Pen account, login, posting, messaging, or in-app purchase.
Reading stories, comments, and public user profiles does not require AI setup.

The iOS build supports iPhone and iPad. The macOS build is a native Flutter Mac
application with App Sandbox enabled. Its reading workspace adapts to available
window width and supports keyboard and pointer input. Independent multiwindow
state is not advertised.

Selecting a story opens Article. Its Comments/Summary inspector starts closed
and opens from the article header. From 1120 logical pixels upward, News,
Article, and the optional Inspector fit together. At 840–1119, opening Inspector
temporarily collapses News; dismissing it restores News if previously enabled.
Below 840, News leads to Article. iPad uses the original draggable bottom sheets;
Mac retains desktop controls with an attached inspector. iPad sheets automatically
become right-side inspectors when widened, retaining content and scroll positions.
Phones retain the original mobile interface in portrait and landscape.
Changing stories keeps an open inspector and follows the new article. Close
Article returns to News and closes Inspector. Sidebar choices last for the
current session; resizing keeps the reading context.

On Mac and iPad hardware keyboards, Command + B toggles News and Command +
Shift + B toggles the inspector. Command + R refreshes stories; Command + [ or
Escape dismisses the inspector before closing Article. On Mac, the app menu's
Settings… item and Command + comma open a separate settings window, keeping the
reading window intact. Other platforms retain their existing settings access.

Article browsing uses an embedded WebView. NSAllowsArbitraryLoadsInWebContent
is enabled because Hacker News links to independent third-party websites whose
transport policies we do not control. Native AI-provider and Hacker News API
connections use HTTPS; the exception is scoped to embedded web content.

AI summaries and translations are optional. To test them, open Settings >
Providers & keys > Add API key, choose the supplied review provider, and save the
dedicated review key supplied in App Review Information. Return to Active model,
choose that provider, and select a model. Open a story and use Summary, or open
comments and choose a translation action. Do not use a personal or production key.
Provider requests are billed to the supplied provider account. The review key
must remain active and funded throughout review and may be revoked afterward.

The app sends the selected article URL and extracted article text for summaries,
or the selected comment text for translations, directly to the chosen provider.
Keys are stored in the operating system's secure storage and can be removed in
Settings > Providers & keys. The privacy policy is available in Settings >
Privacy > Privacy Policy.

Before submission, replace this paragraph with the final signed-build validation
details, public support/privacy URLs, and the completed AI-consent and
content-reporting/blocking behavior. Those requirements are currently deferred;
this draft is not a submission-ready review note.
```

Provide the funded review key through App Store Connect's private review fields,
not this file, screenshots, source code, or public store metadata. If no funded
review setup is available, resolve it before submitting advertised AI features.

## Screenshot capture plan

Capture the final app in use, with API keys and private provider details hidden:

1. iPhone story list and focused article/comments views.
2. iPad portrait, landscape, and the available multi-pane reading workspace.
3. Mac reading workspace with News + Article + Inspector, collapsed sidebars,
   a narrower window, and the dedicated Settings window.
4. Optional summary or translation using a funded test account and public content.

Select the screenshot sizes required by the actual App Store Connect records at
submission time. Keep metadata accurate for the shipped layout. Do not add a
verified iPhone Duo claim, fictional device rendering, or multiwindow promise.

## Apple references

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
