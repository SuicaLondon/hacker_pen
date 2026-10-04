import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate, NSMenuItemValidation {
  private let settingsChannelName = "dev.suica.hackerPen/settings"
  private var mainSettingsChannel: FlutterMethodChannel?
  private var settingsChannel: FlutterMethodChannel?
  private var settingsEngine: FlutterEngine?
  private var settingsWindow: NSWindow?

  func configureSettingsChannel(for controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: settingsChannelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    mainSettingsChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "openSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard self?.presentSettingsWindow() == true else {
        result(FlutterError(
          code: "settings_unavailable",
          message: "Could not open Settings.",
          details: nil
        ))
        return
      }
      result(nil)
    }
  }

  @IBAction func showSettings(_ sender: Any?) {
    if !presentSettingsWindow() {
      NSSound.beep()
    }
  }

  @IBAction func toggleNewsSidebar(_ sender: Any?) {
    sendWorkspaceAction("toggleNews")
  }

  @IBAction func toggleInspector(_ sender: Any?) {
    sendWorkspaceAction("toggleInspector")
  }

  @IBAction func refreshNews(_ sender: Any?) {
    sendWorkspaceAction("refreshNews")
  }

  @IBAction func goBack(_ sender: Any?) {
    sendWorkspaceAction("back")
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    switch menuItem.action {
    case #selector(toggleNewsSidebar(_:)), #selector(toggleInspector(_:)),
      #selector(refreshNews(_:)), #selector(goBack(_:)):
      return mainFlutterWindow?.isKeyWindow == true
    default:
      return true
    }
  }

  private func sendWorkspaceAction(_ action: String) {
    guard mainFlutterWindow?.isKeyWindow == true else { return }
    mainSettingsChannel?.invokeMethod("workspaceAction", arguments: action)
  }

  private func presentSettingsWindow() -> Bool {
    if let window = settingsWindow {
      window.deminiaturize(nil)
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return true
    }

    let engine = FlutterEngine(
      name: "hacker_pen.settings",
      project: nil,
      allowHeadlessExecution: true
    )
    let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    RegisterGeneratedPlugins(registry: engine)
    let channel = FlutterMethodChannel(
      name: settingsChannelName,
      binaryMessenger: engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "settingsChanged",
        let kind = call.arguments as? String,
        kind == "ai" || kind == "reading"
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.mainSettingsChannel?.invokeMethod("settingsChanged", arguments: kind)
      result(nil)
    }

    // Run the named entrypoint before attaching a view that can appear.
    guard engine.run(withEntrypoint: "settingsMain") else {
      engine.shutDownEngine()
      return false
    }
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Settings"
    window.contentViewController = controller
    window.contentMinSize = NSSize(width: 640, height: 480)
    window.isReleasedWhenClosed = false
    window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
    window.standardWindowButton(.zoomButton)?.isEnabled = false
    window.collectionBehavior.insert(.fullScreenNone)
    window.tabbingMode = .disallowed
    window.center()

    settingsEngine = engine
    settingsChannel = channel
    settingsWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    return true
  }

  deinit {
    settingsEngine?.shutDownEngine()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
