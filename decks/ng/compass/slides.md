---
title: Compass — Southbound Adapter Layer
description: Unified southbound adapters — 8 NMS systems, 5 protocols, GraphQL northbound
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
  <div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-4">ngss · Design Onboarding</div>
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">Compass</h1>
  <div class="text-2xl text-slate-300 mb-8">Unified Southbound Adapter Layer</div>
  <div class="flex gap-6 text-sm text-slate-400">
    <span>8 NMS systems</span>
    <span>·</span>
    <span>5 protocols</span>
    <span>·</span>
    <span>GraphQL northbound</span>
    <span>·</span>
    <span>Template-first</span>
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
Why one adapter layer for everything

**Architecture**
End-to-end flow

**Templates**
The two files that define everything

**Client → GraphQL**
How requests come in

</div>
<div>

**Jinja2 Rendering**
How templates become real requests

**Protocol Adapters**
The contract, per protocol

**Response → GraphQL**
Extraction directives in action

**Cross-cutting**
RBAC, cache, audit, resilience

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

- 8 NMS systems, each with a different protocol
- SOAP, REST, SSH, NETCONF, SNMP — each handled ad-hoc
- Credentials scattered, auth logic duplicated
- Every new integration = bespoke code
- No unified API for callers
- No caching, no RBAC, no audit log

</v-clicks>
</div>
<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-3">Compass</div>
<v-clicks>

- One GraphQL API for all NMS systems
- Protocol adapters are generic — templates are vendor-specific
- Credentials centralized, auth lifecycle managed
- New integration = two files (template + schema)
- RBAC, cache, rate limits, audit out of the box
- Schema auto-generated from templates at startup

</v-clicks>
</div>
</div>

---
layout: default
---

# Design Principles

<div class="grid grid-cols-2 gap-6 mt-6">

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-2">01 · Template-first</div>
  <div class="text-sm text-slate-300">Every NMS call is a template. No dynamic query building, no business logic inside Compass. If it's not a template, it doesn't exist.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-2">02 · Adapters are protocol-generic</div>
  <div class="text-sm text-slate-300">The SOAP adapter knows nothing about nce_ip. The REST adapter knows nothing about nfm_t. Vendor specifics live entirely in the template files.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-2">03 · Atomic</div>
  <div class="text-sm text-slate-300">One template = one adapter call. No chaining, no depends_on, no multi-step orchestration. Composition is the caller's job.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-2">04 · No escape hatches</div>
  <div class="text-sm text-slate-300">No inline Python, no scripting, no code blocks in templates. Purely declarative. If you need code, you're solving the wrong problem in the wrong layer.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4 col-span-2">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-2">05 · GraphQL as the single contract</div>
  <div class="text-sm text-slate-300">Clients never know which NMS was called or which protocol was used. They send a typed GraphQL query and get a typed response. The schema is derived entirely from the registered templates — no hand-written SDL.</div>
</div>

</div>

---
layout: default
---

# Architecture — End to End

<div class="font-mono leading-snug text-slate-300 mt-2" style="font-size:11px">

```
┌──────────────────────────────────────────────┐
│   Client  ·  GraphQL query  ·  params        │
└─────────────────────┬────────────────────────┘
                      │
         ┌────────────▼────────────┐
         │  RBAC                   │  per-adapter · per-command
         └────────────┬────────────┘
                      │
         ┌────────────▼────────────┐
         │  Rate & Usage Limits    │
         └────────────┬────────────┘
                      │
         ┌────────────▼────────────┐
         │  GraphQL API            │  validate input · check cache
         └────────────┬────────────┘
                      │
┌─────────────────────▼────────────────────────┐
│  Template Engine                             │
│                                              │
│  Registry ──→ Jinja2 Renderer ←── Auth       │
│                    ↑                         │
│          Credential Resolver                 │
│                    ↓ rendered request        │
│  Protocol Adapter  (SOAP·REST·SSH·NETCONF)   │
│                    ↓ raw response            │
│  Response Parser   (XPath·JSONPath·TextFSM)  │
└─────────────────────┬────────────────────────┘
                      │
         ┌────────────▼────────────┐
         │  NMS / Network System   │  nce_ip · nfm_t · mae · cisco …
         └─────────────────────────┘
```

</div>

---
layout: default
---

# NMS Systems

<div class="grid grid-cols-4 gap-3 mt-6 text-sm">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-blue-400 font-mono text-xs mb-1">SOAP</div>
  <div class="font-semibold text-white">nce_ip</div>
  <div class="text-slate-500 text-xs mt-1">Huawei NCE IP</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-blue-400 font-mono text-xs mb-1">SOAP</div>
  <div class="font-semibold text-white">nce_t</div>
  <div class="text-slate-500 text-xs mt-1">Huawei NCE Transport</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-green-400 font-mono text-xs mb-1">REST</div>
  <div class="font-semibold text-white">nfm_t</div>
  <div class="text-slate-500 text-xs mt-1">Nokia NFM-T</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-green-400 font-mono text-xs mb-1">REST</div>
  <div class="font-semibold text-white">nokia_tx</div>
  <div class="text-slate-500 text-xs mt-1">Nokia TX</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-green-400 font-mono text-xs mb-1">REST</div>
  <div class="font-semibold text-white">cloud</div>
  <div class="text-slate-500 text-xs mt-1">Cloud NMS</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-yellow-400 font-mono text-xs mb-1">SSH</div>
  <div class="font-semibold text-white">datacore</div>
  <div class="text-slate-500 text-xs mt-1">DataCore</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-yellow-400 font-mono text-xs mb-1">SSH</div>
  <div class="font-semibold text-white">cisco</div>
  <div class="text-slate-500 text-xs mt-1">Cisco IOS</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-purple-400 font-mono text-xs mb-1">NETCONF</div>
  <div class="font-semibold text-white">mae</div>
  <div class="text-slate-500 text-xs mt-1">Huawei MAE</div>
</div>

</div>

<div v-click class="mt-6 text-xs text-slate-500 border border-slate-800 rounded px-4 py-2">
  All 8 systems share the same engine. Adding a new system = adding template files. No code changes.
</div>

---
layout: default
---

# A Template is Two Files

<div class="grid grid-cols-2 gap-8 mt-4">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">get_alarms.xml.j2</div>

<div class="text-xs text-slate-400 mb-2">Raw Jinja2 — the exact request sent to the NMS. Nothing else.</div>

```xml
<soapenv:Envelope
  xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:nce="http://www.huawei.com/nce">
  <soapenv:Header/>
  <soapenv:Body>
    <nce:getAlarms>
      <nce:neId>{{ ne_id }}</nce:neId>
      <nce:severity>{{ severity }}</nce:severity>
    </nce:getAlarms>
  </soapenv:Body>
</soapenv:Envelope>
```

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">get_alarms.graphql</div>

<div class="text-xs text-slate-400 mb-2">Input schema + typed output with extraction directives.</div>

```graphql
input GetAlarmsInput {
  ne_id: String!
  severity: AlarmSeverity = CRITICAL
}

enum AlarmSeverity {
  CRITICAL MAJOR MINOR WARNING
}

type Alarm {
  alarm_id:    ID!      @xpath(path: "//alarm/@id")
  severity:    String!  @xpath(path: "//alarm/severity")
  description: String   @xpath(path: "//alarm/description")
  raised_at:   DateTime @xpath(path: "//alarm/raisedTime")
}
```

</div>
</div>

<div v-click class="mt-4 text-xs text-slate-500 border border-slate-800 rounded px-4 py-2">
  No YAML. No inline code. No scripting. Per-template runtime config (cache TTL, timeout, RBAC) lives in the app — not on the filesystem.
</div>

---
layout: default
---

# Client → GraphQL

<div class="grid grid-cols-2 gap-8 mt-4">
<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-2">Client sends</div>

```graphql
query {
  get_alarms(input: {
    ne_id: "NCE-001"
    severity: CRITICAL
  }) {
    alarm_id
    severity
    description
    raised_at
  }
}
```

</div>
<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-3">What happens</div>

<div class="space-y-1.5 text-xs text-slate-300">
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">1</span><span>RBAC — does this client have access to <code>get_alarms</code>?</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">2</span><span>Rate limits — within quota?</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">3</span><span>Cache — fresh result for these params?</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">4</span><span>Validate input against <code>GetAlarmsInput</code> type</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">5</span><span>Resolve credentials for <code>nce_ip</code></span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">6</span><span>Authenticate (session token, api key…)</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">7</span><span>Render Jinja2 template with <code>ne_id</code> and <code>severity</code></span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">8</span><span>POST SOAP envelope to nce_ip endpoint</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">9</span><span>Parse XML response → extract fields via XPath</span></div>
<div v-click class="flex gap-2"><span class="text-indigo-400 font-mono w-4 shrink-0">10</span><span>Return typed <code>[Alarm]</code> result</span></div>
</div>

</div>
</div>

---
layout: default
---

# Jinja2 Rendering

<div class="mt-4 text-sm text-slate-400 mb-6">The renderer takes validated input params and produces the exact request body. This is raw templating — no abstractions, no magic.</div>

<div class="grid grid-cols-3 gap-6">

<div>
<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Input params</div>

```json
{
  "ne_id": "NCE-001",
  "severity": "CRITICAL"
}
```
</div>

<div class="flex items-center justify-center text-slate-600 text-2xl">→</div>

<div>
<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Rendered request</div>

```xml
<soapenv:Envelope ...>
  <soapenv:Body>
    <nce:getAlarms>
      <nce:neId>NCE-001</nce:neId>
      <nce:severity>CRITICAL</nce:severity>
    </nce:getAlarms>
  </soapenv:Body>
</soapenv:Envelope>
```
</div>

</div>

<div class="mt-8 grid grid-cols-3 gap-4 text-xs">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-indigo-400 font-mono mb-1">SOAP</div>
  <div class="text-slate-400">Full XML envelope — namespace declarations, headers, body structure — all in the template</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-green-400 font-mono mb-1">REST</div>
  <div class="text-slate-400">JSON body, query params, path segments — whatever the API expects, verbatim</div>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-yellow-400 font-mono mb-1">SSH</div>
  <div class="text-slate-400">A single CLI command string: <code>show interfaces {{ interface }}</code></div>
</div>

</div>

---
layout: default
---

# Protocol Adapters — The Contract

<div class="mt-4 text-sm text-slate-400 mb-4">Every adapter is protocol-generic. It receives a rendered string and returns raw bytes. No NMS knowledge — that's the template's job.</div>

<div class="grid grid-cols-2 gap-8 text-xs">
<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-2">Adapter receives</div>

```
RenderedRequest
  body:       str          # rendered Jinja2 output
  endpoint:   str          # from adapter config
  auth:       ResolvedCredential
  timeout:    int
```

</div>
<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-2">Adapter returns</div>

```
AdapterResponse
  raw:    str              # raw NMS response, uninterpreted
  status: ok | error
  error:
    code:    SOAP_FAULT | HTTP_ERROR |
             SSH_ERROR | TIMEOUT | ...
    message: str
    raw:     str           # raw error body
```

</div>
</div>

<div class="mt-6 grid grid-cols-4 gap-3 text-xs">

<div v-click class="border-l-2 border-blue-500 pl-3">
  <div class="text-blue-400 font-mono mb-1">SOAP</div>
  <div class="text-slate-400">HTTP POST · sets SOAPAction header · catches <code>&lt;soapenv:Fault&gt;</code> even on HTTP 200</div>
</div>

<div v-click class="border-l-2 border-green-500 pl-3">
  <div class="text-green-400 font-mono mb-1">REST</div>
  <div class="text-slate-400">HTTP method from adapter config · 4xx/5xx → HTTP_ERROR · supports fire_and_forget</div>
</div>

<div v-click class="border-l-2 border-yellow-500 pl-3">
  <div class="text-yellow-400 font-mono mb-1">SSH</div>
  <div class="text-slate-400">Pooled channel · sends command · returns stdout · stderr patterns → SSH_ERROR</div>
</div>

<div v-click class="border-l-2 border-purple-500 pl-3">
  <div class="text-purple-400 font-mono mb-1">NETCONF</div>
  <div class="text-slate-400">Sends rendered XML as <code>&lt;rpc&gt;</code> · catches <code>&lt;rpc-error&gt;</code></div>
</div>

</div>

---
layout: default
---

# Response → GraphQL

<div class="mt-4 text-sm text-slate-400 mb-4">The Response Parser reads the extraction directives from the <code>.graphql</code> output type and applies them to the raw NMS response.</div>

<div class="grid grid-cols-2 gap-8">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Raw NMS response (SOAP XML)</div>

```xml
<alarmList>
  <alarm id="AL-001">
    <severity>CRITICAL</severity>
    <description>Link down on port 0/1</description>
    <raisedTime>2026-04-01T10:00:00</raisedTime>
  </alarm>
  <alarm id="AL-002">
    <severity>MAJOR</severity>
    <description>High CPU utilization</description>
    <raisedTime>2026-04-01T10:05:00</raisedTime>
  </alarm>
</alarmList>
```

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Extraction directives drive parsing</div>

```graphql
type Alarm {
  alarm_id:    ID!      @xpath(path: "//alarm/@id")
  severity:    String!  @xpath(path: "//alarm/severity")
  description: String   @xpath(path: "//alarm/description")
  raised_at:   DateTime @xpath(path: "//alarm/raisedTime")
}
```

<div v-click class="mt-4 text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">GraphQL response</div>

<div v-click>

```json
{ "data": { "get_alarms": [
  { "alarm_id": "AL-001",
    "severity": "CRITICAL",
    "description": "Link down on port 0/1",
    "raised_at": "2026-04-01T10:00:00" },
  { "alarm_id": "AL-002",
    "severity": "MAJOR",
    "description": "High CPU utilization",
    "raised_at": "2026-04-01T10:05:00" }
]}}
```

</div>
</div>
</div>

---
layout: default
---

# Extraction Directives by Protocol

<div class="mt-6 grid grid-cols-2 gap-6 text-sm">

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-blue-400 font-mono text-xs uppercase tracking-wide mb-3">SOAP / XML → @xpath</div>

```graphql
type NeStatus {
  ne_id:   ID!     @xpath(path: "//ne/@id")
  status:  String! @xpath(path: "//ne/operStatus")
}
```

  <div class="text-slate-500 text-xs mt-2">W3C XPath 1.0 against the full response XML</div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-green-400 font-mono text-xs uppercase tracking-wide mb-3">REST / JSON → @jsonpath</div>

```graphql
type Interface {
  name:  String! @jsonpath(path: "$.name")
  state: String! @jsonpath(path: "$.oper-state")
  speed: Int     @jsonpath(path: "$.speed")
}
```

  <div class="text-slate-500 text-xs mt-2">JSONPath against the parsed response body</div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-yellow-400 font-mono text-xs uppercase tracking-wide mb-3">SSH → @textfsm / @regex</div>

```graphql
type Interface {
  name:  String! @textfsm(field: "INTF")
  state: String! @textfsm(field: "LINK_STATUS")
  proto: String! @textfsm(field: "PROTO_STATUS")
}
```

  <div class="text-slate-500 text-xs mt-2">TextFSM template file lives alongside the <code>.j2</code></div>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-purple-400 font-mono text-xs uppercase tracking-wide mb-3">NETCONF → @xpath</div>

```graphql
type PortConfig {
  port_id:  ID!     @xpath(path: "//port/@id")
  mtu:      Int!    @xpath(path: "//port/mtu")
  enabled:  Boolean @xpath(path: "//port/enabled")
}
```

  <div class="text-slate-500 text-xs mt-2">Same XPath engine as SOAP — NETCONF responses are XML</div>
</div>

</div>

---
layout: default
---

# Template Generation

<div class="mt-4 text-sm text-slate-400 mb-6">Templates are generated from standard source specs. The generator produces both files. Generated files are the starting point — hand-tuning is expected and the generator is non-destructive.</div>

<div class="grid grid-cols-2 gap-6 text-sm">

<div v-click class="border-l-2 border-blue-500 pl-4">
  <div class="text-blue-400 font-mono text-xs mb-2">WSDL → SOAP templates</div>
  <div class="text-slate-400 text-xs">Parse operations + XSD input/output types → SOAP envelope Jinja2 + GraphQL types with XPath directives auto-derived from XSD paths</div>
</div>

<div v-click class="border-l-2 border-green-500 pl-4">
  <div class="text-green-400 font-mono text-xs mb-2">OpenAPI → REST templates</div>
  <div class="text-slate-400 text-xs">Parse paths + request/response schemas → JSON body Jinja2 + GraphQL types with JSONPath directives derived from schema field names</div>
</div>

<div v-click class="border-l-2 border-purple-500 pl-4">
  <div class="text-purple-400 font-mono text-xs mb-2">YANG → NETCONF templates</div>
  <div class="text-slate-400 text-xs">Parse RPC definitions → NETCONF <code>&lt;rpc&gt;</code> XML Jinja2 + GraphQL types from YANG input/output nodes with XPath</div>
</div>

<div v-click class="border-l-2 border-yellow-500 pl-4">
  <div class="text-yellow-400 font-mono text-xs mb-2">NTC / manual → SSH templates</div>
  <div class="text-slate-400 text-xs">CLI command string Jinja2 + GraphQL types defined manually, TextFSM template from NTC library or written by hand</div>
</div>

</div>

<div v-click class="mt-8 text-xs text-slate-500 border border-slate-800 rounded px-4 py-3">
  <span class="text-indigo-400 font-mono">nce_ip example:</span> WSDL with ~80 operations → 80 template pairs generated in one pass. Hand-tune the 10 you actually use.
</div>

---
layout: default
---

# RBAC & Access Control

<div class="mt-6 grid grid-cols-2 gap-8 text-sm">

<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-3">Two levels</div>

<v-clicks>

**Per-adapter**
Client A has no access to `nce_ip` at all. Blocked before any template lookup.

**Per-command**
Client A can call `get_alarms` but not `delete_ne`. Enforced after adapter access is confirmed.

</v-clicks>

</div>
<div>

<div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-3">Configured at registration</div>

<v-click>

When a template is registered in the app, you assign:
- Which roles / clients can access it
- Read vs write designation (for future mutation enforcement)

No filesystem config. RBAC lives in the app alongside the per-template runtime config.

</v-click>

</div>
</div>

---
layout: default
---

# Cache, Resilience & Audit

<div class="mt-6 grid grid-cols-3 gap-6 text-sm">

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-3">Cache</div>
  <ul class="text-slate-400 text-xs space-y-2">
    <li>Per-template TTL</li>
    <li>Global default from app config</li>
    <li>Client can pass <code>cache: false</code> to skip</li>
    <li>Mutations and fire-and-forget always bypass</li>
  </ul>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-3">Resilience</div>
  <ul class="text-slate-400 text-xs space-y-2">
    <li>Retry with exponential backoff</li>
    <li>Circuit breaker per adapter</li>
    <li>Connection pooling per host (TTL-based)</li>
    <li>Auth: re-acquire on 401, retry once</li>
  </ul>
</div>

<div v-click class="border border-slate-700 rounded p-4">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-3">Audit Log</div>
  <ul class="text-slate-400 text-xs space-y-2">
    <li>Every execution logged</li>
    <li>Client identity</li>
    <li>Template ID + params</li>
    <li>Timestamp + result status</li>
  </ul>
</div>

</div>

<div v-click class="mt-6 border border-slate-700 rounded p-4 text-sm">
  <div class="text-indigo-400 font-mono text-xs uppercase tracking-wide mb-2">Bulk Execution</div>
  <div class="text-slate-400 text-xs">Multiple templates in a single GraphQL request — engine executes them in parallel. Standard GraphQL batching, no special client handling needed.</div>
</div>

---
layout: default
---

# Adding a New Template

<div class="grid grid-cols-2 gap-8 mt-4">
<div class="text-sm">

<v-clicks>

**1. Generate from source spec**
```bash
compass scaffold soap \
  --wsdl nce_ip.wsdl \
  --operation getTopology
```
<div class="text-slate-500 text-xs mb-3">Produces <code>get_topology.xml.j2</code> + <code>get_topology.graphql</code></div>

**2. Review and hand-tune**
<div class="text-slate-400 text-xs mb-3">Check XPath expressions, adjust field names, add nullable annotations.</div>

**3. Register in the app**
<div class="text-slate-400 text-xs mb-3">Set TTL, assign RBAC roles.</div>

**4. Done**
<div class="text-slate-400 text-xs">Schema updates at next startup. Clients query immediately.</div>

</v-clicks>

</div>
<div v-click>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">What you don't do</div>

<div class="space-y-1.5 text-xs text-slate-500">
  <div class="flex gap-2"><span class="text-red-500">✗</span> Write any Python / Java / Go code</div>
  <div class="flex gap-2"><span class="text-red-500">✗</span> Register a new HTTP route</div>
  <div class="flex gap-2"><span class="text-red-500">✗</span> Write GraphQL resolvers</div>
  <div class="flex gap-2"><span class="text-red-500">✗</span> Handle auth or credentials</div>
  <div class="flex gap-2"><span class="text-red-500">✗</span> Think about connection pooling</div>
  <div class="flex gap-2"><span class="text-red-500">✗</span> Wire up caching</div>
</div>

<div class="mt-4 border border-indigo-800 rounded p-3 bg-indigo-950/30">
  <div class="text-indigo-400 text-xs">Two files. That's the integration surface.</div>
</div>

</div>
</div>

---
layout: default
---

# Summary

<div class="grid grid-cols-2 gap-x-12 gap-y-4 mt-8 text-sm">

<div v-click class="flex gap-3">
  <span class="text-indigo-400 font-mono text-xs mt-0.5">01</span>
  <div>
    <div class="text-white font-medium">One API for everything</div>
    <div class="text-slate-500 text-xs mt-1">GraphQL schema auto-derived from templates. Clients don't know or care which NMS or protocol is behind a query.</div>
  </div>
</div>

<div v-click class="flex gap-3">
  <span class="text-indigo-400 font-mono text-xs mt-0.5">02</span>
  <div>
    <div class="text-white font-medium">Templates are the integration unit</div>
    <div class="text-slate-500 text-xs mt-1">A new NMS command = two files. No code, no routes, no resolvers.</div>
  </div>
</div>

<div v-click class="flex gap-3">
  <span class="text-indigo-400 font-mono text-xs mt-0.5">03</span>
  <div>
    <div class="text-white font-medium">Adapters are generic</div>
    <div class="text-slate-500 text-xs mt-1">SOAP adapter knows SOAP. It doesn't know nce_ip. Vendor specifics live only in templates.</div>
  </div>
</div>

<div v-click class="flex gap-3">
  <span class="text-indigo-400 font-mono text-xs mt-0.5">04</span>
  <div>
    <div class="text-white font-medium">Schema drives extraction</div>
    <div class="text-slate-500 text-xs mt-1">GraphQL output types carry extraction directives. The type definition and parsing config are one thing.</div>
  </div>
</div>

<div v-click class="flex gap-3">
  <span class="text-indigo-400 font-mono text-xs mt-0.5">05</span>
  <div>
    <div class="text-white font-medium">Cross-cutting is free</div>
    <div class="text-slate-500 text-xs mt-1">RBAC, cache, rate limits, retry, circuit breaker, audit — every template gets all of this without any template-level config.</div>
  </div>
</div>

<div v-click class="flex gap-3">
  <span class="text-indigo-400 font-mono text-xs mt-0.5">06</span>
  <div>
    <div class="text-white font-medium">Generated from standards</div>
    <div class="text-slate-500 text-xs mt-1">WSDL, OpenAPI, YANG → scaffold both files. Hand-tune what matters, ignore the rest.</div>
  </div>
</div>

</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">compass · 2026</div>
