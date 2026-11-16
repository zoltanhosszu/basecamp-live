import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// How many people are working in Basecamp right now, like basecamp.com/live.
//   left   = open basecamp.com/live
//   right / middle = refresh now
BarWidget {
  id: root
  moduleName: "zoltanhosszu.basecamp-live"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property int intervalSec: Model.intervalSec(setting("refreshIntervalSec", 60))

  property int total: -1
  property bool failed: false
  property double lastSuccessMs: 0
  property double nextDueMs: 0
  property double nowMs: Date.now()

  readonly property bool hasTotal: total >= 0
  readonly property bool stale: hasTotal && Model.isStale(nowMs, lastSuccessMs, intervalSec)

  readonly property string shortLabel: {
    if (!hasTotal) return failed ? "–" : "…"
    var parts = Model.abbreviate(total)
    return Commons.I18n.formatNumber(parts.value, parts.decimals) + parts.suffix
  }

  readonly property string tooltip: {
    if (!hasTotal) return failed ? strings.t("tooltip.unreachable") : strings.t("tooltip.loading")
    var locale = Qt.locale(Commons.I18n.formatLocale)
    var text = strings.tn("tooltip.count", total).arg(locale.toString(total, "f", 0))
    if (stale) {
      var when = locale.toString(new Date(lastSuccessMs), locale.timeFormat(Locale.ShortFormat))
      text += "\n" + strings.t("tooltip.stale").arg(when)
    }
    return text
  }

  function refresh() {
    if (fetchProc.running) return
    fetchProc.running = true
  }

  function finish(raw) {
    var parsed = Model.parseTotal(raw)
    var now = Date.now()
    if (parsed !== null) {
      root.total = parsed
      root.failed = false
      root.lastSuccessMs = now
    } else {
      root.failed = true
    }
    root.nowMs = now
    root.nextDueMs = Model.nextDueMs(now, parsed !== null, root.intervalSec)
  }

  function openLivePage() {
    Quickshell.execDetached(["omarchy-launch-browser", Model.pageUrl])
  }

  onIntervalSecChanged: nextDueMs = 0

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  ShellIpc {
    target: "zoltanhosszu.basecamp-live"

    function refresh(): void {
      root.broadcast("refresh")
    }
  }

  Process {
    id: fetchProc
    command: [
      "curl", "-fsS", "--proto", "=https",
      "--max-time", "10",
      "--max-filesize", String(Model.maxResponseBytes),
      Model.feedUrl
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finish(text)
    }
  }

  // A short wall-clock tick decides when a fetch is due, so one runs soon
  // after the machine wakes rather than a full interval later.
  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      root.nowMs = Date.now()
      if (Model.isDue(root.nowMs, root.nextDueMs, root.intervalSec)) root.refresh()
    }
  }

  // WidgetButton supplies the tooltip, press feedback and clicks; the icon and
  // count are laid out here so the logo comes first (BarIconButton puts its
  // label before the icon).
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fontSize: Style.font.body
    dimmed: root.stale || (!root.hasTotal && root.failed)
    tooltipText: root.tooltip
    fixedWidth: root.vertical ? -1 : Math.ceil(content.width + (Style.bar.iconSlot - Style.bar.iconCanvas))
    fixedHeight: root.vertical ? Style.bar.statusSlot : -1
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.openLivePage()
      else root.refresh()
    }

    Item {
      id: content
      readonly property real gap: Style.space(4)
      x: (button.width - width) / 2
      y: (button.height - height) / 2
      width: Style.bar.iconCanvas + (count.visible ? gap + count.implicitWidth : 0)
      height: Style.bar.iconCanvas
      scale: button.pressScale

      BasecampIcon {
        x: (Style.bar.iconCanvas - width) / 2
        y: (parent.height - height) / 2
        iconSize: Style.bar.iconSize
        color: button.foreground
      }

      Text {
        id: count
        visible: !root.vertical
        x: Style.bar.iconCanvas + content.gap
        // Center the figures, not the line box, so they sit level with the icon.
        y: (parent.height - height) / 2
          + (countMetrics.descent - countMetrics.ascent + countMetrics.tightBoundingRect("0").height) / 2
        textFormat: Text.PlainText
        text: root.shortLabel
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        renderType: Text.NativeRendering
      }

      FontMetrics {
        id: countMetrics
        font: count.font
      }
    }
  }
}
