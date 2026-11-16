// node tests/model.test.js — plain assert, no dependencies.
const assert = require("assert")
const Model = require("../Model.js")

const tests = {
  "parses the feed's total"() {
    assert.strictEqual(Model.parseTotal('{"total_active":168870}'), 168870)
    assert.strictEqual(Model.parseTotal('{"total_active":0}'), 0)
  },

  "rejects anything that isn't a sane count"() {
    for (const raw of [
      "", null, undefined, "not json", "[]", "null", "42",
      '{"total_active":"168870"}', '{"total_active":-1}', '{"total_active":1.5}',
      '{"total_active":1e20}', '{"other":1}',
      '{"total_active":"<img src=\\"https://example.invalid/t\\">"}',
      '<img src="https://example.invalid/tracker">',
      '{"total_active":1,"pad":"' + "x".repeat(Model.maxResponseBytes) + '"}'
    ]) assert.strictEqual(Model.parseTotal(raw), null, String(raw).slice(0, 60))
  },

  "abbreviates like the menubar app"() {
    const short = n => { const p = Model.abbreviate(n); return p.value.toFixed(p.decimals) + p.suffix }
    assert.strictEqual(short(0), "0")
    assert.strictEqual(short(999), "999")
    assert.strictEqual(short(1000), "1k")
    assert.strictEqual(short(127456), "127k")
    assert.strictEqual(short(168870), "169k")
    assert.strictEqual(short(999499), "999k")
    assert.strictEqual(short(999500), "1.0M")
    assert.strictEqual(short(1234567), "1.2M")
    assert.strictEqual(short(2500000000), "2.5B")
  },

  "clamps the refresh interval"() {
    assert.strictEqual(Model.intervalSec(undefined), 60)
    assert.strictEqual(Model.intervalSec("nope"), 60)
    assert.strictEqual(Model.intervalSec(5), 30)
    assert.strictEqual(Model.intervalSec(90), 90)
    assert.strictEqual(Model.intervalSec(99999), 3600)
  },

  "schedules the next fetch, sooner after a failure"() {
    assert.strictEqual(Model.nextDueMs(1000, true, 60), 61000)
    assert.strictEqual(Model.nextDueMs(1000, false, 60), 1000 + Model.retryIntervalSec * 1000)
    assert.strictEqual(Model.nextDueMs(1000, false, 10), 11000)
  },

  "is due at start, when the time passes, after a wake, or when the clock goes back"() {
    assert.ok(Model.isDue(5000, 0, 60))
    assert.ok(!Model.isDue(5000, 30000, 60))
    assert.ok(Model.isDue(30000, 30000, 60))
    assert.ok(Model.isDue(30000 + 8 * 3600 * 1000, 30000, 60))
    assert.ok(Model.isDue(1000, 1000 + 120 * 1000, 60))
  },

  "goes stale after a few missed intervals"() {
    assert.ok(!Model.isStale(1000, 0, 60))
    assert.ok(!Model.isStale(180000, 1000, 60))
    assert.ok(Model.isStale(182000, 1000, 60))
  }
}

let failed = 0
for (const [name, fn] of Object.entries(tests)) {
  try { fn(); console.log("ok   " + name) }
  catch (e) { failed++; console.log("FAIL " + name + "\n     " + e.message) }
}
if (failed) { console.log(failed + " failed"); process.exit(1) }
