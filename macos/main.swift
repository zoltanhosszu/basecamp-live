import AppKit

// Shows the number of people active in Basecamp right now in the menubar.
// Refreshes every minute; clicking opens basecamp.com/live in Safari.

let feedURL = URL(string: "https://dash.37signals.com/statistics/bc5/live_usage_total.json")!
let pageURL = URL(string: "https://basecamp.com/live")!
let refreshInterval: TimeInterval = 60

// basecamp.com favicon, embedded so the icon shows before the first fetch.
let faviconSVG = """
<svg fill="none" height="32" viewBox="0 0 32 32" width="32" xmlns="http://www.w3.org/2000/svg"><path clip-rule="evenodd" d="m16.0006 2.5625c8.1294 0 14.6082 9.7007 15.9185 18.5977.0723.4906.1084.7359.0561 1.2061-.0319.2871-.2209.9394-.3474 1.199-.2072.4253-.3204.5568-.5467.8198-3.1348 3.644-9.0038 5.0524-15.0805 5.0524-6.07705 0-11.94581-1.4084-15.081348-5.0521-.226436-.2632-.339662-.3948-.546916-.82-.12657-.2598-.315638-.9121-.3475767-1.1993-.0522964-.4703-.01614562-.7156.0561379-1.2063 1.3105428-8.8969 7.7899528-18.59729 15.9197028-18.5973zm4.1441 6.38654c-1.4062 0-5.3373 6.96536-7.1407 6.96536-1.8036 0-2.7412-3.17-4.95885-3.1577-2.19566.0126-4.45907 4.8985-5.5317 7.5666-.30084.7483-.45126 1.1224-.30372 1.82s.35385.8982.76647 1.2995c1.59035 1.5468 5.24127 3.7966 13.0242 3.7966 7.7947 0 11.4445-2.2566 13.0308-3.8036.4083-.3982.6125-.5974.7554-1.3068.1428-.7095-.0097-1.0699-.3147-1.7907-.6886-1.6272-1.9084-4.1626-3.5923-6.3361-1.9023-2.4549-4.3278-5.05314-5.7349-5.05316z" fill="#29353c" fill-rule="evenodd"/></svg>
"""

func menubarIcon() -> NSImage? {
  guard let image = NSImage(data: Data(faviconSVG.utf8)) else { return nil }
  image.size = NSSize(width: 16, height: 16)
  image.isTemplate = true
  return image
}

struct LiveTotal: Decodable {
  let total_active: Int
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem!
  private var timer: Timer?

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = "…"
    statusItem.button?.image = menubarIcon()
    statusItem.button?.imagePosition = .imageLeading
    statusItem.button?.toolTip = "People working in Basecamp now"
    statusItem.button?.target = self
    statusItem.button?.action = #selector(clicked)
    statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

    refresh()
    timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
      self?.refresh()
    }
    timer?.tolerance = 5

    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
  }

  @objc private func refresh() {
    var request = URLRequest(url: feedURL)
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.timeoutInterval = 20

    URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
      let total = data.flatMap { try? JSONDecoder().decode(LiveTotal.self, from: $0) }?.total_active
      DispatchQueue.main.async { self?.show(total) }
    }.resume()
  }

  private func show(_ total: Int?) {
    guard let button = statusItem.button else { return }

    if let total {
      button.title = abbreviate(total)
      button.toolTip = "\(total.formatted()) people working in Basecamp now"
    } else if button.title == "…" {
      button.title = "–"
    }
  }

  private func abbreviate(_ n: Int) -> String {
    switch n {
    case 1_000_000...: String(format: "%.1fM", Double(n) / 1_000_000)
    case 1_000...:     "\(Int((Double(n) / 1_000).rounded()))k"
    default:           "\(n)"
    }
  }

  @objc private func clicked() {
    if NSApp.currentEvent?.type == .rightMouseUp {
      let menu = NSMenu()
      menu.addItem(withTitle: "Refresh", action: #selector(refresh), keyEquivalent: "").target = self
      menu.addItem(.separator())
      menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
      statusItem.menu = menu
      statusItem.button?.performClick(nil)
      statusItem.menu = nil
      return
    }

    let safari = URL(fileURLWithPath: "/Applications/Safari.app")
    NSWorkspace.shared.open([pageURL], withApplicationAt: safari, configuration: NSWorkspace.OpenConfiguration())
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
