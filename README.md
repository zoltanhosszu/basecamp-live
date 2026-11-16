# Basecamp Live

A tiny macOS menubar widget that shows how many people are working in
[Basecamp](https://basecamp.com/live) right now, like "127k".

- Refreshes every minute, and after the Mac wakes from sleep
- Hover for the exact number
- Click to open [basecamp.com/live](https://basecamp.com/live) in Safari
- Right-click for Refresh and Quit

The count comes from the same feed the live page uses:
`https://dash.37signals.com/statistics/bc5/live_usage_total.json`.

## Build

Requires macOS 14+ and the Xcode command line tools (`xcode-select --install`).

```sh
./build.sh            # builds BasecampLive.app here
./build.sh --install  # also copies it to ~/Applications and launches it
```

To start it at login, add `~/Applications/BasecampLive.app` under
System Settings → General → Login Items.

It's a single Swift file (`main.swift`) with no Xcode project and no dependencies.

## Omarchy

There's also a bar widget for [Omarchy](https://omarchy.org) in
[`omarchy/`](omarchy), showing the same count from the same feed: the Basecamp
logo and a number like "170k".

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

It's a QML widget (`BasecampLive.qml`) with its logic in `Model.js`. Run
`omarchy/tests/run` to test that logic with node.
