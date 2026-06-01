---
title: Faultman — Fault Management & Correlation Engine
description: Alarm pipeline, 3 correlation engines, visual rule editor, carrier-grade state management
theme: default
colorSchema: dark
highlighter: shiki
lineNumbers: false
fonts:
  sans: Inter
  mono: JetBrains Mono
transition: fade
mdc: true
---

<div class="flex flex-col justify-center items-start h-full pl-2">
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-4">Macellan · Design Onboarding</div>
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">Faultman</h1>
  <div class="text-2xl text-slate-300 mb-8">Fault Management & Correlation Engine</div>
  <div class="flex gap-6 text-sm text-slate-400">
    <span>8-stage pipeline</span>
    <span>·</span>
    <span>3 correlation engines</span>
    <span>·</span>
    <span>Visual rule editor</span>
    <span>·</span>
    <span>Carrier-grade state</span>
  </div>
</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">2026</div>

---
layout: default
---

# Agenda

<div class="grid grid-cols-2 gap-x-12 gap-y-3 mt-6 text-sm">
<div>

**The Problem**
Why raw alarms are not enough

**Compass Ecosystem**
Where Faultman fits

**Alarm Pipeline**
8 sequential stages, temporal runs async

**Enrichment & Deduplication**
Context from Compass, fingerprint-based dedup

**Topology RCA**
In-memory graph, root cause detection

**Temporal Correlation**
Storm detection, sequences, absence

</div>
<div>

**Suppression & Flapping**
Maintenance windows, cycle detection

**Three Engines**
Static · Topology · Temporal

**Alarm Model**
Sentinel base + Faultman enrichment

**State Management**
What lives where and why

**Rule Engine UI**
React Flow canvas, node types, actions

**Tech Stack**
Java · Kafka · Redis · TimescaleDB · React

</div>
</div>

---
layout: default
---

# The Problem

<div class="grid grid-cols-2 gap-12 mt-4">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">Raw alarm stream</div>
<v-clicks>

- A single fiber cut produces **dozens of alarms** across multiple NEs and layers
- NOC sees noise — hundreds of alarms, none labeled as root cause
- NE identifiers with no site, region, customer, or service context
- No way to know: is this 50 alarms or 1 problem with 50 symptoms?
- Suppression, maintenance windows, flapping — all handled manually or not at all
- Correlation rules hard-coded by developers, no operator control

</v-clicks>
</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">Faultman</div>
<v-clicks>

- Correlates alarm bursts into **root cause + symptom** trees
- Enriches every alarm with site, region, customer, and SLA context
- Deduplicates repeated alarms — one active fault entry, not N copies
- Temporal patterns: storm detection, sequence correlation, absence detection
- Suppression and flapping detection — configurable, not hard-coded
- **Visual rule editor**: NOC engineers build and modify rules without code

</v-clicks>
</div>
</div>

---
layout: default
---

# Design Principles

<div class="grid grid-cols-2 gap-6 mt-6">

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">01 · Signal over noise</div>
  <div class="text-sm text-slate-300">Processed alarms represent faults, not events. Every downstream consumer sees correlated, enriched, deduplicated data — never the raw stream.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">02 · Operator-owned rules</div>
  <div class="text-sm text-slate-300">NOC engineers define correlation logic through a visual canvas. Adding a new rule does not require a developer or a deployment.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">03 · Pipeline doesn't wait</div>
  <div class="text-sm text-slate-300">Temporal correlation runs async. The main pipeline never blocks — low latency is preserved regardless of time-window rule complexity.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">04 · State is explicit</div>
  <div class="text-sm text-slate-300">Every stateful component has a defined primary store, backup, and recovery path. No implicit shared state, no hidden dependencies.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4 col-span-2">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">05 · One DSL, three engines</div>
  <div class="text-sm text-slate-300">A single rule definition language covers static field matching, topology-based RCA, and temporal patterns. The compiler routes each rule to the correct engine. Users never choose an engine explicitly.</div>
</div>

</div>

---
layout: default
---

# Position in the Compass Ecosystem

<div class="font-mono text-xs mt-6 text-slate-300 leading-relaxed">

```
Network Elements (NEs)
  └─ NBIs (CORBA · SSE · Nokia Kafka · SNMP)
       └─ Sentinel ──────────── normalize, filter, route
            └─ Kafka consumer topic
                 └─ Faultman ── correlate, enrich, rule, act
                      ├─ Redis           active alarm state
                      ├─ TimescaleDB     alarm history
                      └─ Kafka output ─► NocMon · external systems
```

</div>

<div class="grid grid-cols-3 gap-4 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">SENTINEL</div>
  <div class="text-slate-300">Upstream project</div>
  <div class="text-slate-500 text-xs mt-1">Connects to all NBIs, normalizes alarms into a common model, delivers to Faultman via Kafka. Faultman is a Sentinel consumer.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">COMPASS GRAPHQL</div>
  <div class="text-slate-300">Enrichment source</div>
  <div class="text-slate-500 text-xs mt-1">Single GraphQL API over all NMS adapters. Faultman queries it for site, region, customer, SLA, and service data.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">ORIENTDB</div>
  <div class="text-slate-300">Graph database</div>
  <div class="text-slate-500 text-xs mt-1">NE parent-child topology and enrichment data. Faultman loads the network graph from here for RCA correlation.</div>
</div>

</div>

<v-click>
<div class="mt-4 text-xs text-slate-500">Faultman does not connect to NBIs directly. All alarm ingestion goes through Sentinel.</div>
</v-click>

---
layout: default
---

# Alarm Pipeline — Overview

Every alarm passes through 8 sequential stages per Kafka partition.

<div class="mt-4 grid grid-cols-1 gap-2 text-sm">

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S1</span>
  <span class="text-white w-52 shrink-0">Kafka intake</span>
  <span class="text-slate-400 text-xs">Consume from Sentinel topic · partition key = NE mgmt IP · manual offset commit after pipeline completes</span>
</div>

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S2</span>
  <span class="text-white w-52 shrink-0">Enrichment</span>
  <span class="text-slate-400 text-xs">Add site, region, customer, SLA, service impact · Compass GraphQL + OrientDB · cached locally</span>
</div>

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S3</span>
  <span class="text-white w-52 shrink-0">Deduplication</span>
  <span class="text-slate-400 text-xs">Fingerprint-based · repeat = increment count · clear event = remove · timeout expiry configurable per alarm type</span>
</div>

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S4</span>
  <span class="text-white w-52 shrink-0">Static rule evaluation</span>
  <span class="text-slate-400 text-xs">DSL-compiled field-matching rules · priority order · adaptive evaluation · hot-reload via atomic swap</span>
</div>

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S5</span>
  <span class="text-white w-52 shrink-0">Topology RCA</span>
  <span class="text-slate-400 text-xs">In-memory NE graph · walk upstream for active parent alarms · mark root cause or symptom</span>
</div>

<div v-click class="flex gap-4 items-center border border-blue-900 rounded px-4 py-2 bg-blue-950/20">
  <span class="font-mono text-blue-400 w-6 shrink-0">S6</span>
  <span class="text-white w-52 shrink-0">Temporal correlation</span>
  <span class="text-slate-400 text-xs">Async side path · Kafka Streams (windowed counts) + custom state machine (sequences, absence) · injects synthetic alarms</span>
  <span class="font-mono text-blue-600 text-xs ml-auto shrink-0">async</span>
</div>

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S7</span>
  <span class="text-white w-52 shrink-0">Suppression / flapping</span>
  <span class="text-slate-400 text-xs">Maintenance window check · flapping detection via circular buffer · suppressed alarms stop here</span>
</div>

<div v-click class="flex gap-4 items-center border border-slate-800 rounded px-4 py-2">
  <span class="font-mono text-orange-400 w-6 shrink-0">S8</span>
  <span class="text-white w-52 shrink-0">Output dispatch</span>
  <span class="text-slate-400 text-xs">3 parallel writes: Kafka processed-alarms topic · Redis active alarm table · TimescaleDB history · offset commit after all 3 succeed</span>
</div>

</div>

<v-click>
<div class="mt-3 text-xs text-slate-500">S6 temporal runs on a side path and never blocks the main pipeline.</div>
</v-click>

---
layout: two-cols
---

# S2 — Enrichment

<div class="text-sm mt-4 pr-6">

Sentinel delivers a normalized alarm with NE identity and alarm classification. Faultman adds **network and business context**.

<v-clicks>

**What gets added:**
- `site` — physical site of the NE
- `region` — geographic region
- `customer` — affected customer IDs
- `slaLevel` — priority classification
- `serviceImpact` — affected service list

**Where it comes from:**
- Compass GraphQL API for site, region, customer, service data
- OrientDB for topology-linked context

</v-clicks>

<v-click>

**Cache strategy:**

Local cache per enrichment type, refreshed every ~5 minutes from Compass + OrientDB. Cache miss triggers a live lookup. Most alarms are served from memory.

</v-click>

</div>

::right::

<div class="text-xs font-mono mt-8 text-slate-400 leading-relaxed">

```json
// Sentinel delivers:
{
  "neName": "GL34_Y9345_SANCAKTEPE",
  "severity": "major",
  "alarmName": "EthernetPortLocalFault",
  "domain": "Ran"
}

// After S2 enrichment:
{
  "neName": "GL34_Y9345_SANCAKTEPE",
  "severity": "major",
  "alarmName": "EthernetPortLocalFault",
  "domain": "Ran",

  "site":          "Sancaktepe",
  "region":        "Istanbul",
  "customer":      ["TT-Mobility"],
  "slaLevel":      "P1",
  "serviceImpact": ["4G-Data", "VoLTE"]
}
```

</div>

---
layout: default
---

# S3 — Deduplication

<div class="grid grid-cols-2 gap-12 mt-4">
<div>

<div class="text-sm">

**Fingerprint**

<v-click>

```
hash(sourceNbi + alarmName + neName + affectedObject)
```

Same physical fault always produces the same fingerprint, regardless of how many times the NBI sends it.

</v-click>

<v-clicks>

**On repeat alarm:**
- Existing entry — increment `dedupCount`, update `lastOccurrence`
- No new active alarm created

**On clear event** (explicit `eventType: cleared` from Sentinel):
- Remove fingerprint from dedup state
- Mark alarm as cleared in active alarm table

**On timeout** (no clear received):
- Configurable per alarm type — e.g., heartbeat alarms auto-expire after 10 minutes
- Prevents stale alarms accumulating when a source doesn't send explicit clears

</v-clicks>

</div>

</div>
<div>

<div class="text-sm">

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">State</div>

<v-click>

`ConcurrentHashMap<fingerprint, DedupState>`

Stored in JVM heap. Synced to Redis every 10 seconds as backup. On restart: warm up from Redis (5–10s), then continue from Kafka if Redis is unavailable.

</v-click>

<v-click>

<div class="mt-6 border border-slate-700 rounded p-3 text-xs text-slate-400">
  <span class="text-orange-400 font-mono text-xs">CLEAR SEMANTICS</span><br><br>
  Clear = explicit Sentinel event <span class="text-slate-500">OR</span> configurable timeout.<br><br>
  Sources that don't send explicit clears (e.g., SNMP) rely on timeout expiry. Timeout is set per alarm type in config.
</div>

</v-click>

</div>

</div>
</div>

---
layout: default
---

# S5 — Topology RCA

<div class="grid grid-cols-2 gap-10 mt-4">
<div>

<div class="text-sm font-semibold text-white mb-2">The graph</div>

<div class="text-sm text-slate-300 mb-4">
In-memory directed graph loaded from OrientDB. Nodes = network elements, edges = physical and logical connections between them.
</div>

<v-clicks>

**RCA algorithm — 5 steps:**

1. Find the alarming NE in the graph
2. Walk upstream → get parent NEs (1–N hops)
3. Check Redis active alarm table: do any parents have active alarms?
4. **If yes** → this alarm is a **symptom**; link to parent's alarm as root cause
5. **If no** → this alarm is a **candidate root cause**; downstream symptoms will link to it

</v-clicks>

<v-click>

Cross-partition lookup (parent NE on a different Kafka partition) goes through the Redis active alarm table — sub-millisecond.

</v-click>

</div>
<div>

<div class="text-sm font-semibold text-white mb-3">Common RCA patterns</div>

<div class="grid grid-cols-1 gap-3 text-xs">

<div v-click class="border-l-2 border-orange-500 pl-3">
  <div class="text-white font-semibold mb-1">Upstream propagation</div>
  <div class="text-slate-400">Parent NE alarm → child NEs emit LOS/LOF. Root cause: parent. Children: symptoms.</div>
</div>

<div v-click class="border-l-2 border-blue-500 pl-3">
  <div class="text-white font-semibold mb-1">Link failure bilateral</div>
  <div class="text-slate-400">Fiber cut → both ends of a link alarm simultaneously. Root cause: the link.</div>
</div>

<div v-click class="border-l-2 border-green-500 pl-3">
  <div class="text-white font-semibold mb-1">Ring protection switchover</div>
  <div class="text-slate-400">Ring link fail → burst of alarms. Graph detects ring topology → consolidates burst into one event.</div>
</div>

<div v-click class="border-l-2 border-purple-500 pl-3">
  <div class="text-white font-semibold mb-1">Multi-layer cascade</div>
  <div class="text-slate-400">L1 optical → L2 Ethernet → L3 IP alarm chain. Cross-layer edges enable multi-hop traversal.</div>
</div>

</div>

</div>
</div>

---
layout: default
---

# S6 — Temporal Correlation

<div class="text-sm text-slate-400 mt-2 mb-4">Runs async. Main pipeline never waits. When a pattern fires, a synthetic alarm is injected back into the pipeline.</div>

<div class="grid grid-cols-3 gap-4 mt-2">

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Count / Window</div>
  <div class="text-xs text-slate-400 mb-3">Kafka Streams windowed aggregation</div>
  <div class="font-mono text-xs text-slate-300 bg-slate-900 rounded p-3">
    when count(alarm<br>
    &nbsp;&nbsp;[neName == $NE])<br>
    &nbsp;&nbsp;&gt; 50 within 60s<br>
    then create_synthetic(<br>
    &nbsp;&nbsp;"ALARM_STORM", $NE)
  </div>
  <div class="text-xs text-slate-500 mt-2">Use for: storm detection, threshold crossing over time</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-blue-400 font-mono text-xs uppercase tracking-wide mb-2">Sequence</div>
  <div class="text-xs text-slate-400 mb-3">Custom state machine</div>
  <div class="font-mono text-xs text-slate-300 bg-slate-900 rounded p-3">
    when alarm_A[cause=="LOS"]<br>
    followed_by alarm_B[<br>
    &nbsp;&nbsp;neName==alarm_A.neName<br>
    &nbsp;&nbsp;AND cause=="LOF"]<br>
    within 30s<br>
    then correlate(A, B)
  </div>
  <div class="text-xs text-slate-500 mt-2">Use for: causal chains between alarm types on same NE</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-green-400 font-mono text-xs uppercase tracking-wide mb-2">Absence</div>
  <div class="text-xs text-slate-400 mb-3">Custom state machine</div>
  <div class="font-mono text-xs text-slate-300 bg-slate-900 rounded p-3">
    when not alarm[<br>
    &nbsp;&nbsp;type=="HEARTBEAT"<br>
    &nbsp;&nbsp;AND neName==$NE]<br>
    within 300s<br>
    then create_synthetic(<br>
    &nbsp;&nbsp;"NE_UNREACHABLE", $NE)
  </div>
  <div class="text-xs text-slate-500 mt-2">Use for: heartbeat monitoring, NE unreachable detection</div>
</div>

</div>

<v-click>
<div class="mt-4 border border-slate-700 rounded px-4 py-2 text-xs text-slate-400">
  <span class="text-orange-400 font-mono">DSL ROUTING</span> — The compiler inspects the rule syntax and routes it automatically: <code>count()</code> / <code>sum()</code> → Kafka Streams · <code>followed_by</code> / <code>not...within</code> → state machine. One DSL, correct engine every time.
</div>
</v-click>

---
layout: default
---

# S7 — Suppression & Flapping

<div class="grid grid-cols-2 gap-12 mt-6">
<div>

<div class="text-sm font-semibold text-white mb-3">Maintenance Windows</div>

<v-clicks>

- Defined per NE or NE group
- Cron-based schedule
- Alarms matching the NE during the window are suppressed — `suppressReason: maintenance`
- Window definition managed via rule engine UI
- Suppressed alarms do not reach downstream consumers

</v-clicks>

</div>
<div>

<div class="text-sm font-semibold text-white mb-3">Flapping Detection</div>

<v-clicks>

- Circular buffer of raise/clear timestamps per alarm key
- If raise/clear cycle rate exceeds a configurable threshold within a time window → alarm is flagged as flapping
- Flapping alarms suppressed — `suppressReason: flapping`
- State: `ConcurrentHashMap<alarmKey, CircularBuffer<timestamp>>`
- Backed to Redis; worst case: detection starts a few cycles late after restart

</v-clicks>

</div>
</div>

<v-click>
<div class="mt-8 border border-slate-700 rounded p-3 text-sm text-slate-400">
  <span class="text-orange-400 font-mono text-xs">NOTE</span> — Suppressed alarms are still written to TimescaleDB history. They just don't appear in the active alarm table or the downstream Kafka topic. Suppression is a delivery decision, not a data loss decision.
</div>
</v-click>

---
layout: default
---

# Three Correlation Engines

<div class="text-sm text-slate-400 mt-2 mb-6">All three share one DSL and one rule management UI. The compiler routes rules to the correct engine automatically.</div>

<div class="grid grid-cols-1 gap-4">

<div v-click class="border border-purple-800 rounded-lg p-4">
  <div class="flex items-center gap-4 mb-2">
    <div class="text-purple-400 font-mono text-xs uppercase tracking-wide">Static Rule Evaluator</div>
    <div class="text-xs text-slate-500 font-mono">≈ 63% of rules</div>
  </div>
  <div class="text-sm text-slate-300 mb-2">Field-matching: severity overrides, alarm renaming, tagging, category classification, enrichment rules.</div>
  <div class="text-xs text-slate-500">Adaptive evaluation: sequential (&lt; 200 rules) → decision tree (200–1000) → multi-field index (&gt; 1000). Hot-reload via atomic swap — zero processing gap.</div>
</div>

<div v-click class="border border-orange-800 rounded-lg p-4">
  <div class="flex items-center gap-4 mb-2">
    <div class="text-orange-400 font-mono text-xs uppercase tracking-wide">Topology Correlation Engine</div>
    <div class="text-xs text-slate-500 font-mono">≈ 25% of rules</div>
  </div>
  <div class="text-sm text-slate-300 mb-2">RCA on the in-memory NE graph. Parent-child upstream propagation, bilateral link failure, ring protection, multi-layer cascades.</div>
  <div class="text-xs text-slate-500">Graph updated via Kafka topology-change events (incremental) + periodic full resync from OrientDB (every 30 min). Graph size: 5K–50K NEs, 10K–200K edges ≈ 50–500MB heap.</div>
</div>

<div v-click class="border border-amber-800 rounded-lg p-4">
  <div class="flex items-center gap-4 mb-2">
    <div class="text-amber-400 font-mono text-xs uppercase tracking-wide">Temporal Correlation Engine</div>
    <div class="text-xs text-slate-500 font-mono">≈ 12% of rules</div>
  </div>
  <div class="text-sm text-slate-300 mb-2">Time-window patterns: storm detection (Kafka Streams), alarm sequences and absence detection (custom state machine).</div>
  <div class="text-xs text-slate-500">Async — main pipeline never waits. Synthetic alarms re-enter pipeline at S1 when patterns fire.</div>
</div>

</div>

---
layout: two-cols
---

# Alarm Model

<div class="text-sm mt-4 pr-6">

Faultman starts with Sentinel's common alarm model and adds two layers:

<v-clicks>

**Enrichment fields** — added at S2:
- `site`, `region` — resolved from NE identity
- `customer` — list of affected customer IDs
- `slaLevel` — P1 / P2 / P3 / P4
- `serviceImpact` — list of affected services

**Correlation fields** — added at S5/S6:
- `correlationId` — groups related alarms
- `rootCauseId` — points to root cause alarm (if symptom)
- `isRootCause` — true if this alarm caused others
- `symptoms` — IDs of symptom alarms

**Processing fields** — added throughout:
- `dedupCount` — how many times this alarm repeated
- `tags` — applied by static rules
- `suppressed`, `suppressReason` — maintenance | flapping | rule

</v-clicks>

</div>

::right::

<div class="text-[11px] font-mono mt-4 text-slate-400 leading-relaxed overflow-auto max-h-100">

```json
{
  // Sentinel base
  "id":             "sentinel-uuid",
  "sourceNbi":      "huawei-mae-ist",
  "sourceType":     "corba",
  "receivedAt":     "2026-04-01T14:22:10Z",
  "eventType":      "raised",
  "domain":         "Transport",
  "severity":       "critical",
  "alarmName":      "EthernetPortLocalFault",
  "alarmType":      "communicationsAlarm",
  "neName":         "965-IXR2125085-ATAKOY",
  "affectedObject": "port-1/1/1",
  "serviceAffecting": true,
  "raw":            { },

  // Enrichment (S2)
  "site":           "Ataköy",
  "region":         "Istanbul",
  "customer":       ["TT-Kurumsal"],
  "slaLevel":       "P1",
  "serviceImpact":  ["MPLS-VPN-TT-01"],

  // Correlation (S5)
  "isRootCause":    true,
  "correlationId":  "corr-abc123",
  "symptoms":       ["sentinel-uuid-2",
                     "sentinel-uuid-3"],

  // Processing
  "dedupCount":     1,
  "tags":           ["transport-critical"],
  "suppressed":     false
}
```

</div>

---
layout: default
---

# State Management

<div class="mt-4 grid grid-cols-1 gap-2 text-sm">

<div v-click class="flex gap-4 items-start border border-slate-800 rounded px-4 py-3">
  <div class="w-44 shrink-0">
    <div class="text-white font-semibold">Dedup state</div>
    <div class="font-mono text-xs text-slate-500 mt-1">~50MB heap</div>
  </div>
  <div class="text-slate-400 text-xs flex-1">JVM heap (primary) + Redis backup (sync every 10s). On restart: Redis warm-up in 5–10s. Total Redis loss → Kafka replay.</div>
</div>

<div v-click class="flex gap-4 items-start border border-slate-800 rounded px-4 py-3">
  <div class="w-44 shrink-0">
    <div class="text-white font-semibold">Active alarm table</div>
    <div class="font-mono text-xs text-slate-500 mt-1">~200MB Redis</div>
  </div>
  <div class="text-slate-400 text-xs flex-1">Redis cluster is the primary store (not a cache). Redis Hash per alarm + Sorted Set by severity + Set per NE. Topology RCA queries this: "does parent NE have active alarms?" = Redis SMEMBERS.</div>
</div>

<div v-click class="flex gap-4 items-start border border-slate-800 rounded px-4 py-3">
  <div class="w-44 shrink-0">
    <div class="text-white font-semibold">Topology graph</div>
    <div class="font-mono text-xs text-slate-500 mt-1">~300MB heap</div>
  </div>
  <div class="text-slate-400 text-xs flex-1">JVM heap only. Read-heavy, write-rare (topology changes infrequently). Updated via Kafka topology-changes events + full resync every 30min from OrientDB. ReadWriteLock: concurrent reads, exclusive writes.</div>
</div>

<div v-click class="flex gap-4 items-start border border-slate-800 rounded px-4 py-3">
  <div class="w-44 shrink-0">
    <div class="text-white font-semibold">Temporal windows</div>
    <div class="font-mono text-xs text-slate-500 mt-1">~150MB total</div>
  </div>
  <div class="text-slate-400 text-xs flex-1">Kafka Streams: RocksDB on disk + Kafka changelog for recovery. State machine: JVM heap (windows are short — 30–300s — heap loss is tolerable, state refills quickly).</div>
</div>

<div v-click class="flex gap-4 items-start border border-slate-800 rounded px-4 py-3">
  <div class="w-44 shrink-0">
    <div class="text-white font-semibold">Flapping state</div>
    <div class="font-mono text-xs text-slate-500 mt-1">~10MB heap</div>
  </div>
  <div class="text-slate-400 text-xs flex-1">JVM heap + Redis backup. Circular buffer of timestamps per alarm key. Worst case on restart: detection starts a few raise/clear cycles late.</div>
</div>

<div v-click class="flex gap-4 items-start border border-slate-800 rounded px-4 py-3">
  <div class="w-44 shrink-0">
    <div class="text-white font-semibold">Alarm history</div>
    <div class="font-mono text-xs text-slate-500 mt-1">TimescaleDB</div>
  </div>
  <div class="text-slate-400 text-xs flex-1">PostgreSQL + TimescaleDB extension. All processed alarms written at S8 (batched: every 100 alarms or 1s). Time-series queries for trending, SLA analysis, and correlation history.</div>
</div>

</div>

---
layout: default
---

# Rule Engine UI — The Canvas

<div class="text-sm text-slate-400 mt-2 mb-4">Visual, low-code. Target users: NOC engineers and operations leads. Built with React + React Flow + TypeScript.</div>

<div class="grid grid-cols-2 gap-10 mt-2">
<div>

<div class="font-mono text-xs bg-slate-900 rounded-lg p-4 text-slate-300 leading-relaxed">

```
┌──────────────────────────────────────────┐
│                                          │
│  [Alarm Trigger]──[AND]──[Followed By]   │
│   severity=critical  │    LOF within 30s │
│   domain=Transport   │         │         │
│                      │    [Tag: rca-los] │
│                  [OR]──[Count > 50/60s]  │
│                            │             │
│                       [Suppress]         │
│                                          │
└──────────────────────────────────────────┘
   canvas reads left-to-right: when → then
```

</div>

<v-click>
<div class="mt-4 text-xs text-slate-500">
Rules serialize to graph JSON on the backend and compile to the correct engine. An operator building a "followed by" node doesn't need to know what a state machine is.
</div>
</v-click>

</div>
<div>

<div class="text-sm font-semibold text-white mb-3">Node types</div>

<div class="grid grid-cols-1 gap-2 text-xs">

<div v-click class="border-l-2 border-orange-500 pl-3">
  <span class="text-white">Alarm Trigger</span>
  <span class="text-slate-500 ml-2">inline condition builder: field + operator + value, nested AND/OR</span>
</div>

<div v-click class="border-l-2 border-slate-500 pl-3">
  <span class="text-white">AND / OR / NOT</span>
  <span class="text-slate-500 ml-2">logic combinator — connects multiple condition branches</span>
</div>

<div v-click class="border-l-2 border-blue-500 pl-3">
  <span class="text-white">Followed By [alarm] within [T]</span>
  <span class="text-slate-500 ml-2">sequence pattern with time window input</span>
</div>

<div v-click class="border-l-2 border-amber-500 pl-3">
  <span class="text-white">Count &gt; N within T</span>
  <span class="text-slate-500 ml-2">windowed count with inline threshold + window inputs</span>
</div>

<div v-click class="border-l-2 border-green-500 pl-3">
  <span class="text-white">Not seen within T</span>
  <span class="text-slate-500 ml-2">absence detection with configurable window</span>
</div>

<div v-click class="border-l-2 border-purple-500 pl-3">
  <span class="text-white">Topology: parent has alarm</span>
  <span class="text-slate-500 ml-2">topology-aware condition node</span>
</div>

<div v-click class="border-l-2 border-teal-500 pl-3">
  <span class="text-white">Action nodes</span>
  <span class="text-slate-500 ml-2">tag · suppress · set severity · create synthetic · call webhook · write to DB · call Compass</span>
</div>

</div>

</div>
</div>

---
layout: default
---

# Rule Engine — Actions

What the right side of a rule can do:

<div class="grid grid-cols-3 gap-4 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Alarm mutations</div>
  <div class="text-slate-400 text-xs">
    <div class="mb-1">· Tag with a label</div>
    <div class="mb-1">· Override severity</div>
    <div class="mb-1">· Rename alarm</div>
    <div>· Suppress (with reason)</div>
  </div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-blue-400 font-mono text-xs uppercase tracking-wide mb-2">Synthetic alarms</div>
  <div class="text-slate-400 text-xs">
    <div class="mb-1">· Create a new synthetic alarm</div>
    <div class="mb-1">· Set any model field</div>
    <div>· Re-enters pipeline at S1</div>
  </div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-green-400 font-mono text-xs uppercase tracking-wide mb-2">Webhooks</div>
  <div class="text-slate-400 text-xs">
    <div class="mb-1">· HTTP POST to configured URL</div>
    <div class="mb-1">· Alarm context in payload</div>
    <div>· Retry + timeout configurable</div>
  </div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-purple-400 font-mono text-xs uppercase tracking-wide mb-2">Database write</div>
  <div class="text-slate-400 text-xs">
    <div class="mb-1">· Write alarm fields to a configured DB table</div>
    <div>· DB connector defined in system config</div>
  </div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-amber-400 font-mono text-xs uppercase tracking-wide mb-2">Compass GraphQL</div>
  <div class="text-slate-400 text-xs">
    <div class="mb-1">· Call Compass API from within a rule</div>
    <div class="mb-1">· Map response fields back to alarm</div>
    <div>· Used for dynamic enrichment mid-rule</div>
  </div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-teal-400 font-mono text-xs uppercase tracking-wide mb-2">File write</div>
  <div class="text-slate-400 text-xs">
    <div class="mb-1">· Append alarm data to a file</div>
    <div>· Path configured per rule</div>
  </div>
</div>

</div>

<v-click>
<div class="mt-4 text-xs text-slate-500">Rule hot-reload: saving a rule in the UI triggers an atomic swap of the compiled rule set. No restart, no processing gap, no in-flight alarm is dropped.</div>
</v-click>

---
layout: default
---

# Scalability Model

<div class="grid grid-cols-2 gap-10 mt-4">
<div>

<div class="text-sm font-semibold text-white mb-3">Partitioning strategy</div>

<v-clicks>

Partition key = **NE mgmt IP**. All alarms from the same NE land on the same partition. This means per-NE dedup and flapping state is always local — no cross-partition coordination for the common case.

Each processor instance handles a set of Kafka partitions. Scale out = add more instances + increase partitions.

**Starting point**: 16 partitions · 4 processor instances.

</v-clicks>

</div>
<div>

<div class="text-sm font-semibold text-white mb-3">Cross-partition topology RCA</div>

<v-click>

The challenge: a child NE and its parent NE may be on different Kafka partitions. Topology RCA needs to know if the parent has an active alarm — but that state lives on a different partition.

</v-click>

<v-click>

**Solution: Redis active alarm table as shared state.**

The lookup `SMEMBERS active:ne:{parentIp}` goes to Redis — sub-millisecond. Local correlation is free; cross-partition correlation pays a single Redis round trip.

This eliminates the need for repartitioning by topology groups (which causes hotspots) or a two-phase cross-correlator (which is overkill at this scale).

</v-click>

</div>
</div>

<v-click>
<div class="mt-6 bg-green-950/30 border border-green-800 rounded-lg px-4 py-3 text-sm text-green-300">
  Scale path: if topology grows beyond 100K NEs and Redis becomes the bottleneck, move to a two-phase correlation model where a dedicated cross-correlator consumer group handles parent-child lookups independently.
</div>
</v-click>

---
layout: default
---

# Tech Stack

<div class="grid grid-cols-3 gap-4 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">BACKEND</div>
  <div class="text-slate-300">Java · Spring Boot</div>
  <div class="text-slate-500 text-xs mt-1">Consistent with Sentinel and broader Macellan stack. All pipeline, rule engine backend, and API services.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">STREAM PROCESSING</div>
  <div class="text-slate-300">Apache Kafka · Kafka Streams</div>
  <div class="text-slate-500 text-xs mt-1">Alarm ingestion from Sentinel, temporal windowed aggregation (S6), topology change events, output to NocMon.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">ACTIVE STATE</div>
  <div class="text-slate-300">Redis cluster</div>
  <div class="text-slate-500 text-xs mt-1">Primary store for active alarm table. Also backup for dedup, flapping, and topology state.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">HISTORY</div>
  <div class="text-slate-300">TimescaleDB</div>
  <div class="text-slate-500 text-xs mt-1">PostgreSQL + TimescaleDB extension. All processed alarms. Time-series queries for trending and SLA analysis.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">RULE ENGINE UI</div>
  <div class="text-slate-300">React · React Flow · TypeScript</div>
  <div class="text-slate-500 text-xs mt-1">Visual canvas with domain-specific custom nodes. Tailwind dark theme. WebSocket for live alarm feed.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">DEPLOY</div>
  <div class="text-slate-300">Docker Compose · Ansible</div>
  <div class="text-slate-500 text-xs mt-1">All services containerized. Single <code>ansible-playbook site.yml</code> to stand up or update the full environment.</div>
</div>

</div>

---
layout: default
---

# Open Questions

Things to resolve before or during implementation:

<div class="grid grid-cols-1 gap-3 mt-6 text-sm">

<div v-click class="flex gap-4 border border-amber-900 rounded px-4 py-3">
  <span class="text-amber-400 font-mono text-xs w-6 shrink-0 mt-0.5">01</span>
  <div>
    <span class="text-white font-semibold">Topology source</span>
    <span class="text-slate-400 ml-2 text-xs">— Where exactly do NE parent-child relationships live? OrientDB directly, or does Compass expose them via GraphQL?</span>
    <div class="text-xs text-slate-600 mt-1">Blocks: RCA engine data loading, S5 graph sync design</div>
  </div>
</div>

<div v-click class="flex gap-4 border border-amber-900 rounded px-4 py-3">
  <span class="text-amber-400 font-mono text-xs w-6 shrink-0 mt-0.5">02</span>
  <div>
    <span class="text-white font-semibold">Compass GraphQL scope</span>
    <span class="text-slate-400 ml-2 text-xs">— What entities and queries does it expose? What's available for site, customer, SLA, and service enrichment?</span>
    <div class="text-xs text-slate-600 mt-1">Blocks: S2 enrichment field design, cache strategy</div>
  </div>
</div>

<div v-click class="flex gap-4 border border-amber-900 rounded px-4 py-3">
  <span class="text-amber-400 font-mono text-xs w-6 shrink-0 mt-0.5">03</span>
  <div>
    <span class="text-white font-semibold">NocMon integration model</span>
    <span class="text-slate-400 ml-2 text-xs">— Does NocMon consume from the Kafka processed-alarms topic, or does it pull via a REST/WebSocket API from Faultman?</span>
    <div class="text-xs text-slate-600 mt-1">Blocks: S8 output design, API surface</div>
  </div>
</div>

<div v-click class="flex gap-4 border border-amber-900 rounded px-4 py-3">
  <span class="text-amber-400 font-mono text-xs w-6 shrink-0 mt-0.5">04</span>
  <div>
    <span class="text-white font-semibold">Alarm volume</span>
    <span class="text-slate-400 ml-2 text-xs">— What are the expected alarms/sec from Sentinel under normal and storm conditions?</span>
    <div class="text-xs text-slate-600 mt-1">Blocks: Kafka partition count, Redis sizing, TimescaleDB batch tuning</div>
  </div>
</div>

<div v-click class="flex gap-4 border border-amber-900 rounded px-4 py-3">
  <span class="text-amber-400 font-mono text-xs w-6 shrink-0 mt-0.5">05</span>
  <div>
    <span class="text-white font-semibold">Alarm-change events</span>
    <span class="text-slate-400 ml-2 text-xs">— Should Faultman process Nokia NSP severity escalations (eventType: changed), or handle raise/clear only?</span>
    <div class="text-xs text-slate-600 mt-1">Blocks: S3 dedup logic, active alarm table update model</div>
  </div>
</div>

</div>

---
layout: center
class: text-center
---

<div class="flex flex-col items-center justify-center h-full">
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-6">Macellan · Compass FM</div>
  <h1 class="text-5xl font-bold text-white mb-4">Let's build it.</h1>
  <div class="text-slate-400 text-lg mb-10 max-w-lg">
    Carrier-grade correlation with a rule editor operators can actually use.
  </div>
  <div class="grid grid-cols-4 gap-8 text-center mt-4">
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">8</div>
      pipeline stages
    </div>
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">3</div>
      correlation engines
    </div>
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">1</div>
      visual rule canvas
    </div>
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">1</div>
      DSL for all engines
    </div>
  </div>
</div>
