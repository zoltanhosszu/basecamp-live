// Pure helpers for the Basecamp Live widget. Loaded by QML (`import "Model.js"
// as Model`) and by the node tests through the module.exports guard at the end.

// The same feed basecamp.com/live reads. It answers {"total_active": 168870}.
var feedUrl = "https://dash.37signals.com/statistics/bc5/live_usage_total.json"
var pageUrl = "https://basecamp.com/live"

var maxResponseBytes = 4096
var maxTotal = 10000000000

var defaultIntervalSec = 60
var minIntervalSec = 30
var maxIntervalSec = 3600

// After a failed fetch (often the network still coming up after a wake),
// try again sooner than the usual interval.
var retryIntervalSec = 15

// A count older than this many intervals is shown dimmed.
var staleIntervals = 3

// The active total from a feed response, or null when it isn't a sane count.
function parseTotal(raw) {
  var text = String(raw === undefined || raw === null ? "" : raw)
  if (text.length === 0 || text.length > maxResponseBytes) return null
  var parsed
  try {
    parsed = JSON.parse(text)
  } catch (e) {
    return null
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return null
  var total = parsed.total_active
  if (typeof total !== "number" || !isFinite(total) || Math.floor(total) !== total) return null
  if (total < 0 || total > maxTotal) return null
  return total
}

// The short form for the bar: 127 → 127, 127456 → 127k, 1234567 → 1.2M.
// Returned in parts so QML can write the number with the language's digits
// and decimal separator; the unit letter stays as it is.
function abbreviate(n) {
  if (n >= 1000) {
    var thousands = Math.round(n / 1000)
    if (thousands < 1000) return { value: thousands, decimals: 0, suffix: "k" }
    var millions = Math.round(n / 100000) / 10
    if (millions < 1000) return { value: millions, decimals: 1, suffix: "M" }
    return { value: Math.round(n / 100000000) / 10, decimals: 1, suffix: "B" }
  }
  return { value: n, decimals: 0, suffix: "" }
}

function intervalSec(value) {
  var n = Number(value)
  if (!isFinite(n)) return defaultIntervalSec
  return Math.min(maxIntervalSec, Math.max(minIntervalSec, Math.round(n)))
}

// When the next fetch is due, given how the last one went.
function nextDueMs(nowMs, succeeded, intervalSeconds) {
  var wait = succeeded ? intervalSeconds : Math.min(intervalSeconds, retryIntervalSec)
  return nowMs + wait * 1000
}

// Due once the wall clock passes nextDue. Checked on a short tick against the
// wall clock rather than one long monotonic timer, so a fetch happens right
// after the machine wakes instead of up to a whole interval later. A clock
// that jumped backwards also makes it due.
function isDue(nowMs, nextDue, intervalSeconds) {
  if (!nextDue) return true
  if (nowMs >= nextDue) return true
  return nextDue - nowMs > intervalSeconds * 1000
}

function isStale(nowMs, lastSuccessMs, intervalSeconds) {
  if (!lastSuccessMs) return false
  return nowMs - lastSuccessMs > staleIntervals * intervalSeconds * 1000
}

if (typeof module !== "undefined") {
  module.exports = {
    feedUrl: feedUrl,
    pageUrl: pageUrl,
    maxResponseBytes: maxResponseBytes,
    retryIntervalSec: retryIntervalSec,
    parseTotal: parseTotal,
    abbreviate: abbreviate,
    intervalSec: intervalSec,
    nextDueMs: nextDueMs,
    isDue: isDue,
    isStale: isStale
  }
}
