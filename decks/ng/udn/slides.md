---
title: UDN — IPDR / NAT Lawful Intercept Platform
description: Real-time telecom data collection, correlation, and legal reporting for Vodafone Turkey
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
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-4">ngss · Dev / Analyst Onboarding</div>
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">UDN</h1>
  <div class="text-2xl text-slate-300 mb-8">IPDR / NAT Lawful Intercept Platform</div>
  <div class="flex gap-6 text-sm text-slate-400">
    <span>Vodafone Turkey</span>
    <span>·</span>
    <span>9 sites</span>
    <span>·</span>
    <span>2 data flows</span>
    <span>·</span>
    <span>Real-time + offline</span>
  </div>
</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">2026</div>

---
layout: default
---

# Agenda

<div class="grid grid-cols-2 gap-x-12 gap-y-3 mt-6 text-sm">
<div>

**Why UDN exists**
Legal mandate, what must be logged

**System overview**
Two flows, one pipeline

**Sites & infrastructure**
9 sites, node types, Kafka cluster

**Repos & code map**
What lives where

**Flow 1 — RADIUS + Syslog**
Workers → Flink → NAT reports → BTK / LDM

</div>
<div>

**Flow 2 — UFDR**
DPI workers → Flink → IPDR reports

**Kafka topics**
Full topic reference

**Loggers & file rolling**
How report files are produced

**File delivery**
Destinations, scripts, scheduling

**HSM & offline recovery**
Archival, replay from raw CSVs

</div>
</div>

---
layout: default
---

# Why UDN Exists

<div class="grid grid-cols-2 gap-12 mt-4">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">The legal mandate</div>

Turkish law requires mobile operators to log every subscriber's internet activity and retain it for **10 years**:

<v-clicks>

- **Who** connected — MSISDN, IMSI, IMEI
- **From where** — private IP, cell location, site
- **To what** — destination IP, port, protocol, app
- **When & how long** — timestamps, session duration
- **How much** — bytes up/down, packet counts
- **Via which NAT** — private → public IP/port mapping

</v-clicks>

</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">What UDN does</div>

<v-clicks>

- Collects raw events from network devices at wire speed
- Correlates subscriber identity with network sessions
- Formats records into standardized legal report formats
- Delivers reports to **BTK** (regulator) and **LDM** (intercept system)
- Archives everything long-term to **HSM**
- Can **replay** from HSM raw files if outputs are lost

</v-clicks>

</div>
</div>

---
layout: default
---

# Two Flows, One Pipeline

<div class="grid grid-cols-2 gap-6 mt-4">

<div class="border border-blue-700 rounded-lg p-5">
  <div class="text-xs font-mono text-blue-400 uppercase tracking-widest mb-3">Flow 1 · RADIUS + Syslog</div>

  **Source data:** RADIUS accounting packets + Juniper NAT session logs

  **What it tracks:** NAT translations — which subscriber's private IP mapped to which public IP/port at what time

  **Produces:**
  - `natv2` — legacy NAT session format
  - `natv3` — current NAT session format
  - `pbanat` — port-block allocation NAT
  - `notcorrelated` — unmatched syslog records

  **Destinations:** BTK · LDM · HSM

</div>

<div class="border border-green-700 rounded-lg p-5">
  <div class="text-xs font-mono text-green-400 uppercase tracking-widest mb-3">Flow 2 · UFDR</div>

  **Source data:** Binary DPI (Deep Packet Inspection) records from Huawei probes

  **What it tracks:** Layer 7 detail — actual HTTP/DNS/TCP sessions with full subscriber context

  **Produces:**
  - `ipdrv1` / `ipdrv2` — HTTP, TCP, UDP, DNS, SMTP…
  - `nonat` — static IP + IPv6 (non-NAT events)
  - `domain` — visited domain + category
  - `app` — per-app usage counts

  **Destinations:** BTK/kurum · LDM · HSM

</div>
</div>

<div class="mt-4 text-sm text-slate-400">The two flows are independent pipelines sharing infrastructure (Kafka cluster, logger machines). They complement each other: UFDR has richer app-layer data; RADIUS+Syslog covers sessions that DPI probes may miss.</div>

---
layout: default
---

# System Architecture

<div class="font-mono leading-snug text-slate-300 mt-2" style="font-size:10.5px">

```
┌─ Sources ─────────────────────────────────────────────────────────────────────┐
│  RADIUS accounting · UDP:1813        Juniper syslog · UDP          UFDR DPI · UDP  │
└────────────┬────────────────────────────────┬────────────────────────┬────────┘
             │                                │                        │
    ┌─────────▼────────┐             ┌─────────▼────────┐   ┌──────────▼────────┐
    │  radiusclient    │             │  syslog worker   │   │  ufdr worker      │
    │  (AVP parser)    │             │  (regex parser)  │   │  (TLV parser)     │
    │  + HSM CSV bkp ──┼────────┐    │  + HSM CSV bkp ──┼───┼──▶ ufdr-info      │
    └─────────┬────────┘        │    └─────────┬────────┘   │  ▶ ufdr-base      │
              │                 │              │             │  ▶ ufdr-stats     │
        [radius topic]          │        [syslog topic]     └───────────────────┘
              │                 │              │
    ┌─────────▼──────────────────▼────┐        │       ┌────────────────────────┐
    │      nat2sysrad  (Flink)        │        │       │   Manager  (Flink)     │
    │  KeyedCoProcessFunction         │        │       │   StatsMatcher         │
    │  RADIUS.ip == syslog.src_ip     │        │       │     base ✕ stats       │
    │  TTL: 1 day · RocksDB           │        │       │   InfoMatcher          │
    └─────────────┬───────────────────┘        │       │     info ✕ above       │
                  │                            │       └──────┬────────┬────────┘
        [nat2reportsysrad]              [HSM raw CSVs]        │        │
                  │                    (esycollector→HSM)  [ufdr-nat] [ufdr-noinfo]
    ┌─────────────▼──────────┐                │              │        │
    │  NAT loggers           │                │    ┌─────────▼──┐  ┌──▼──────────┐
    │  natv2 · natv3         │                │    │IPDR loggers│  │ RequestApp  │
    │  pbanat · unmatched    │                │    │ipdrv1/v2   │  │ re-requests │
    └─────────────┬──────────┘                │    │nonat/domain│  │ info via UDP│
                  │                           │    └─────────┬──┘  └────────────┘
    ┌─────────────▼───────────────────────────▼────────────▼──────────────────┐
    │          Destinations                                                     │
    │  BTK:/MOBIL_TRAFIK (natv3)  BTK:/CGNAT (natv2)  pbanat-server (pbanat)  │
    │  LDM:/Regulasyon/ (natv3, nonat)   kurum (ipdrv1/v2, in progress)        │
    │  HSM: hsm2:/scoutfs/vftresn/10year/natipdr/  (raw input + reports)       │
    └───────────────────────────────────────────────────────────────────────────┘
```

</div>

---
layout: default
---

# Sites & Infrastructure

<div class="grid grid-cols-5 gap-3 mt-4 text-xs">

<div class="border border-orange-700 rounded-lg p-3 col-span-2">
  <div class="text-orange-400 font-mono uppercase tracking-wide mb-2 text-xs">Mobile sites (5)</div>

  | Code | Workers | Loggers | Flink |
  |------|---------|---------|-------|
  | **esy** | 10 | 4 | 14 |
  | **tzl** | 26 | 4 | 14 |
  | **adn** | 12 | 5 | 18 |
  | **psk** | 26 | 4 | 14 |
  | **gzm** | 10 | 4 | 14 |

</div>

<div class="space-y-3 col-span-1">

  <div class="border border-slate-600 rounded-lg p-3">
  <div class="text-slate-400 font-mono uppercase tracking-wide mb-2 text-xs">DRC backup (2)</div>

  **drcpsk** — 26w · 5l · 18f
  **drcadn** — 26w · 4l · 14f
  </div>

  <div class="border border-slate-600 rounded-lg p-3">
  <div class="text-slate-400 font-mono uppercase tracking-wide mb-2 text-xs">Fixed network (2)</div>

  **fixgzm** — 10w · 2l
  **fixtzl** — 10w · 1l
  </div>

</div>

<div class="col-span-2 space-y-3">

  <div class="border border-slate-700 rounded-lg p-3">
  <div class="text-slate-400 font-mono uppercase tracking-wide mb-2 text-xs">Node naming</div>
  <code class="text-green-400">{site}{role}{N}</code>

  ```
  adnworker3   psklogger2
  tzlflink5    esykafka1
  esycollector2
  ```
  SSH: all via jumphost `ng` (see wiki)
  </div>

  <div class="border border-slate-700 rounded-lg p-3">
  <div class="text-slate-400 font-mono uppercase tracking-wide mb-2 text-xs">Kafka cluster (per site)</div>

  ```
  169.254.0.10-15:9092
  schema registry :8081
  retention: 5 minutes ⚠️
  ```

  **ESY only:** `esycollector1-4` stage files before HSM transfer
  </div>

</div>
</div>

---
layout: default
---

# Repos & Code Map

<div class="grid grid-cols-2 gap-8 mt-4">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">Repositories</div>

<div class="space-y-2 text-sm">

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-orange-400 font-mono text-xs mb-1">udn-client · main repo</div>
  Workers, loggers, manager Flink, request handler, dispatcher. Everything except the RADIUS probe and nat2sysrad Flink.
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-blue-400 font-mono text-xs mb-1">nat2sysrad · Flink job</div>
  Correlates RADIUS + syslog → <code>nat2reportsysrad</code>
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-blue-400 font-mono text-xs mb-1">radiusclient · RADIUS probe</div>
  UDP:1813 listener, AVP parser → <code>radius</code> topic
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 font-mono text-xs mb-1">udn-recovery · offline replay</div>
  Reads HSM raw CSVs → regenerates NAT2/NAT3
</div>

<div v-click class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 font-mono text-xs mb-1">pbanat-calc · library</div>
  Private IP → public IP + port-range mapping
</div>

</div>
</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">udn-client package layout</div>

```
src/main/java/.../udn/
│
├── client/            workers
│   ├── ufdr/          binary TLV parser
│   ├── syslog/        RFC5424 regex parser
│   └── hsm/           raw CSV backup writers
│
├── logger/            loggers
│   └── reporters/     one class per report type
│
├── manager/           Flink UFDR correlation
│   └── base/          shared matcher logic
│
├── request/           ufdr-noinfo → UDP re-request
├── dispatcher/        SFTP delivery (ESY)
└── common/            Kafka, Avro, metrics
```

Entry: `App.java` (picocli)
Subcommands: `client · logger · manager · request · dispatcher`
Config: `/opt/udn/service.env` (generated from Ansible template)

</div>
</div>

---
layout: default
---

# Flow 1 — Syslog Worker

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-blue-400 uppercase tracking-widest mb-2">SyslogListener / SyslogRecordHandler</div>

**Transport:** Netty Epoll UDP
**Source:** Juniper routers emit `RT_FLOW_SESSION_CREATE` / `RT_FLOW_SESSION_CLOSE`
**Parser:** Regex on RFC 5424

**Fields extracted:**

```
source_address       private subscriber IP
source_port
nat_source_address   translated public IP
nat_source_port
destination_address / destination_port
protocol_id          6=TCP  17=UDP
bytes_from_client, bytes_from_server
packets_from_client, packets_from_server
elapsed_time         session duration (s)
reason               termination code
UDNJuniperIP         which NAT box sent this
```

**Kafka output:** `syslog` topic, keyed by `source_address`
**HSM backup:** also writes pipe-delimited gzip CSV to `/opt/udn/bck/hsm/`

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Filters applied</div>

<div class="space-y-2 text-sm">

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs mb-1">DNS drop</div>
  88 Vodafone DNS IPs + port 53 are excluded. Optional ultra-DNS mode drops all port 53 traffic.
</div>

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs mb-1">NAT validity</div>
  Dropped if <code>nat_src == src</code> (no translation) or <code>nat_src == 0.0.0.0</code>.
</div>

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs mb-1">KKTC variant (Cyprus)</div>
  Different regex, timestamps shifted +3h UTC. File suffix differs.
</div>

</div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-4 mb-2">HSM CSV format (20 fields, pipe-delimited)</div>

```
time | type | src_ip | src_port |
nat_src_ip | nat_src_port |
nat_dst_ip | nat_dst_port | proto |
pkts_client | bytes_client |
pkts_server | bytes_server |
session_id | elapsed | juniper_ip |
reason | timestamp | dst_ip | dst_port
```

</div>
</div>

---
layout: default
---

# Flow 1 — RADIUS Worker

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-blue-400 uppercase tracking-widest mb-2">radiusclient — RadiusPacketHandler</div>

**Transport:** Netty UDP port **1813**
**Source:** Vodafone core sends RADIUS Accounting-Request packets
**Parser:** Standard AVPs + Vodafone VSAs (vendor 14122)

**Key AVP → Avro field mapping:**

| AVP | Avro field | Meaning |
|-----|------------|---------|
| 8 | `field_8` | Subscriber IP (correlation key) |
| 30 | `field_30` | APN (Called-Station-Id) |
| 31 | `field_31` | MSISDN |
| 40 | `field_40` | Type: 1=Start 2=Stop 3=Interim |
| 44 | `field_44` | Session ID (join key) |
| 55 | `field_55` | Timestamp |
| VSA 104151 | `field_104151` | IMSI |
| VSA 104152 | `field_104152` | Charging ID |
| VSA 104156/7 | `field_104156/7` | SGSN/GGSN IP |
| VSA 104158 | `field_104158` | MCCMNC |
| VSA 1041520 | `field_1041520` | IMEI |
| VSA 1041521 | `field_1041521` | RAT type |
| VSA 1041522 | `field_1041522` | LAC:SAC |

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Filters & routing</div>

<div class="space-y-2 text-sm mb-4">

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs mb-1">APN filter</div>
  <code>field_30 == "wttx"</code> or <code>"internetstatik"</code> → dropped entirely.
  <code>"internet"</code> → kept, but written as empty string in all report outputs.
</div>

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs mb-1">Optional features</div>
  RADIUS forwarding to second server, Accounting-Response sending, Redis publishing — all configurable but not active in prod.
</div>

</div>

**Kafka output:** `radius` topic, keyed by `field_8` (subscriber IP)

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-4 mb-2">RADIUS types</div>

```
field_40 = 1  →  Accounting-Start
field_40 = 2  →  Accounting-Stop
field_40 = 3  →  Accounting-Interim
```

nat2sysrad ignores Stop records when looking up RADIUS for syslog correlation — it wants the most recent non-Stop record before the syslog timestamp.

</div>
</div>

---
layout: default
---

# Flow 1 — Flink: nat2sysrad

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-blue-400 uppercase tracking-widest mb-2">Correlation logic</div>

<div class="font-mono text-slate-300 text-xs leading-relaxed border border-slate-700 rounded p-3 mb-3">

```
radius  ──key: field_44──▶  re-keyed by field_8 (IP)
                                        │
syslog  ──key: source_address───────────┘
                     │
          KeyedCoProcessFunction
                     │
     match: radius.field_8 == syslog.source_address
          + RADIUS time before syslog event
                     │
          ┌──────────┴──────────┐
    nat2reportsysrad      unmatchedreportsysrad
                               latematchreportsysrad
```

</div>

**State backend:** RocksDB
**RADIUS TTL:** 1 day
**Checkpointing:** every 60 seconds
**Parallelism:** filter ×20 · join ×60 · sink ×30

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Output record fields (nat2report.avsc)</div>

<div class="grid grid-cols-2 gap-x-4 text-xs">
<div>

| Field | Meaning |
|-------|---------|
| MSISDN / IMSI / IMEI | Identity |
| OZELIP / OZELPORT | Private IP/port |
| GENELIP / GENELPORT | Public NAT IP/port |
| HEDEFIP / HEDEFPORT | Destination |
| BASLANGICTARIH | Session start |
| SURE | Duration (s) |

</div>
<div>

| Field | Meaning |
|-------|---------|
| KAYITTIPI | 0=CREATE / 1=CLOSE |
| TERMINATIONCAUSE | Reason |
| NATCIHAZIP | NAT device IP |
| RATTYPE | Radio access type |
| MCCMNC | Network code |
| YURTICIYURTDISI | 0=domestic / 1=intl |
| SGSNIP / GGSNIP | Core node IPs |
| SGSNHOSTNAME | Resolved hostname |

</div>
</div>

<div class="border border-slate-700 rounded p-2 mt-2 text-xs">
  <span class="text-slate-400">International detection:</span> MCCMNC=28602 (Cyprus) or source IP in Cyprus ranges → <code>YURTICIYURTDISI=1</code>
</div>

<div class="border border-slate-700 rounded p-2 mt-2 text-xs">
  <span class="text-slate-400">Hostname resolution:</span> SGSN/GGSN IPs looked up in <code>SGSNGGSNMappings.csv</code>. NAT device IPs in <code>CGNATHostMappings.csv</code>.
</div>

</div>
</div>

---
layout: default
---

# Flow 1 — NAT Report Formats

<div class="grid grid-cols-2 gap-6 mt-3">
<div>

<div class="border border-blue-800 rounded-lg p-4">
<div class="text-xs font-mono text-blue-400 uppercase tracking-widest mb-2">natv2 · Nat2ParallelReport</div>

Topic: `nat2reportsysrad`

**File pattern:**
```
VODAFONE_002_TRAFIK_
  {START}_{END}_{INDEX}_{DEVICEID}.log.gz
```

**20 pipe-delimited fields:**
```
MSISDN | private_ip | private_port |
public_ip | public_port | timestamp |
duration | term_cause | dest_ip | dest_port |
IMSI | IMEI | LAC | SAC | APN |
GGSN_ip | GGSN_host | SGSN_ip | SGSN_host |
domestic_flag
```

CLOSE event → **2 lines** (one per direction)

**Destination:** `cgnuser@10.86.235.5:/CGNAT`

</div>
</div>
<div>

<div class="border border-green-800 rounded-lg p-4">
<div class="text-xs font-mono text-green-400 uppercase tracking-widest mb-2">natv3 · Nat3ParallelReport</div>

Topic: `nat2reportsysrad`

**File pattern:**
```
VODAFONE_002_TRAFIK_NAT_
  {START}_{END}_{DEVICEID}_{INDEX_PADDED}.log.gz
```

**31 pipe-delimited fields:**
```
MSISDN | APN | record_type | direction |
timestamp | duration |
src_ip | src_port | nat_ip | nat_port |
dst_ip | dst_port | [IPv6 ×4 empty] |
protocol | app_protocol | LAC |
IMEI | IMSI | bytes_up | bytes_down |
term_cause | RAT | MCCMNC | charging_id |
SGSN_ip | GGSN_ip | juniper_ip |
file_id | traffic_type=1 | ts_secs
```

**Destinations:** `BTK:/MOBIL_TRAFIK` and **LDM**

<div class="text-xs text-yellow-400 mt-2">⚠ natv3 files stage through <code>toldm/</code> dir before LDM pickup</div>
</div>

</div>
</div>

---
layout: default
---

# Flow 1 — PBA-NAT & Fixed Network

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-2">What is PBA-NAT?</div>

Instead of logging individual NAT sessions, some NAT devices assign a **fixed port block** per subscriber. The mapping is deterministic:

```
Subscriber 10.0.0.5
  → always maps to  203.0.113.12
  → always uses ports  5040 – 6047
```

A pre-generated mapping table is sufficient — no per-session logs needed.

**pbanat-calc library** computes this from `PbanatMappings.csv`:
- Per-site CIDR blocks → public IP ranges
- Port step: **1008** (mobile), **4032** (fixed)
- ordinal in CIDR → (public IP offset, portStart, portEnd)

**pbanat3 report:** MSISDN, private IP, public IP, port range, timestamps, RAT, charging ID, SGSN/GGSN, APN

**Topic:** `radresult` · **Destination:** `pbanatuser@10.86.75.15`

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Fixed network (fixgzm / fixtzl)</div>

Simpler topology — fixed network sites don't have UFDR probes:

<div class="font-mono text-slate-300 text-xs border border-slate-700 rounded p-3 mt-2">

```
FIXGZMLOGGER1 ──▶ pbanat3 ──▶ BTK ──▶ SENT
              ──▶ natv3   ──▶ esycollector ──▶ HSM
FIXGZMLOGGER2 ──▶ natv3
FIXTZLLOGGER1 ──▶ natv2
```

</div>

<div class="text-xs text-slate-400 mt-3">See <code>~/Excalidraw Whiteboard 2.png</code> for the fixed network schema.</div>

<div class="border border-slate-700 rounded p-3 mt-4 text-sm">
  <div class="text-slate-400 text-xs mb-1">KKTC (Northern Cyprus)</div>
  Special syslog variant: different regex, timestamp offset +3h UTC. Report file: <code>11784_MHH_TRAFIK_...</code>. Handled by <code>KKTCReport</code>.
</div>

</div>
</div>

---
layout: default
---

# Flow 2 — UFDR Workers

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-green-400 uppercase tracking-widest mb-2">UFDRListener / UFDRRecordHandler</div>

**Transport:** Netty NIO UDP
**Ports:** `10801-10807, 10851-10857, 10901-10907, 10951-10957`

**UFDR binary packet structure:**

```
Header (12 bytes):
  version · flags · length
  NE type · interface · module
  neID (4 bytes, identifies probe)

Per record:
  1 byte  cached/ext flag
  1 byte  type  (7=info / 8=base / 9=stats)
  2 bytes length
  2 bytes fixed fields length
  ... TLV fields
```

**Composite keys:**
```
userSessionID = (neID << 48) | sessionID
event_key     = userSessionID_flowID_transactionID
```

**Heartbeat:** type=2 → auto-ACK, no publish

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Record types & Kafka output</div>

| Type | Name | Key | Topic |
|------|------|-----|-------|
| **7** | **Info** — session context | userSessionID | `ufdr-info` |
| **8** | **Base** — session base data | event_key | `ufdr-base` |
| **9** | **Stats** — flow end metrics | event_key | `ufdr-stats` |

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-4 mb-2">Key TLV tags</div>

| Tag | Name | Content |
|-----|------|---------|
| 1 | ULI | Cell: MCC/MNC/LAC/SAC/TAC/ECI |
| 2 | Volume | uplink/downlink bytes + packets |
| 3 | Time | flowEnds, start/end (+ millis) |
| 19 | RAT | 1=UTRAN 2=GERAN 6=EUTRAN 51=NR |
| 29 | ServiceAwareness | DPI app/subapp/category |
| 30 | UserID | IMSI, IMEI, MSISDN (BCD decoded) |
| 31 | Quintuple | IPs, ports, protocol, isNAT, nat_key |
| 36 | APN | Access point name |
| 151–154 | HTTP / DNS | full request/response detail |

</div>
</div>

---
layout: default
---

# Flow 2 — Flink: Manager

<div class="text-xs font-mono text-green-400 uppercase tracking-widest mb-3">Two chained CoProcessFunctions — udn-client/manager/</div>

<div class="font-mono text-slate-300 leading-snug border border-slate-700 rounded p-3 mb-3" style="font-size:10.5px">

```
ufdr-info  (15p) ──key: userSessionID──────────────────────────────▶ InfoMatcher
                                                                           ▲
ufdr-base  (70p) ──key: event_key──▶ StatsMatcher                         │
ufdr-stats (70p) ──key: event_key──▶   base ✕ stats                       │
                                        TTL 48h ──joined record───────────┘
                                        unmatched stats ──────────────▶ ufdr-noinfo (40p)
```

</div>

<div class="grid grid-cols-2 gap-6">
<div>

**StatsMatcher** joins `ufdr-base` + `ufdr-stats` on `event_key`:
- Stats with `endFlagFlowComplete=true` + base present → emit joined record
- Otherwise buffer, 48h TTL

**InfoMatcher** joins joined stats + `ufdr-info` on `userSessionID`:
- Info with `zone != null` → **session start** → flush all buffered stats, emit enriched IPDR records
- Info with `zone == null` → **session end** → clear state
- Stats arrive + info cached → emit immediately
- Stats arrive + no info → buffer 2 min → emit to `ufdr-noinfo`

</div>
<div>

**ufdr-noinfo** → `RequestApp` (on worker1):
- Reconstructs a UFDR "info request" UDP packet
- Sends back to the original probe endpoint
- Probe returns the info record → re-enters `ufdr-info`

**State backend:** RocksDB
**Output schema:** `ufdr.avsc` — 160+ fields

The final `ufdr-nat` record contains everything:
IMSI/IMEI/MSISDN · cell location · DPI app data
NAT info · timestamps · volumes · HTTP/DNS detail

**Kafka:** `ufdr-nat` (200 partitions) · `ufdr-noinfo` (40 partitions)

</div>
</div>

---
layout: default
---

# Flow 2 — IPDR Reports

<div class="grid grid-cols-3 gap-4 mt-3">
<div>

<div class="border border-green-800 rounded-lg p-4">
<div class="text-xs font-mono text-green-400 uppercase tracking-widest mb-2">IPDRv1</div>

Topic: `ufdr-nat`
Types: **HTTP · TCP · UDP · IPP**

Separator: `0x1A` / line end: `0x1D`

**HTTP fields (sample):**
```
start | end | msisdn |
msIP | msPort |
serverIP | serverPort |
method | path | host |
referer | userAgent |
IMEI | IMSI |
requestSize | respCode |
respSize | cookie
```

Max file age: **1 min**

Destination: BTK/kurum
*(scripts exist, not yet live)*

</div>
</div>
<div>

<div class="border border-green-800 rounded-lg p-4">
<div class="text-xs font-mono text-green-400 uppercase tracking-widest mb-2">IPDRv2</div>

Topic: `ufdr-nat`
Types: **HTTP · HTTPS · SMTP · POP3 · IMAP · DNS · TCP · UDP · IPP**

Adds vs v1: TAC, Cell ID, auth, LAC/SAC/ECI, per-record
Time: `yyyy-MM-dd HH:mm:ss.SSSSSS`
Max file age: **25 min**

Destination: BTK/kurum
*(in progress)*

<div class="mt-3 border border-green-900 rounded-lg p-3">
<div class="text-xs font-mono text-slate-400 uppercase tracking-widest mb-2">nonat · NONATReport</div>

Types: **statik** / **ipv6**

`statik`: APN = `internetstatik`
`ipv6`: IPv6 address detected

Destination: **LDM**
</div>

</div>
</div>
<div>

<div class="border border-slate-700 rounded-lg p-4">
<div class="text-xs font-mono text-slate-400 uppercase tracking-widest mb-2">domain · DomainReport</div>

Topic: `ufdr-nat`

Visited domains enriched with category from `DomainMappings.csv`

```
VFTR_Domain_Tags_
  {ROLLTIME}_{DEVICEID}.txt.gz
```

Destination: **BTK**

<div class="mt-3">
<div class="text-xs font-mono text-slate-400 uppercase tracking-widest mb-1">app · AppReport</div>

Per-app usage counts, dynamic type creation from remote JSON config

```
APPCOUNT_{TYPE}_{ROLLTIME}_{HOSTID}.txt.gz
```
</div>

<div class="mt-3 text-xs text-slate-500">
<strong>Unused:</strong> <code>NATReport</code> (commented out), direct <code>nat2report</code>/<code>nat3report</code> variants replaced by parallel versions.
</div>

</div>
</div>
</div>

---
layout: default
---

# Kafka Topics Reference

<div class="grid grid-cols-2 gap-6 mt-3">
<div>

| Topic | Producer | Consumer | Partitions |
|-------|----------|----------|------------|
| `radius` | radiusclient | nat2sysrad | — |
| `syslog` | syslog worker | nat2sysrad | — |
| `ufdr-info` | ufdr worker | Manager Flink | **15** |
| `ufdr-base` | ufdr worker | Manager Flink | **70** |
| `ufdr-stats` | ufdr worker | Manager Flink | **70** |
| `ufdr-nat` | Manager Flink | IPDR loggers | **200** |
| `ufdr-noinfo` | Manager Flink | RequestApp | **40** |
| `nat2reportsysrad` | nat2sysrad | NAT loggers | — |
| `unmatchedreportsysrad` | nat2sysrad | unmatched logger | — |
| `latematchreportsysrad` | nat2sysrad | (late logger) | — |
| `radresult` | pbanat Flink | pbanat logger | — |

</div>
<div>

<div class="space-y-3 text-sm">

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs font-mono mb-1">PRODUCER CONFIG</div>

  ```yaml
  linger.ms: 5
  compression.type: lz4
  batch.size: 5 MB
  acks: 0          # fire-and-forget
  ```
</div>

<div class="border border-slate-700 rounded p-3">
  <div class="text-slate-400 text-xs font-mono mb-1">CONSUMER CONFIG</div>

  ```yaml
  max.poll.records: 10000
  fetch.max.bytes: 52 MB
  auto.offset.reset: earliest
  ```
</div>

<div class="border border-red-900 rounded p-3">
  <div class="text-red-400 text-xs font-mono mb-1">⚠ RETENTION: 5 MINUTES</div>
  Data is ephemeral. If a consumer falls behind, records are <strong>lost forever</strong>. Monitor consumer lag on every deployment and after restarts.
</div>

</div>
</div>
</div>

---
layout: default
---

# Loggers — How Report Files Are Made

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Logger instances per site</div>

| Process | Topic | Report types | Metrics |
|---------|-------|--------------|---------|
| `logger-natparallel` | nat2reportsysrad | nat2parallel, nat3parallel | :8083 |
| `logger-ipdr` | ufdr-nat | ipdrv1, ipdrv2, nonat, domain | :8080 |
| `logger-pbanat` | radresult | pbanat3 | :8084 |
| `logger-unmatched` | unmatchedreportsysrad | unmatched | — |

Each logger instance is assigned **specific partition IDs** — not all partitions:

```
ADN nat loggers:
  adnlogger1 → partitions 0-19
  adnlogger2 → partitions 20-39
ADN IPDR loggers:
  adnlogger3 → partitions 0-99
  adnlogger4 → partitions 100-199
```

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">RollWriter — file lifecycle</div>

<div class="font-mono text-slate-300 text-xs border border-slate-700 rounded p-3">

```
Kafka record
  → Reporter.generate() → List<ReportLine>
  → LinkedBlockingQueue  (async)
  → batch writer (10K records at a time)
  → live.log  (active write target)
  → roll trigger:
      size > 789 MB
      OR age  > 10 min
      OR on-the-hour (optional)
  → sortzip.sh  (external sort + gzip)
  → /opt/udn/bck/report/{logger}/{type}/
      YYYY/MM/DD/{filename}.log.gz
```

</div>

**Filename template vars:**
`{START}` `{END}` `{INDEX}` `{INDEX_PADDED}`
`{DEVICEID}` `{SITE}` `{HOSTID}` `{FILEID}` `{TYPE}`

</div>
</div>

---
layout: default
---

# File Delivery

<div class="grid grid-cols-2 gap-6 mt-3">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Safe delivery pattern (all scripts)</div>

```bash
# 1. mark in-progress
mv file.gz file.gz.tmp

# 2. upload via SFTP
sftp put file.gz.tmp
sftp rename file.gz.tmp file.gz   # atomic on remote

# 3. mark done locally
mv file.gz.tmp → sent/
```

Stuck `.tmp` files (>6h old) are auto-rotated back by `rotate()`.
All operations log to **Loki** at `10.194.11.11:3100`.
Scheduled as **systemd timers** (`.service` + `.timer` pairs).

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-4 mb-2">natv3 dual-delivery staging</div>

```
report/{logger}/natv3/  ─(BTK send)─▶  BTK
                          then moves to
                        toldm/{logger}/natv3/
                          ─(LDM send)─▶  LDM
                          then moves to
                        sent/
```

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Delivery map</div>

| Script | Source | Destination |
|--------|--------|-------------|
| `send-btk-natv3.sh` | `*/natv3/` | `10.86.235.5:/MOBIL_TRAFIK` |
| `send-natv2.sh` | `*/natv2/` | `10.86.235.5:/CGNAT` |
| `send-pbanat.sh` | `*/pbanat3/` | `10.86.75.15:/data/gsm_pban/...` |
| `send-ldm-natv3.sh` | `toldm/*/natv3/` | `ldm:/Regulasyon/ipdrlogger1/natv3/` |
| `send-ldm-nonat.sh` | `*/nonat/` | `ldm:/Regulasyon/...` |
| `send-domain.sh` | `*/domain/` | BTK |
| `send-hsm-input.sh` | `/opt/udn/bck/hsm/` | `hsm2:.../natipdr/` |
| `send-hsm-report.sh` | `*/natv{2,3}/pbanat3/nonat/` | `hsm2:.../natipdr/report/` |
| `send-fix-pbanat.sh` | fixed `*/pbanat3/` | same pbanat server |
| `send-ipdrv1-*.sh` | `*/ipdrv1/` | kurum *(not yet live)* |

BTK backup server: `10.86.235.6` (commented out, `#yedek`)

</div>
</div>

---
layout: default
---

# HSM & Offline Recovery

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-2">HSM archival</div>

**Location:** ESY site — `hsm2:/scoutfs/vftresn/10year/natipdr/`

```
natipdr/
├── (root)      ← raw input: RADIUS + syslog CSVs
└── report/
    ├── natv2/
    ├── natv3/
    ├── pbanat3/
    ├── nonat/{statik,ipv6}/
    └── notcorrolated/
```

Transfer path for mobile sites:
```
logger machines
  → /opt/udn/bck/report/
  → send-hsm-report.sh (rsync)
  → esycollector1-4
  → HSM
```

Raw syslog input file: `HSM_SYSLOG_{TYPE}_{END}_{INDEX}.log.gz`
Raw RADIUS input file: `HSM_RADIUS_...`

</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-2">udn-recovery — offline replay</div>

When outputs need regeneration (data loss, bug fix, reprocessing):

```bash
# Step 1: load RADIUS CSVs into PostgreSQL
java Main load \
  --radius-path /path/to/HSM_RADIUS_*.gz \
  --connection jdbc:postgresql://localhost/...

# Step 2: correlate + regenerate reports
java Main generate \
  --syslog-path /path/to/HSM_SYSLOG_*.gz \
  --output-path /path/to/output/

# No-DB alternative (all in RAM)
java Main generate-in-memory ...
```

**Correlation query:**
```sql
SELECT rad FROM radius
WHERE ip = ?
  AND time < ?
  AND type != 1          -- exclude Stop records
ORDER BY time DESC
LIMIT 1
```

**Skip condition:** term reason in `{1,4,7,8,9}` AND duration > 1800s

**Output:** NAT2 (20 fields, 2 lines/CLOSE) + NAT3 (31 fields)

</div>
</div>

---
layout: default
---

# Static Mapping Tables

Loaded from `src/main/resources/` at startup. Used by both loggers and udn-recovery.

<div class="grid grid-cols-2 gap-6 mt-3">
<div>

| File | Maps |
|------|------|
| `appProtocolMappings.csv` | port + protocol → service name |
| `IPPappProtocolMappings.csv` | IP protocol # (1-255) → name |
| `ApplicationMappings.csv` | DPI app/subapp ID → display name |
| `TermCauseMappings.csv` | Juniper termination code → label |
| `DomainMappings.csv` | domain → category + category code |
| `CGNATHostMappings.csv` | CGNAT gateway IP → hostname |
| `SGSNGGSNMappings.csv` | SGSN/GGSN IP → hostname |
| `DNSReqTypeMappings.csv` | DNS query type # → name |
| `PbanatMappings.csv` | site CIDR blocks → public IP + port step |

</div>
<div>

**Hardcoded in `StaticMapping.java`:**

<div class="grid grid-cols-2 gap-4 text-xs">
<div>

```java
// RAT types
0  = none
1  = UTRAN   (3G)
2  = GERAN   (2G)
6  = EUTRAN  (4G)
51 = NR      (5G)
```

```java
// HTTP methods
1=GET   2=HEAD  3=POST
4=PUT   5=DELETE 6=CONNECT
7=OPTIONS 8=PATCH
```

</div>
<div>

```java
// RADIUS field_40 type
1 = Start
2 = Stop
3 = Interim

// APN normalization
"internet" → ""  (empty in outputs)
"wttx"     → dropped
"internetstatik" → dropped
```

</div>
</div>

</div>
</div>

---
layout: default
---

# Telecom Glossary

<div class="grid grid-cols-3 gap-4 mt-3 text-sm">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Subscriber identity</div>

| Term | Meaning |
|------|---------|
| MSISDN | Phone number |
| IMSI | SIM card ID |
| IMEI | Device (handset) ID |
| MCCMNC | Network code (e.g. TR Vodafone = 28602) |

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-3 mb-2">Network nodes</div>

| Term | Meaning |
|------|---------|
| SGSN | Serving GPRS Support Node |
| GGSN | Gateway GPRS Support Node |
| NE | Network Element (probe ID) |
| APN | Access Point Name |

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Location</div>

| Term | Meaning |
|------|---------|
| LAC | Location Area Code |
| SAC | Service Area Code |
| RAC | Routing Area Code (3G) |
| TAC | Tracking Area Code (4G) |
| ECI | E-UTRAN Cell Identifier |
| CGI | Cell Global Identity |

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-3 mb-2">Radio access</div>

| Term | Meaning |
|------|---------|
| RAT | Radio Access Technology |
| GERAN | 2G (GSM/GPRS) |
| UTRAN | 3G (UMTS) |
| EUTRAN | 4G (LTE) |
| NR | 5G New Radio |

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">System / legal</div>

| Term | Meaning |
|------|---------|
| UFDR | UMTS Flow Data Record (Huawei DPI) |
| TLV | Type-Length-Value (binary encoding) |
| IPDR | IP Detail Record (report format) |
| NAT | Network Address Translation |
| PBA-NAT | Port Block Allocation NAT |
| CGNAT | Carrier-Grade NAT |
| BTK | Turkish telecom regulator |
| LDM | Lawful intercept data management |
| HSM | Long-term secure storage |
| DRC | Disaster Recovery Center |
| KKTC | Northern Cyprus (UTC+3 variant) |

</div>
</div>

---
layout: default
---

# Getting Started

<div class="grid grid-cols-2 gap-8 mt-3">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">SSH access</div>

Full SSH config in `wiki/udn/UDN_SSH_Connections.md`. Pattern: all hosts jump via `ng` (10.176.251.239:443).

```bash
# ~/.ssh/config (excerpt)
Host ng
  Hostname 10.176.251.239
  Port 443

Host adnworker1
  Hostname 10.194.10.100
  ProxyJump ng

Host adn* !adnworker1
  ProxyJump adnworker1

# then just:
ssh adnworker3
ssh psklogger2
ssh tzlflink5
```

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-4 mb-2">Repos</div>

```bash
~/proj/ng/udn-client      # main
~/proj/ng/nat2sysrad      # flow 1 flink
~/proj/ng/radiusclient    # radius probe
~/proj/ng/udn-recovery    # offline replay
~/proj/ng/pbanat-calc     # pbanat lib
```

</div>
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Key paths on servers</div>

```
/opt/udn/              main runtime
/opt/udn/service.env   site config (generated)
/opt/udn/bck/
  ├── hsm/             raw HSM input CSVs
  ├── report/          rolled report files
  ├── toldm/           natv3 staged for LDM
  └── sent/            delivered (done)
/opt/scripts/          delivery scripts
/opt/scripts/logs/     delivery logs
/mnt/flink/            Flink Kafka config files
```

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mt-4 mb-2">Useful commands</div>

```bash
# service health
systemctl status udn-ufdr udn-syslog udn-flink

# follow delivery
journalctl -u send-btk-natv3 -f

# count queued files
fdfind '.*gz$' /opt/udn/bck/report/ | wc -l

# check consumer lag (on kafka host)
kafka-consumer-groups.sh \
  --bootstrap-server 169.254.0.10:9092 \
  --describe --group udn-logger-nat

# unstick .tmp files manually
fdfind '.*\.tmp$' /opt/udn/bck/report/ \
  --changed-before 6h -x mv {} {.}
```

</div>
</div>

---
layout: center
class: text-center
---

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-8">End of onboarding</div>

<h1 class="text-5xl font-bold text-white mb-6">UDN at a glance</h1>

<div class="grid grid-cols-3 gap-5 text-left max-w-3xl mx-auto text-sm mt-4">

<div class="border border-blue-800 rounded-lg p-4">
  <div class="text-blue-400 font-mono text-xs uppercase tracking-wide mb-2">Flow 1</div>
  RADIUS + Syslog
  → nat2sysrad Flink
  → natv2 · natv3 · pbanat
  → BTK · LDM · HSM
</div>

<div class="border border-green-800 rounded-lg p-4">
  <div class="text-green-400 font-mono text-xs uppercase tracking-wide mb-2">Flow 2</div>
  UFDR (DPI binary)
  → Manager Flink
  → ipdrv1/v2 · nonat · domain
  → BTK · LDM · HSM
</div>

<div class="border border-slate-700 rounded-lg p-4">
  <div class="text-slate-400 font-mono text-xs uppercase tracking-wide mb-2">Offline</div>
  HSM raw CSVs
  → udn-recovery
  → regenerate NAT2/NAT3
  → re-deliver
</div>

</div>

<div class="mt-10 text-slate-500 text-xs font-mono">
Full reference → <code>~/Sync/vault/ng/projects/udn/udn.md</code>
</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">ngss · internal · confidential · 2026</div>
