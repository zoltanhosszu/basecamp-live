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
