# Apple platform release readiness

Updated: October 5, 2026.

This release prepares the existing Hacker Pen features for iPad and the native
Flutter macOS app. It does not add posting, messaging, accounts, a paid AI
service, or independent multiwindow state. App Store submission is not complete
and must wait for the open requirements below.

## Validation limits

Run the development checks in `README.md` for the current revision. Flutter
widget tests use a fake native WebView and do not verify website interaction,
platform signing, or secure-storage behavior on physical devices.

Previous local checks produced an unsigned Mac Debug build, an ad hoc arm64 Mac
Release build, and an arm64 iPad simulator build. The local Mac trial omitted
the Keychain access group. These checks do not establish distribution readiness;
properly provisioned builds, signed Keychain testing, and interactive native
validation remain pending.

With the pinned Flutter 3.41.9 toolchain, the earlier Xcode 27 simulator build
encountered a multi-architecture framework verification failure. An explicit
arm64 destination with `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES` succeeded. No SDK patch
or source architecture override is included. See the recorded upstream context:
[Flutter issue #188461](https://github.com/flutter/flutter/issues/188461) and
[fix #188625](https://github.com/flutter/flutter/pull/188625).

## Prepared in the repository

- Preserve the existing iOS bundle ID, `dev.suica.hackerPen`, and developer team.
  The macOS target now uses the same identity and the display name Hacker Pen.
  Its automatic signing uses Apple Development instead of the template's ad hoc
  identity. Unsigned native checks may override `CODE_SIGNING_ALLOWED=NO`.
  Registration, distribution certificates, and provisioning must still be
  checked in the developer account before a signed archive is produced.
- Use the News category for the macOS bundle. Replace the macOS template icon
  with the existing custom iOS icon at every required Mac size.
- Keep macOS App Sandbox and outgoing-network access enabled. Apply the same
  web-content-only ATS exception already used on iOS, so embedded third-party
  article websites have consistent behavior. This is not a broad native-network
  ATS exemption; explain the arbitrary article-site requirement in review notes.
- Enable Keychain Sharing for the app targets. iOS Debug, Profile, and Release
  reference `Runner/Runner.entitlements`; macOS Debug/Profile and Release use
  their existing entitlement files. Their empty `keychain-access-groups` arrays
  follow the installed `flutter_secure_storage_darwin` instructions and use the
  signed app's default access group without introducing a custom App Group.
  Configuration alone does not establish that signed key storage works.
- Start the Mac window with 1200 × 800 points of content and a 360 × 480 minimum.
- Require macOS 12 or later for the app and native dependency targets. The
  installed Xcode 27 toolchain rejects deployment targets below macOS 12; the
  Podfile raises older plugin targets during installation without editing
  generated Pods projects.
- Prepare English store-copy and review-note drafts in `app-store-metadata.md`.
  No App Store Connect record or public website has been created or updated.

## Platform behavior to validate

News is the entry point. Selecting a story opens its linked article or self-post;
comments and summary open from that article's header in an optional inspector.
The inspector starts closed and never replaces its parent article. Closing the
article closes its inspector and returns to News. Both supporting sidebars can
collapse; the article has no separate visibility toggle.

Phones keep the original interface in portrait and landscape, including the
collapsible headers, hideable floating action dock, Comments/Summary bottom
sheets, and existing immersive-reading preference. Device routing uses the iOS
device idiom rather than inferring a phone or tablet from window dimensions.
An iPad keeps one workspace owner across resizing and uses the original phone
presentation below 840 logical pixels. Mac retains desktop controls at every
supported window width.

At 1120 logical pixels and above, News, Article, and Inspector can appear
together. At 840–1119, opening the inspector temporarily collapses News;
closing it restores News only if the user had it enabled. Below 840, navigation
is News → Article. Narrow iPad uses the original draggable bottom sheets; narrow
Mac uses an attached inspector over the mounted article. An open iPad sheet
automatically becomes a right-side inspector when widened and a sheet when
narrowed, preserving the selected story, mounted WebView, content, and panel
scroll positions.
Changing story keeps an open inspector and its Comments/Summary tab, following
the new article. Selecting another story does not automatically request AI.
Visibility is transient and is not stored between launches. Desktop panes share
one aligned toolbar row without a global Hacker Pen toolbar or a repeated
article title in the inspector. News retains its directly clickable category
strip below the toolbar. Larger windows retain denser rows and a selected-story
accent. Reading, profiles, summaries, translations, settings, and key management
must remain usable at every supported width.

Check hardware-keyboard shortcuts on Mac and iPad: Command + R refreshes the
story list, Command + comma opens settings, Command + B toggles News,
Command + Shift + B toggles the selected article's inspector. Command + [ or
unmodified Escape dismisses the inspector before closing the article. Other
platforms use Control in place of Command. On Mac, the application menu's
Settings… item and Command + comma open one dedicated settings window; repeat
activation fronts the existing window. Settings use desktop forms and dialogs,
leaving reading untouched. Check saved model/key/language changes in the reading
window and discard stale AI results without reloading the article or making
automatic AI requests. The status-bar extension preference remains on iOS.
Native View menu commands route these shortcuts while web content owns focus;
they are disabled while Settings is active. File → Close Window uses the native
responder chain and Command + W.

On iPad, test portrait, landscape, Split View, Stage Manager, and continuous
resizing without losing the selected story or breaking navigation. On Mac, test
the starting size, the minimum size, full screen, keyboard input, pointer input,
and trackpad scrolling. A stable multiwindow experience is not promised by this
release.

The requested iPhone Duo support is limited to adaptable sizes in this release.
Device-specific implementation and validation are deferred until after launch.
Do not advertise verified compatibility based solely on size tests.

The in-app privacy policy is bundled from `assets/privacy_policy.txt` and is available under Settings > Privacy > Privacy Policy without a network request. Publish this same text at a public HTTPS URL for the App Store Connect Privacy Policy field.

## Public privacy and support information: pending

- Confirm the developer's public support contact and replace the policy's App Store support-contact reference with a direct contact method.
- Publish the policy and verify its public URL without signing in. No public policy URL has been deployed by this change.
- Configure the Support URL and Privacy Policy URL in App Store Connect.
- Review the App Privacy answers against actual third-party processing and retention. On-device storage alone is not collection, but the developer's lack of a backend does not establish the practices of AI providers or embedded websites.
- The policy describes existing behavior. The user has deferred the explicit AI
  consent flow. It remains an open submission requirement: disclose the selected
  provider and data being sent, obtain explicit permission before sharing
  personal data with third-party AI, and provide a way to withdraw permission.
  Saving an API key or displaying the policy is not a claim that this flow exists.

## Hacker News content controls: deferred

Hacker Pen is a read-only client for public Hacker News data. It does not offer posting, messaging, or an app account. Its comment loader excludes items marked `deleted` or `dead` by Hacker News.

Do not claim that the app already provides reporting or author blocking. Those features are absent. The story-list and profile paths also need a consistent review of upstream deletion and moderation flags. Apple Guideline 1.2 does not state a blanket exception for third-party read-only clients.

The user has deferred reporting and local author blocking from this adaptation.
Before submission, provide a working public contact, decide how users report
objectionable content with a timely response process, and address author blocking.
These features do not inherently require a custom social-network backend.
Reliance on upstream moderation alone remains an unresolved review risk, not a
guarantee of compliance.

## Signed builds and device validation: pending

The initial Mac build could not find a development provisioning profile for
`dev.suica.hackerPen`. Account provisioning has not been performed. A subsequent
Debug build succeeded with `CODE_SIGNING_ALLOWED=NO`; it does not establish
signed Keychain behavior, verified runtime usability, or distribution readiness.
The current toolbar/mobile revision also produced an arm64 local Release trial that passed
deep/strict ad hoc signature verification and launched on the current Mac.
Temporary signing entitlements omitted the Keychain access group. A local trial
does not replace a correctly provisioned signed build, native interaction
verification, or signed Keychain testing.

- Test signed builds on a physical iPhone, a physical iPad, and Mac. Cover
  offline use, failed article pages, missing or invalid AI keys, exhausted
  provider quotas, and returning while requests are pending.
- On each signed platform, save a temporary provider key, read it after relaunch,
  replace it, remove it, and verify removal after relaunch. Use a dedicated test
  credential; never include an API key in source, screenshots, logs, or this doc.
  Validate entitlement expansion and provisioning against the signed archive.
- Check the archive's privacy report. The installed secure-storage, preferences,
  and WebView plugins already include privacy manifests; verify that their
  manifests are bundled and that the final report matches actual app behavior.
- Give App Review working access to advertised AI functionality. Supply a
  funded, revocable review credential securely in App Store Connect for at least
  one tested provider, with setup instructions and billing disclosure. Do not
  ask reviewers to obtain or fund their own key. This credential is still pending.
- Capture screenshots from the final running app on the relevant iPhone, iPad,
  and Mac sizes. Complete the age-rating questionnaire for public Hacker News
  content and embedded browsing; do not assume a low rating from the app's icon.
- Confirm copyright owner, distribution territories, pricing, App Privacy
  answers, and export-compliance answers before replacing draft metadata. Keep
  the current bundle ID and avoid enabling encryption exemptions without review.
- Produce and validate signed distribution archives after the missing account,
  metadata, and consent/content-control requirements have been resolved. Local
  tests, simulator builds, and unsigned builds do not complete this step.

## Apple references

- https://developer.apple.com/app-store/review/guidelines/#user-generated-content
- https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage
- https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/help/glossary/universal-purchase/
- https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox
- https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowsarbitraryloadsinwebcontent
