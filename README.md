# Basecamp Live

Tiny bar widgets that show how many people are working in
[Basecamp](https://basecamp.com/live) right now, like "127k": one for the
macOS menubar, one for the [Omarchy](https://omarchy.org) bar.

Both read the same feed the live page uses:
`https://dash.37signals.com/statistics/bc5/live_usage_total.json`.

## macOS

A menubar item in [`macos/`](macos): the Basecamp logo and the count.

- Refreshes every minute, and after the Mac wakes from sleep
- Hover for the exact number
- Click to open [basecamp.com/live](https://basecamp.com/live) in Safari
- Right-click for Refresh and Quit

### Build

Requires macOS 14+ and the Xcode command line tools (`xcode-select --install`).

```sh
./macos/build.sh            # builds macos/BasecampLive.app
./macos/build.sh --install  # also copies it to ~/Applications and launches it
```

To start it at login, add `~/Applications/BasecampLive.app` under
System Settings → General → Login Items.

It's a single Swift file (`macos/main.swift`) with no Xcode project and no
dependencies.

## Omarchy

A bar widget in [`omarchy/`](omarchy): the Basecamp logo and a number like
"170k".

- Refreshes every minute, and soon after the machine wakes from sleep
- Hover for the exact number
- Left-click to open [basecamp.com/live](https://basecamp.com/live) in your browser
- Right- or middle-click to refresh
- The count dims if it hasn't updated in a few minutes

### Install

```sh
curl -fsSL https://raw.githubusercontent.com/zoltanhosszu/basecamp-live/main/omarchy/install.sh | bash
```

Or from a checkout, run `./omarchy/install.sh`. Run it again to update, or with
`--uninstall` to remove the widget. It installs to
`~/.config/omarchy/plugins/zoltanhosszu.basecamp-live` and adds the widget to
the right of the bar.

Move it with `omarchy bar move zoltanhosszu.basecamp-live --section <section>`,
or drag it along the bar.

To refresh less often, set `refreshIntervalSec` (30–3600, default 60) on its
entry in `~/.config/omarchy/shell.json`:

```json
{ "id": "zoltanhosszu.basecamp-live", "refreshIntervalSec": 120 }
```

Scripts can refresh it with `omarchy-shell zoltanhosszu.basecamp-live refresh`.

It's a QML widget (`omarchy/BasecampLive.qml`) with its logic in
`omarchy/Model.js`. Run `omarchy/tests/run` to test that logic with node.
