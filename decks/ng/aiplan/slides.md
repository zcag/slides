---
title: ngss AI Systems
description: AI-powered office infrastructure on local hardware — what changes when AI is embedded across every part of how we work
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
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-4">ngss · Internal Initiative · 2026</div>
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">AI Systems</h1>
  <div class="text-2xl text-slate-300 mb-8">An AI-powered office built on local infrastructure</div>
  <div class="flex gap-6 text-sm text-slate-400">
    <span>Local LLMs on our hardware</span>
    <span>·</span>
    <span>Full data ownership</span>
    <span>·</span>
    <span>Embedded across every part of how we work</span>
  </div>
</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">2026</div>

---
layout: default
---

# The Premise

<div class="grid grid-cols-2 gap-12 mt-6">
<div>

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-3">Today</div>

<v-clicks>

- Knowledge lives in people's heads, Jira, SharePoint — disconnected
- Slow tasks aren't just slow — some don't happen at all
- Context is lost when people leave or move between projects
- Devs spend time searching, explaining, reformatting
- Production problems are caught after they happen

</v-clicks>

</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">With AI Systems</div>

<v-clicks>

- A single layer across all tools, queryable in plain language
- Tasks that were too costly to bother with become trivial
- Institutional memory is persistent and searchable
- Devs work with an expert partner that knows the whole codebase
- Production is watched, analysed, and improved continuously

</v-clicks>

</div>
</div>

---
layout: default
---

# For Developers

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-6">What the day-to-day looks like</div>

<div class="grid grid-cols-2 gap-10">
<div>

<v-clicks>

**You pick up a ticket**
Agent briefs you — relevant code, recent changes, what could break — before you write a line.

**You hit a bug**
*"Why is this user getting a 403?"* → traces auth, permissions, recent deploys. Answer in seconds, not hours.

**You open a PR**
Already reviewed before any human looks at it — risks flagged, missing tests caught, patterns checked.

</v-clicks>

</div>
<div>

<v-clicks>

**Routine tickets run themselves**
Agent team takes a well-scoped ticket from spec to PR — code, tests, docs included. You review and approve.

**Your codebase improves on its own**
Background analysis finds what no one has time to look for — performance gaps, security issues, dead code. Fix PRs opened automatically.

**A new dev joins**
Guided through the codebase, questions answered, starter tasks assigned. First two weeks without pulling senior devs away from their work.

</v-clicks>

</div>
</div>

---
layout: default
---

# Deployment Preflight

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-6">Before anything ships — a check built from your actual incident history</div>

<div class="grid grid-cols-2 gap-8">
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">What it analyzes</div>

<v-clicks>

- Code changes, migrations, config deltas, and dependency bumps in the deployment
- Downstream services affected and their known fragile points
- Test coverage on the changed paths
- Past incidents linked to similar changes

</v-clicks>

</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">What it produces</div>

<v-clicks>

- A tailored checklist for this specific deployment — not a generic template
- Gaps flagged: missing rollback plan, untested migration, env vars not propagated to all services
- Risk warnings: interdependent services deploying together, breaking change without canary strategy
- *"A similar change in Q3 caused a cascade on the auth service — verify X before proceeding"*

</v-clicks>

</div>
</div>

<v-click>
<div class="mt-6 border border-slate-700 rounded p-3 text-xs text-slate-400">
A static checklist doesn't know your system's specific failure modes. This one does — because it's read every incident you've had.
</div>
</v-click>

---
layout: default
---

# For Delivery

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-6">Visibility that actually prevents surprises</div>

<div class="grid grid-cols-2 gap-8">
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">Ask anything — in plain language</div>

<v-clicks>

- *"Who has bandwidth this week?"*
- *"Are we on track for the Q3 release?"*
- *"Which epics are trending toward delay?"*
- *"How is the Faultman rollout tracking?"*
- *"What did we actually deliver last quarter?"*

</v-clicks>

</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">Surfaced without being asked</div>

<v-clicks>

- Overloaded sprints — flagged before they start
- Blockers sitting too long without movement
- Silent scope growth as it happens
- Pattern data: *"backend tickets underestimated by ~40%"*
- Sprint reports and stakeholder updates — written automatically from raw data

</v-clicks>

</div>
</div>

<v-click>
<div class="mt-6 border border-slate-700 rounded p-3 text-xs text-slate-400">
Meetings produce decisions, action items, and Jira tickets automatically — not a recording no one watches.
</div>
</v-click>

---
layout: default
---

# Production + Institutional Memory

<div class="grid grid-cols-2 gap-8 mt-4">
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">Production that explains itself</div>

<v-clicks>

- Error spike → correlated to the deploy that caused it, not just an alert
- DB degrading over weeks → index proposed, migration opened
- Recurring incident → root cause diagnosed, runbook written
- Infrastructure drift → flagged before it pages someone

</v-clicks>

<v-click>
<div class="mt-4 border border-orange-900 border-opacity-50 rounded p-3 text-xs text-slate-300 bg-orange-950 bg-opacity-20">
<em>"Error rate on /checkout up 300% — correlates with deploy 2h ago. 3 users affected. Rollback or patch?"</em>
</div>
</v-click>

</div>
<div>

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-3">Context that doesn't walk out the door</div>

<v-clicks>

- *"Why did we decide against switching ORMs?"* → full thread with reasoning
- *"Has this bug happened before?"* → incident history across all projects
- *"What was agreed about data retention?"* → meeting, ticket, decision linked
- *"What was built beyond the original Faultman scope?"* → spec vs. delivery

</v-clicks>

<v-click>
<div class="mt-4 border border-orange-900 border-opacity-50 rounded p-3 text-xs text-slate-300 bg-orange-950 bg-opacity-20">
A person leaving doesn't mean their context leaving. A new dev joins in 6 months and gets real answers with sources.
</div>
</v-click>

</div>
</div>

---
layout: default
---

# Production Confidence

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-6">Fewer surprises. Better signal.</div>

<div class="grid grid-cols-3 gap-6">

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Config Drift Detection</div>
  <div class="text-sm text-slate-300">Continuously compares config across environments. Catches the "works in staging, broken in prod" class of incidents before users see them — env vars, feature flags, service discovery, secrets.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Post-deploy Verification</div>
  <div class="text-sm text-slate-300">After every deployment, actively exercises changed paths and checks dependent services. Not just "pod is running" — key flows tested, downstream services healthy, metrics stable.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Alert Intelligence</div>
  <div class="text-sm text-slate-300">Identifies alerts that fire constantly but never get acted on. Groups related alerts into meaningful incidents. Reduces the noise that causes real issues to be missed.</div>
</div>

</div>

<v-click>
<div class="mt-6 border border-slate-700 rounded p-3 text-xs text-slate-400">
Together: production moves from "we find out when users complain" to "we find out before it matters."
</div>
</v-click>

---
layout: default
---

# On Our Own Hardware

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-6">What that means in practice</div>

<div class="grid grid-cols-3 gap-6">

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Nothing Leaves the Building</div>
  <div class="text-sm text-slate-300">Codebase, tickets, architecture, production data — none of it goes to a cloud API. No compliance risk. No third party with access to our systems.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Always Running</div>
  <div class="text-sm text-slate-300">Agents run continuously. No rate limits, no per-query cost, no quota stopping a background workload. They work while we don't.</div>
</div>

<div v-click class="border border-slate-700 rounded-lg p-4">
  <div class="text-orange-400 font-mono text-xs uppercase tracking-wide mb-2">Gets Better Over Time</div>
  <div class="text-sm text-slate-300">Models run against our own systems and history. The longer they operate, the more accurately they understand our codebase, our incidents, our patterns.</div>
</div>

</div>

<v-click>
<div class="mt-8 border border-slate-700 rounded-lg p-4 bg-slate-900">
  <div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-2">Cost model</div>
  <div class="text-sm text-slate-300">One-time hardware investment. Run as many agents, as often, as needed — no per-query billing that scales with usage.</div>
</div>
</v-click>

---
layout: default
---

# The Compound Effect

<div class="text-xs font-mono text-slate-500 uppercase tracking-widest mb-6">Systems are most powerful when connected</div>

<div class="space-y-2 mt-4">

<div v-click class="flex items-center gap-3 text-xs font-mono">
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48 text-right">Knowledge Base</div>
  <div class="text-orange-400 text-sm">──►</div>
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48">Project Expert</div>
  <div class="text-slate-500 ml-2">history + live state in one place</div>
</div>

<div v-click class="flex items-center gap-3 text-xs font-mono">
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48 text-right">Jira Expert</div>
  <div class="text-orange-400 text-sm">──►</div>
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48">AI Dev Team</div>
  <div class="text-slate-500 ml-2">well-scoped tickets → better output</div>
</div>

<div v-click class="flex items-center gap-3 text-xs font-mono">
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48 text-right">Code Quality Agent</div>
  <div class="text-orange-400 text-sm">──►</div>
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48">PR Review</div>
  <div class="text-slate-500 ml-2">flags become review criteria</div>
</div>

<div v-click class="flex items-center gap-3 text-xs font-mono">
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48 text-right">System Quality Agent</div>
  <div class="text-orange-400 text-sm">──►</div>
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48">Incident Agent</div>
  <div class="text-slate-500 ml-2">prod baseline → anomaly detection</div>
</div>

<div v-click class="flex items-center gap-3 text-xs font-mono">
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48 text-right">Incident Agent</div>
  <div class="text-orange-400 text-sm">──►</div>
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48">Project Expert</div>
  <div class="text-slate-500 ml-2">runtime context for debugging</div>
</div>

<div v-click class="flex items-center gap-3 text-xs font-mono">
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48 text-right">Meeting Agent</div>
  <div class="text-orange-400 text-sm">──►</div>
  <div class="border border-slate-700 rounded px-3 py-1.5 text-slate-300 w-48">Knowledge Base</div>
  <div class="text-slate-500 ml-2">decisions captured automatically</div>
</div>

</div>

<v-click>
<div class="mt-6 border border-orange-900 border-opacity-40 rounded-lg p-4 bg-orange-950 bg-opacity-20">
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-2">The closed loop</div>
  <div class="text-sm text-slate-300">
    Jira Expert detects a delivery risk → opens a ticket → AI Dev Team picks it up → implements → PR Review catches issues → merges → Knowledge Base records the decision. A human is involved at the approval points. Not the grunt work.
  </div>
</div>
</v-click>

---
layout: default
---

# How We Get There

<div class="mt-4">

| Phase | Focus | Why first |
|-------|---------|-----------|
| **1** | Knowledge Base · Project Expert | Foundation — every other system benefits from shared context |
| **2** | PR & Review Intelligence | Immediate daily value for devs, lowest risk to start |
| **3** | Jira Expert | High value for PM and team lead, builds on existing data |
| **4** | Code Quality Agent | Needs codebase context established first |
| **5** | System Quality Agent | Needs baseline metrics and log visibility |
| **6** | AI Dev Team | Most complex — needs all other layers stable |
| **7** | Incident · Onboarding · Standup | Operational layer, layer in once core is running |

</div>

<v-click>
<div class="mt-4 text-xs text-slate-500">
Each phase delivers standalone value. This is a priority order, not a dependency chain — any phase can start independently.
</div>
</v-click>

---
layout: center
class: text-center
---

<div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-6">The constraint shifts</div>

<h2 class="text-4xl font-bold text-white mb-6 leading-tight">
  From <span class="text-slate-500">can we do this?</span><br>
  to <span class="text-orange-400">do we want to do this?</span>
</h2>

<div class="text-slate-400 text-lg max-w-xl mx-auto">
  Tasks that were impossible or required too much coordination to bother with become trivially initiatable.
</div>

<v-click>
<div class="mt-8 border border-orange-800 border-opacity-50 rounded-lg px-8 py-3 bg-orange-950 bg-opacity-20 inline-block">
  <div class="text-xs font-mono text-orange-400 uppercase tracking-widest mb-1">Where to start</div>
  <div class="text-sm text-slate-300">Phase 1 · Knowledge Base + Project Expert · first value in two weeks</div>
</div>
</v-click>

<div class="mt-6 text-xs text-slate-600 font-mono">All systems run on our hardware · Local LLMs · Data stays in-house</div>
