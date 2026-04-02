---
title: Sentinel — Alarm Routing Service
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
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">Sentinel</h1>
  <div class="text-2xl text-slate-300 mb-8">Alarm Routing Service</div>
  <div class="flex gap-6 text-sm text-slate-400">
    <span>4 NBI interfaces</span>
    <span>·</span>
    <span>N consumers</span>
    <span>·</span>
    <span>RBAC</span>
    <span>·</span>
    <span>Full E2E test coverage</span>
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
Why we're building this

**Architecture**
Services and how they fit together

**Probe Layer**
One probe per interface type

**NBI Interfaces**
CORBA · Nokia Kafka · SSE · SNMP

**Common Alarm Model**
Normalized schema from real data

</div>
<div>

**Data Flow**
Live and on-demand sync

**Filtering**
Two-layer approach

**Auth & RBAC**
Permissions and effective subscriptions

**Testing Strategy**
Full E2E with mocked NBIs and consumers

</div>
</div>

---
layout: default
---

# The Problem

<div class="grid grid-cols-2 gap-12 mt-4">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">Today</div>
<v-clicks>

- 8+ separate Java processes, one per NBI instance
- Each process is hand-configured with hardcoded logic
- No common alarm model — each probe invents its own
- No consumer concept — data goes wherever it's wired
- No filtering — full alarm firehose flows everywhere
- No auth — any system that knows the Kafka topic gets everything
- No E2E tests — "works if prod is running"

</v-clicks>
</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">Sentinel</div>
<v-clicks>

- 4 probe services, one per **interface type**
- Each manages all NBI instances of its protocol
- Single normalized alarm model across all sources
- Consumer subscriptions with fine-grained filtering
- Two-layer filtering — reduce at source, refine per consumer
- RBAC — consumers only see what they're permitted to see
- Full E2E test suite with mocked NBIs and consumers

</v-clicks>
</div>
</div>

---
layout: default
---

# Design Principles

<div class="grid grid-cols-2 gap-6 mt-6">

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">01 · Pass-through</div>
  <div class="text-sm text-slate-300">Sentinel holds no alarm state. It normalizes, filters, and forwards. Nothing is stored.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">02 · Pull what you need</div>
  <div class="text-sm text-slate-300">Only fetch alarms from a source if at least one consumer cares. No blind ingestion.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">03 · Two-layer filtering</div>
  <div class="text-sm text-slate-300">Reduce at the source (aggregate demand), then filter per-consumer before delivery.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">04 · Source-agnostic normalization</div>
  <div class="text-sm text-slate-300">All protocols feed into a single common alarm model. Consumers don't know which NBI an alarm came from unless they want to.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4 col-span-2">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">05 · Authorized access</div>
  <div class="text-sm text-slate-300">Every consumer is authenticated. Subscriptions are constrained by RBAC permissions. No consumer can receive alarms outside their permitted scope.</div>
</div>

</div>

---
layout: default
---

# Architecture

<div class="font-mono text-xs mt-4 text-slate-300 leading-relaxed">

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Alarm Sources (NBIs)                          │
│          CORBA            SSE          Kafka          SNMP          │
└────────────┬──────────────┬────────────┬──────────────┬────────────┘
             │              │            │              │
┌────────────▼──────────────▼────────────▼──────────────▼────────────┐
│                          Probe Layer                                │
│          corba-probe   sse-probe   kafka-probe   snmp-probe         │
│             1 service per interface · manages all NBI instances     │
└──────────────────────────────┬─────────────────────────────────────┘
                               │  normalized alarms
┌──────────────────────────────▼─────────────────────────────────────┐
│                         Internal Kafka                              │
│              pre-filtered by aggregate consumer subscriptions       │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────────┐
│                        Consumer Router                              │
│                     per-consumer filtering                          │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────────┐
│          Consumer Kafka  (live topic + sync topic per consumer)  │
└──────────────────────────────────────────────────────────────────┘
```

<div class="mt-3 text-xs border border-slate-700 rounded px-3 py-2 text-slate-400">
  <span class="text-orange-400 font-mono">Auth Service</span> — identity · RBAC · permission queries · consulted by Subscription Manager, Consumer Router, and Sync Handler
</div>

</div>

---
layout: default
---

# Services at a Glance

<div class="grid grid-cols-3 gap-4 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-2">PROBES (×4)</div>
  <div class="text-slate-300">corba · sse · kafka · snmp</div>
  <div class="text-slate-500 text-xs mt-1">Connect to NBIs, normalize to common model, produce to internal Kafka</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-2">SUBSCRIPTION MANAGER</div>
  <div class="text-slate-300">Consumer subscription registry</div>
  <div class="text-slate-500 text-xs mt-1">Computes aggregate filter for probes + per-consumer filter for router</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-2">CONSUMER ROUTER</div>
  <div class="text-slate-300">Live alarm delivery</div>
  <div class="text-slate-500 text-xs mt-1">Reads internal Kafka, applies per-consumer filter, produces to consumer topics</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-2">SYNC HANDLER</div>
  <div class="text-slate-300">On-demand alarm dumps</div>
  <div class="text-slate-500 text-xs mt-1">Triggers probe sync, routes through same pipeline to consumer sync topic</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-2">AUTH SERVICE</div>
  <div class="text-slate-300">Identity + RBAC</div>
  <div class="text-slate-500 text-xs mt-1">Consumer credentials, roles, permission queries — all auth lives here</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-2">DASHBOARD</div>
  <div class="text-slate-300">Operations UI</div>
  <div class="text-slate-500 text-xs mt-1">Real-time topology, probe health, consumer lag, alarm live feed</div>
</div>

</div>

---
layout: default
---

# Probe Layer

<div class="mt-4 text-sm">

One service per interface type. Each service manages **all** NBI instances of its protocol. Adding a new NBI = config change, not a new deployment.

</div>

<div class="grid grid-cols-2 gap-6 mt-6">

<div v-click class="border-l-2 border-orange-500 pl-4">
  <div class="font-semibold text-white">corba-probe</div>
  <div class="text-xs text-slate-400 mt-1">8 NMS instances (Huawei MAE RAN ×6, DataCore, TX)</div>
  <div class="text-xs text-slate-500 mt-2">NMS pushes <code>NT_ALARM</code> events to the probe's ORB listener · Sync: pull full dump from NMS</div>
</div>

<div v-click class="border-l-2 border-blue-500 pl-4">
  <div class="font-semibold text-white">kafka-probe</div>
  <div class="text-xs text-slate-400 mt-1">2 Nokia NSP instances (Transport, TX/core)</div>
  <div class="text-xs text-slate-500 mt-2">SSL/TLS Kafka consumer from Nokia NSP · Sync: REST HTTPS to NSP snapshot endpoint</div>
</div>

<div v-click class="border-l-2 border-green-500 pl-4">
  <div class="font-semibold text-white">sse-probe</div>
  <div class="text-xs text-slate-400 mt-1">Huawei MAE RTN (primary + backup)</div>
  <div class="text-xs text-slate-500 mt-2">Long-lived HTTP SSE stream · Sync: HTTP query with limit param on same server</div>
</div>

<div v-click class="border-l-2 border-slate-500 pl-4">
  <div class="font-semibold text-white">snmp-probe</div>
  <div class="text-xs text-slate-400 mt-1">Source TBD</div>
  <div class="text-xs text-slate-500 mt-2">Passive trap receiver · <span class="text-yellow-500">No sync support</span> — SNMP has no dump mechanism</div>
</div>

</div>

---
layout: two-cols
---

# Interface: CORBA

<div class="text-sm mt-4 pr-6">

**Protocol**: CORBA IIOP, TMF MTNM standard

**Live — push model**

<v-clicks>

1. Probe connects to NMS as CORBA client
2. Probe registers its own ORB endpoint with the NMS
3. NMS pushes `NT_ALARM` events to that endpoint
4. Probe also receives `NT_HEARTBEAT` — used to detect connection loss

</v-clicks>

<v-click>

**Sync — pull model**

Probe calls NMS to request full active alarm dump. NMS returns all current alarms. Used for consumer state initialization.

</v-click>

<v-click>

**NMS instances**: 8 total across Huawei MAE (RAN regions), DataCore, and TX/transport

</v-click>

</div>

::right::

<div class="text-xs font-mono mt-6 text-slate-400 leading-relaxed">

```
NMS (10.122.210.7:31100)
  │
  │  1. probe registers ORB endpoint
  │◄────────────────────────
  │
  │  2. NMS pushes NT_ALARM events
  ├──────────────────────────►
  │     event_type: NT_ALARM
  │     objectName: EMS;Huawei/...
  │     nativeProbableCause: MUT_LOS
  │     perceivedSeverity: PS_MAJOR
  │     additionalInfo: ...
  │
  │  3. probe normalizes → Kafka
```

<div class="mt-4 text-slate-500">
Each instance needs:<br>
· master + slave NMS host/port<br>
· IOR string (CORBA endpoint ID)<br>
· orb.host:port (probe's own listener)
</div>

</div>

---
layout: two-cols
---

# Interface: Nokia Kafka

<div class="text-sm mt-4 pr-6">

**Protocol**: Kafka over SSL/TLS, Nokia NSP format

**Live**

<v-clicks>

- Standard Kafka consumer connecting to Nokia NSP Kafka
- Nokia NSP emits **three event types** — all must be handled:
  - `alarm-create` → `eventType: raised`
  - `alarm-delete` → `eventType: cleared`
  - `alarm-change` → `eventType: changed` (delta — only changed fields)

</v-clicks>

<v-click>

**Sync**

REST HTTPS call to Nokia NSP snapshot endpoint. Returns full active alarm set.

</v-click>

<v-click>

**Two NSP instances**:
- Transport: `10.122.238.141:9192`
- TX/core: `10.180.12.41:9193`

Both use mutual TLS (truststore + keystore).

</v-click>

</div>

::right::

<div class="text-[11px] font-mono mt-6 text-slate-400 leading-relaxed">

```json
// alarm-create
{ "nsp-fault:alarm-create": {
    "objectId": "fdn:model:fm:Alarm:160297073",
    "alarmName": "EthernetPortLocalFault",
    "severity": "major",
    "neName": "965-IXR2125085-ATAKOY_TT-POC3",
    "firstTimeDetected": 1774484111883
} }

// alarm-delete (objectId only — no context)
{ "nsp-fault:alarm-delete": {
    "objectId": "fdn:model:fm:Alarm:160296904"
} }

// alarm-change (delta — changed fields only)
{ "nsp-fault:alarm-change": {
    "objectId": "fdn:model:fm:Alarm:160297073",
    "severity": { "old-value": "warning",
                  "new-value": "major" }
} }
```

</div>

---
layout: two-cols
---

# Interface: SSE

<div class="text-sm mt-4 pr-6">

**Protocol**: HTTP SSE (Server-Sent Events), Huawei MAE RESTCONF

**Live**

<v-clicks>

1. Probe authenticates → gets session token
2. POST to subscription endpoint → gets SSE stream URL
3. Connect to SSE stream → server pushes alarm events continuously
4. Primary + backup server for failover

</v-clicks>

<v-click>

**Sync**

HTTP query to same server with `limit` parameter. Optional flag to include cleared alarms.

Endpoint: `/restconf/streams/sse/v1/identifier/{uuid}`

</v-click>

<v-click>

**Source**: Huawei MAE RTN
`10.122.253.248:26335` (primary)
`10.122.253.216:26335` (backup)

</v-click>

</div>

::right::

<div class="text-xs font-mono mt-6 text-slate-400 leading-relaxed">

```
1. POST /restconf/operations/authenticate
   → session token

2. POST /restconf/operations/subscribe
   → { "url": "/restconf/streams/sse/
              v1/identifier/{uuid}" }

3. GET /restconf/streams/sse/
       v1/identifier/{uuid}
   → Content-Type: text/event-stream

   data: { "alarm": { ... } }
   data: { "alarm": { ... } }
   ...

4. Sync query:
   GET /restconf/data/alarms?limit=5000
   → array of active alarms
```

<div class="mt-4 text-slate-500">
Auth: username/password per session<br>
User: <code>srvc.ngssalarm</code>
</div>

</div>

---
layout: default
---

# Interface: SNMP

<div class="grid grid-cols-2 gap-12 mt-6">
<div>

**Protocol**: SNMP trap receiver

**Live**

- Passive listener — network elements send traps to the probe
- No polling, no connection management
- Probe decodes trap PDUs → normalizes → Kafka

**Sync: Not supported**

SNMP has no mechanism to request a dump of active alarms. Consumers subscribing only to SNMP sources cannot do a state initialization sync.

</div>
<div class="flex items-center justify-center">

<div class="border border-yellow-600 rounded-lg p-6 text-center">
  <div class="text-yellow-400 text-4xl mb-3">⚠</div>
  <div class="text-yellow-300 font-semibold mb-2">No sync support</div>
  <div class="text-sm text-slate-400">Consumers that include SNMP in their subscription will not receive a terminal marker for SNMP alarms during sync. Handle gracefully.</div>
</div>

</div>
</div>

<div class="mt-6 text-xs text-slate-500">
Source details TBD — host and trap config need clarification before implementing snmp-probe.
</div>

---
layout: default
---

# Common Alarm Model

<div class="grid grid-cols-2 gap-8 mt-4">
<div class="overflow-auto max-h-96">

```json
{
  // Sentinel metadata
  "id":              "sentinel-uuid",
  "sourceNbi":       "huawei-mae-ist",
  "sourceType":      "corba",
  "receivedAt":      "2026-03-26T00:15:10Z",

  // Event
  "eventType":       "raised",
  "sourceAlarmId":   "1968323578",
  "domain":          "Ran",

  // Timing
  "firstOccurrence": "2026-03-26T00:14:54Z",
  "lastOccurrence":  "2026-03-26T00:14:54Z",
  "clearTime":       null,

  // Classification
  "severity":        "major",
  "alarmName":       "User Plane Fault",
  "alarmType":       "communicationsAlarm",
  "probableCause":   "LINK_FAILURE",

  // Resource
  "neName":          "GL34_Y9345_SANCAKTEPE_AQUA",
  "affectedObject":  "Service Type=X2",
  "serviceAffecting": false,

  "additionalText":  "...",
  "raw":             { /* original payload */ }
}
```

</div>
<div class="text-sm">

<v-clicks>

**One model for all sources**
CORBA, Nokia Kafka, SSE, and SNMP all normalize into this structure.

**`raw` field is always present**
Original payload preserved verbatim — no information loss, supports debugging and reprocessing.

**`eventType` distinguishes Nokia Kafka's three events**
`raised` · `cleared` · `changed`
CORBA and SSE only emit raised/cleared.

**`domain` is the primary routing dimension**
Ran · Transmission · Transport · DataCore

</v-clicks>

</div>
</div>

---
layout: default
---

# Severity Normalization & Event Types

<div class="grid grid-cols-2 gap-12 mt-4">
<div>

<div class="text-sm font-semibold text-white mt-1 mb-2">Severity mapping</div>

| Sentinel value | CORBA | Nokia Kafka |
|---|---|---|
| `critical` | `PS_CRITICAL` | `critical` |
| `major` | `PS_MAJOR` | `major` |
| `minor` | `PS_MINOR` | `minor` |
| `warning` | `PS_WARNING` | `warning` |
| `indeterminate` | `PS_INDETERMINATE` | `indeterminate` |
| `cleared` | `PS_CLEARED` | *(alarm-delete)* |

<div class="text-xs text-slate-500 mt-2">SSE severity mapping TBD — payload not yet captured</div>

</div>
<div>

<div class="text-sm font-semibold text-white mt-1 mb-2">Nokia alarm-delete has no context</div>

<v-click>

Nokia NSP only sends `objectId` on `alarm-delete`. No NE name, no alarm name.

```json
{ "nsp-fault:alarm-delete": {
    "objectId": "fdn:model:fm:Alarm:160296904"
} }
```

</v-click>
<v-click>

**Sentinel must enrich cleared events** to carry full context. Two options:

- **In-memory index**: store key fields on `alarm-create`, look up on `alarm-delete`
- **Accept sparse clears**: consumers correlate by `sourceAlarmId`

→ decision needed before implementing kafka-probe

</v-click>

</div>
</div>

---
layout: default
---

# Filterable Dimensions

What consumers can subscribe on — grounded in real alarm data from prod NBIs.

<div class="grid grid-cols-2 gap-x-12 gap-y-2 mt-6 text-sm">

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">domain</code>
  <span class="text-slate-400">Ran · Transmission · Transport · DataCore</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">severity</code>
  <span class="text-slate-400">critical · major · minor · warning · indeterminate</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">alarmName</code>
  <span class="text-slate-400">EthernetPortLocalFault · User Plane Fault · BfdSessionMissing · ...</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">alarmType</code>
  <span class="text-slate-400">communicationsAlarm · thresholdAlarm · equipmentAlarm (X.733)</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">neName</code>
  <span class="text-slate-400">NE name — prefix-coded: GL34_... · T-T... · TKD0801_... · 965-IXR...</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">sourceNbi</code>
  <span class="text-slate-400">Which NMS/NSP instance the alarm came from</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">serviceAffecting</code>
  <span class="text-slate-400">true · false</span>
</div>

<div v-click class="flex gap-3 items-start py-2 border-b border-slate-800">
  <code class="text-orange-400 w-28 shrink-0">eventType</code>
  <span class="text-slate-400">raised · cleared · changed</span>
</div>

</div>

---
layout: default
---

# Data Flow

<div class="mt-6">

<div class="text-sm font-semibold text-white mb-2">Live (continuous)</div>

<div class="font-mono text-sm bg-slate-900 rounded-lg p-4 mt-2 text-slate-300">

```
NBI  →  Probe  →  [source-level filter]  →  Internal Kafka (live)
     →  Consumer Router  →  [per-consumer filter + permitted scope]
     →  Consumer live topic
```

</div>

</div>

<div class="mt-8">

<div class="text-sm font-semibold text-white mb-2">Sync (on demand)</div>

<div class="font-mono text-sm bg-slate-900 rounded-lg p-4 mt-2 text-slate-300">

```
Consumer requests sync
→ Sync Handler validates with Auth Service
→ Sync Handler triggers probes  (SNMP excluded)
→ Probe pulls full dump from NBI
→ [source-level filter]  →  Internal Kafka (sync)
→ Consumer Router  →  [per-consumer filter + scope]
→ Consumer sync topic  →  Terminal marker
```

</div>

</div>

<div class="mt-4 text-xs text-slate-500">
Both paths go through the same two-layer filtering. The only difference is which internal and consumer Kafka topics are used.
</div>

---
layout: default
---

# Two-Layer Filtering

<div class="grid grid-cols-2 gap-10 mt-6">

<div>

<div class="text-sm font-semibold text-white mb-2">Layer 1 — Source Level (Probe)</div>

<v-clicks>

Compute the **union of all consumer subscriptions** → aggregate filter.

Probes only pull alarms matching this aggregate. If no consumer cares about SNMP alarms from a specific NE, the probe doesn't even ingest them.

If the NBI supports server-side filtering (CORBA filter expressions, Kafka topic selection), leverage it. Otherwise filter client-side.

Recomputed whenever subscriptions change.

</v-clicks>

</div>

<div>

<div class="text-sm font-semibold text-white mb-2">Layer 2 — Consumer Level (Router)</div>

<v-clicks>

Each alarm in internal Kafka is evaluated against **each consumer's specific filter** (subscription ∩ permitted scope).

Only matching alarms are produced to that consumer's topic.

This is where the fine-grained per-consumer logic lives.

Applies to both live and sync paths.

</v-clicks>

</div>
</div>

<v-click>
<div class="mt-6 border border-slate-700 rounded p-3 text-sm text-slate-400">
<span class="text-orange-400 font-mono text-xs">WHY TWO LAYERS?</span>  Layer 1 keeps the internal Kafka lean — we don't ingest what nobody wants. Layer 2 isolates consumers from each other — each gets only their slice.
</div>
</v-click>

---
layout: default
---

# Auth & RBAC

<div class="grid grid-cols-2 gap-10 mt-4">
<div>

<div class="text-sm font-semibold text-white mb-2">Auth Service</div>

<v-clicks>

Dedicated microservice. **All other services delegate auth to it — none implement auth logic themselves.**

Responsibilities:
- Consumer identity and credentials (API keys / tokens)
- RBAC role definitions and assignment
- Answer permission queries: *"can consumer X subscribe to Y?"*
- Ensure subscriptions stay within permitted scope

</v-clicks>

</div>
<div>

<div class="text-sm font-semibold text-white mb-2">Effective Subscription</div>

<v-click>

```
effective = requested ∩ permitted_scope
```

</v-click>

<v-click>

If a `ran-consumer` requests Transport alarms:
→ subscription rejected

If a `ran-consumer` requests all domains:
→ only Ran alarms delivered

</v-click>

<v-click>

**Permission axes** (same as subscription dimensions):

| Axis | Example |
|---|---|
| Domain | Ran, Transport, ALL |
| Severity | major+, all |
| Source NBI | specific IDs, ALL |
| Event types | raised+cleared, or include changed |

</v-click>

</div>
</div>

---
layout: default
---

# RBAC Roles

Example role definitions — adjust to real consumer needs:

<div class="grid grid-cols-2 gap-4 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-blue-400 font-mono text-xs uppercase mb-2">ran-consumer</div>
  <div class="text-slate-400">Domain: Ran only<br>Severity: all<br>NBIs: all Ran NMS instances<br>Events: raised + cleared</div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-green-400 font-mono text-xs uppercase mb-2">transport-consumer</div>
  <div class="text-slate-400">Domain: Transport + Transmission<br>Severity: all<br>NBIs: Nokia NSP + Huawei TX<br>Events: raised + cleared</div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-orange-400 font-mono text-xs uppercase mb-2">full-consumer</div>
  <div class="text-slate-400">Domain: ALL<br>Severity: all<br>NBIs: ALL<br>Events: raised + cleared + changed</div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-slate-300 font-mono text-xs uppercase mb-2">readonly-consumer</div>
  <div class="text-slate-400">Domain: any (scoped by assignment)<br>Severity: major+ only<br>NBIs: assigned<br>Events: raised + cleared only</div>
</div>

</div>

<v-click>
<div class="mt-4 text-xs text-slate-500">Roles bundle permissions. A consumer is assigned one or more roles. Effective scope = union of all assigned roles, intersected with the subscription at delivery time.</div>
</v-click>

---
layout: default
---

# Consumer Delivery Model

Each consumer gets two Kafka topics:

<div class="grid grid-cols-2 gap-10 mt-6">

<div v-click class="border-l-4 border-blue-500 pl-6">
  <div class="text-blue-400 font-semibold text-lg mb-2">Live topic</div>
  <div class="text-sm text-slate-300 mb-3">Continuous stream of normalized alarms. Always flowing. Never drained.</div>
  <div class="font-mono text-xs text-slate-500">
    consumer.{id}.live
  </div>
</div>

<div v-click class="border-l-4 border-amber-500 pl-6">
  <div class="text-amber-400 font-semibold text-lg mb-2">Sync topic</div>
  <div class="text-sm text-slate-300 mb-3">On-demand full alarm dump. Consumer drains it once, then discards. Terminal marker signals completion.</div>
  <div class="font-mono text-xs text-slate-500">
    consumer.{id}.sync
  </div>
</div>

</div>

<v-click>
<div class="mt-6 text-sm text-slate-400">

**Typical consumer startup sequence:**

1. Subscribe to Sentinel (declare subscription + get topics assigned)
2. Request sync → drain sync topic until terminal marker
3. Start consuming from live topic — now in steady state
4. If reconnecting after a gap → repeat sync before resuming live

</div>
</v-click>

---
layout: default
---

# Testing Strategy

<div class="text-sm mt-2 mb-4 text-slate-400">
Fully testable without production NBIs or real consumers. Single command to run the entire E2E suite.
</div>

<div class="grid grid-cols-2 gap-8">
<div>

<div class="text-sm font-semibold text-white mb-2">Mock NBI Services</div>

<v-clicks>

| Probe | Mock |
|---|---|
| corba-probe | `mock-corba-nms` — CORBA server, emits NT_ALARM, handles sync requests |
| sse-probe | `mock-sse-server` — auth + subscription + SSE stream + sync query |
| kafka-probe | Kafka + seeded NSP-format data — no extra service needed |
| snmp-probe | `mock-snmp-trap-sender` — sends trap PDUs on schedule |

Each mock can: emit alarms on schedule · simulate connection loss · respond to sync

</v-clicks>

</div>
<div>

<div class="text-sm font-semibold text-white mb-2">Mock Consumer</div>

<v-click>

A `mock-consumer` service that:
- Subscribes with a configurable subscription + role
- Reads live and sync Kafka topics
- Exposes REST for test assertions: received alarms, counts, last received

</v-click>

<v-click>

<div class="text-sm font-semibold text-white mt-4 mb-2">Auth in Tests</div>

Auth Service runs in **in-memory mode** — no external store. Pre-seeded with test consumers and roles via config. No separate mock needed.

</v-click>

</div>
</div>

---
layout: default
---

# E2E Test Scenarios

<div class="grid grid-cols-2 gap-x-10 gap-y-3 mt-6 text-sm">

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Live flow</span> — mock NBI emits alarms → assert mock-consumer receives only matching alarms</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Filtering</span> — two consumers with different subscriptions → each receives only its slice</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Sync</span> — consumer requests sync → receives canned alarm set + terminal marker</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Probe reconnect</span> — mock NBI drops connection → probe reconnects and resumes delivery</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Subscription change</span> — consumer updates subscription → subsequent alarms reflect new filter</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">SNMP no-sync</span> — consumer with SNMP-only subscription requests sync → graceful rejection</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Permission enforcement</span> — ran-consumer attempts to subscribe to Transport → rejected</div>
</div>

<div v-click class="flex gap-3">
  <span class="text-green-400 mt-0.5">✓</span>
  <div><span class="text-white">Scope intersection</span> — consumer subscribes to all domains but only has Ran permission → only Ran delivered</div>
</div>

</div>

<v-click>

```bash
docker compose --profile test up --abort-on-container-exit
```

</v-click>

---
layout: default
---

# Tech Stack

<div class="grid grid-cols-3 gap-4 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">SERVICES</div>
  <div class="text-slate-300">Java · Spring Boot</div>
  <div class="text-slate-500 text-xs mt-1">All backend services: probes, router, subscription mgr, sync handler, auth, dashboard BE</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">MESSAGING</div>
  <div class="text-slate-300">Apache Kafka</div>
  <div class="text-slate-500 text-xs mt-1">Internal Kafka + consumer delivery topics. Also used as Nokia NSP source interface.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">DASHBOARD</div>
  <div class="text-slate-300">React + TypeScript</div>
  <div class="text-slate-500 text-xs mt-1">Real-time topology, ECharts for throughput/lag, WebSocket (STOMP), Tailwind dark theme</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">DEPLOY</div>
  <div class="text-slate-300">Docker Compose + Ansible</div>
  <div class="text-slate-500 text-xs mt-1">All services containerized. Single <code>ansible-playbook site.yml</code> to stand up or update.</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">TESTING</div>
  <div class="text-slate-300">Compose test profile</div>
  <div class="text-slate-500 text-xs mt-1">mock-corba-nms · mock-sse-server · mock-snmp-trap-sender · mock-consumer · auth in-memory mode</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-500 text-xs font-mono mb-2">REPO</div>
  <div class="text-slate-300">Monorepo</div>
  <div class="text-slate-500 text-xs mt-1">All services, mocks, Ansible playbooks, and Compose files in a single repo.</div>
</div>

</div>

---
layout: center
class: text-center
---

<div class="flex flex-col items-center justify-center h-full">
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-6">Ready to build</div>
  <h1 class="text-5xl font-bold text-white mb-4">Let's ship it.</h1>
  <div class="text-slate-400 text-lg mb-10 max-w-md">
    4 probes · 1 router · 1 auth service · full E2E test coverage
  </div>
  <div class="grid grid-cols-4 gap-6 text-center mt-4">
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">4</div>
      probe types
    </div>
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">8+</div>
      NBI instances
    </div>
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">N</div>
      consumers
    </div>
    <div class="text-slate-500 text-sm">
      <div class="text-2xl font-bold text-white mb-1">1</div>
      common model
    </div>
  </div>
</div>
