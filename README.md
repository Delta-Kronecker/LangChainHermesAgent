# LangChain Engineering System for Hermes Agent

A complete, production-ready multi-agent engineering system built on [Hermes Agent](https://hermes-agent.nousresearch.com/docs) (**v0.23.2+**, `2026.9.24` stable).

This repository contains the full specification, automated setup scripts, role charters (`SOUL.md`), skill mapping (with upstream links), runtime model configuration, and delegation/kanban configuration required to deploy a **7-profile specialized LangChain engineering team**.

---

## ⚡ Quick Start

```bash
git clone https://github.com/Delta-Kronecker/LangChainHermesAgent.git
cd LangChainHermesAgent
```

- **Linux/macOS:** `chmod +x setup.sh && ./setup.sh`
- **Windows (PowerShell):** `./setup.ps1`

The script creates the 7 isolated profiles, deploys `SOUL.md`, copies approved skills, configures delegation (kanban + optional `profile_routes`), disables delegation on leaf specialists, wires the local web-search gateway plugin, and sets the runtime model.

---

## 1. System Architecture & Team Topology

**Central Manager + 6 Leaf Specialists.**

```text
                            USER
                             |
                             v
               +---------------------------+
               |     langchain-engineer    |
               | (Lead Architect / Manager) |
               +-------------+-------------+
                             |
          kanban_create (primary) | delegate_task / profile_routes (optional)
                             |
    +----------+----------+--+-------+----------+----------+
    v          v          v          v          v          v
 langchain  langgraph  agent-      rag       evaluation  production
 -specialist -specialist systems-   -specialist -specialist -specialist
                        specialist
```

- **Primary delegation channel:** the shared **Kanban board** — manager calls `kanban_create(assignee=...)`; the dispatcher spawns the assignee profile.
- **Optional inline delegation:** `delegate_task` via the `advanced-delegation` plugin's `profile_routes` backend.
- **Leaf policy:** all six specialists have the `delegation` toolset **disabled**; they report only through the Kanban board.

### Role Charters

| Profile | Role Name | Mission / Domain Scope |
|---|---|---|
| `langchain-engineer` | Lead Architect & Manager | Orchestration, task decomposition, interface contracts, quality gates, final integration. |
| `langchain-specialist` | LangChain Engineer | Core abstractions, runnables, prompts, tools, structured output, middleware, dependency pinning. |
| `langgraph-specialist` | LangGraph Engineer | `StateGraph`, state schemas, reducers, `Command`/`Send`, interrupts (HITL), checkpointing, `langgraph-cli`. |
| `agent-systems-specialist` | Agent Systems Engineer | Deep Agents (`create_deep_agent`), planning (`TodoList`), memory backends, application-level multi-agent topology. |
| `rag-specialist` | RAG Engineer | Ingestion, chunking, embeddings, vector stores (Chroma/FAISS/Pinecone), hybrid retrieval, reranking, citations. |
| `evaluation-specialist` | Evaluation Engineer | Datasets/benchmarks, LLM-as-judge rubrics, offline/online evals, LangSmith experiment & trace diagnosis. |
| `production-specialist` | Production Engineer | API packaging, test infra, security threat modeling & secrets policy, observability, release readiness (L3 gate). |

---

## 2. Runtime & Model Configuration

All seven profiles share one runtime model/provider (each `profiles/<profile>/config.yaml`):

```yaml
model:
  default: tokenharbor/deepseek-v4.1-flash:free
  api_mode: chat_completions
  provider: 9router
  base_url: http://localhost:20128/v1
  key_env: HERMES_CUSTOM_9ROUTER_API_KEY
```

| Field | Value |
|---|---|
| Runtime | Hermes Agent **v0.23.2** (2026.9.24), install `git` |
| Model | `tokenharbor/deepseek-v4.1-flash:free` |
| Provider | `9router` (custom, OpenAI-compatible) — `http://localhost:20128/v1`, `chat_completions` |
| Key | `HERMES_CUSTOM_9ROUTER_API_KEY` (only in `.env`, never committed) |

> **Model configuration is user-managed.** Do not hardcode/change models from a role. Change `model.default` in each profile config (or `/model` in a session).
> **Per-task pinning:** `kanban_create(..., model="tokenharbor/deepseek-v4.1-flash:free", provider="9router")`.

---

## 3. Approved Skills (verified, with upstream links)

Skills are installed **only** from the official LangChain team repository. Verify any profile: `hermes -p <profile> skills list`.

### 3.1 Currently installed, per profile

| Profile | Skill | Link |
|---|---|---|
| `langchain-engineer` | `ecosystem-primer` | internal (Hermes profile skill; orchestration primer) |
| `langchain-specialist` | `langchain-dependencies` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `langchain-fundamentals` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `langchain-middleware` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| `langgraph-specialist` | `langgraph-cli` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `langgraph-fundamentals` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `langgraph-human-in-the-loop` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| `agent-systems-specialist` | `deep-agents-core` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `deep-agents-memory` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `deep-agents-orchestration` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| `rag-specialist` | `langchain-rag` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| `evaluation-specialist` | `eval-engineering` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `langsmith-experiment-diagnosis` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| | `langsmith-online-eval-engineering` | [repo](https://github.com/langchain-ai/langchain-skills) *(legacy layout)* |
| `production-specialist` | `langchain-agent-monitoring` | [skills/langchain-agent-monitoring](https://github.com/langchain-ai/langchain-skills/tree/main/skills/langchain-agent-monitoring) |
| | `langchain-agent-tracing` | [skills/langchain-agent-tracing](https://github.com/langchain-ai/langchain-skills/tree/main/skills/langchain-agent-tracing) |

> "Legacy layout" = the skill was installed from an earlier version of `langchain-ai/langchain-skills` (under `config/skills/`). It is **no longer present at `main`**; the file exists only in the local profile. To migrate, use the current 4-skill set below.

### 3.2 Current official set (`langchain-ai/langchain-skills`, 4 skills)

These replace the older smaller skills and are all present at `main` (verified HTTP 200):

| Skill | Link | Purpose |
|---|---|---|
| `langchain-build-agent` | [skills/langchain-build-agent](https://github.com/langchain-ai/langchain-skills/tree/main/skills/langchain-build-agent) | Build/modify LLM apps with Deep Agents, LangGraph, LangChain; how the layers fit; when Managed Deep Agents fits. |
| `langchain-eval-engineering` | [skills/langchain-eval-engineering](https://github.com/langchain-ai/langchain-skills/tree/main/skills/langchain-eval-engineering) | Eval/benchmark engineering: Task Specs, Harbor tasks, environments, synthetic data, verifiers, calibration. |
| `langchain-agent-monitoring` | [skills/langchain-agent-monitoring](https://github.com/langchain-ai/langchain-skills/tree/main/skills/langchain-agent-monitoring) | **Production** monitoring: quality signals, online evaluators, alerts, review queues, failure analysis. |
| `langchain-agent-tracing` | [skills/langchain-agent-tracing](https://github.com/langchain-ai/langchain-skills/tree/main/skills/langchain-agent-tracing) | LangSmith tracing: instrumentation, threads, metadata, sampling, **sensitive-data redaction**, distributed tracing. |

### 3.3 Recommended mapping of the current 4 skills

| Profile | Recommended current skill(s) |
|---|---|
| `langchain-specialist` | `langchain-build-agent` |
| `langgraph-specialist` | `langchain-build-agent` |
| `agent-systems-specialist` | `langchain-build-agent` |
| `rag-specialist` | `langchain-build-agent` (retrieval is part of LangChain app building) |
| `evaluation-specialist` | `langchain-eval-engineering` (+ `langchain-agent-monitoring`) |
| `production-specialist` | `langchain-agent-monitoring`, `langchain-agent-tracing` (installed) |

Install from a clone of the official repo:
```bash
git clone --depth 1 https://github.com/langchain-ai/langchain-skills.git
cp -r langchain-skills/skills/langchain-build-agent "$HERMES_PROFILES/langchain-specialist/skills/"
# repeat per profile mapping above
```

### 3.4 Excluded skills (security)

`langsmith-trace`, `langsmith-dataset`, `langsmith-evaluator`, `langgraph-persistence` — excluded. Use approved skills + official docs.

---

## 4. Web Search via the Local Gateway (`localgw-web` plugin)

The gateway at `http://localhost:20128` exposes `POST /v1/search` which **requires** a `provider` (or `model`) field. No built-in Hermes web provider sends that field, so this system ships the `localgw-web` provider plugin and pins `web.search_backend: localgw` on every profile.

```http
POST http://localhost:20128/v1/search
Authorization: Bearer $HERMES_CUSTOM_9ROUTER_API_KEY
Content-Type: application/json

{"provider":"tavily","query":"...","search_type":"web","max_results":5}
```
=> HTTP 200 in ~2-5 s with `{"results":[{"title","url","snippet",...}]}`.

**Plugin layout (per profile):** `profiles/<profile>/plugins/localgw-web/` — `provider.py` (class `LocalGatewayWebSearchProvider`, `NAME="localgw"`), `__init__.py` (`register(ctx)`), `plugin.yaml`.

```bash
hermes -p <profile> plugins enable localgw-web --no-allow-tool-override
hermes -p <profile> config set web.search_backend localgw
```
**Env overrides:** `LOCALGW_BASE_URL`, `LOCALGW_API_KEY`, `LOCALGW_PROVIDER` (default `tavily`).
> `web_extract` is not routed through the gateway; extend `extract()` if a fetch route exists.

---

## 5. Delegation & Orchestration

### 5.1 Kanban (primary)
```python
kanban_create(title="<objective>", assignee="<specialist>", body="<task contract>", priority=10)
```
Monitor with `kanban_list`/`kanban_show`; workers comment + complete. Never recreate a card that is done.

### 5.2 `profile_routes` (optional, manager only)
```yaml
delegation:
  backend: profile_routes
  backends:
    profile_routes:
      langchain-specialist:     { profile: langchain-specialist,     description: "LangChain Engineer ..." }
      langgraph-specialist:     { profile: langgraph-specialist,     description: "LangGraph Engineer ..." }
      agent-systems-specialist: { profile: agent-systems-specialist, description: "Agent Systems Engineer ..." }
      rag-specialist:           { profile: rag-specialist,           description: "RAG Engineer ..." }
      evaluation-specialist:    { profile: evaluation-specialist,    description: "Evaluation Engineer ..." }
      production-specialist:    { profile: production-specialist,    description: "Production Engineer ..." }
```

### 5.3 Task contract (every delegation)
```text
TASK / CONTEXT / SCOPE / OUT OF SCOPE / CONSTRAINTS / EXPECTED OUTPUT /
ACCEPTANCE CRITERIA / DEPENDENCIES / RISKS / VERIFICATION / HANDOFF
```

### 5.4 Leaf enforcement
```bash
for p in langchain-specialist langgraph-specialist agent-systems-specialist rag-specialist evaluation-specialist production-specialist; do
  hermes -p "$p" tools disable delegation
done
```

---

## 6. Tools & Toolsets

**39 reachable tools = 32 in-schema + 7 deferred** per profile:

| Group | Tools |
|---|---|
| File (4) | `read_file`, `write_file`, `patch`, `search_files` |
| Exec (2) | `terminal`, `execute_code` |
| Web (3) | `web_search` (-> localgw), `web_extract`, `browser_exec` |
| Skills/Memory (4) | `skills_list`, `skill_view`, `skill_manage`, `memory` |
| Kanban (12) | `kanban_show/create/comment/complete/block/link/heartbeat/attach/attach_url/attachments/request_review/request_changes` |
| Misc (6) | `vision_analyze`, `text_to_speech`, `manage_connections`, `clarify` |
| Deferred gateway (3) | `tool_search`, `tool_describe`, `tool_call` |
| Deferred tools (7) | `browser_vault`, `computer_use`, `cronjob_manage`, `kanban_schedule`, `process_manage`, `session_search`, `todo_list` |

`delegation` is enabled **only** on `langchain-engineer`.

---

## 7. Manual Installation

1. **Plugin (optional):** `hermes plugins install advanced-delegation --enable --yes-deps`
2. **Create profiles:**
```bash
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer
hermes profile create --no-skills --description "LangChain Engineer for core abstractions, tools, runnables, and middleware" langchain-specialist
hermes profile create --no-skills --description "LangGraph Engineer for stateful workflows, state schemas, and checkpointing" langgraph-specialist
hermes profile create --no-skills --description "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems" agent-systems-specialist
hermes profile create --no-skills --description "RAG Engineer for ingestion, vector search, reranking, and grounded citations" rag-specialist
hermes profile create --no-skills --description "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics" evaluation-specialist
hermes profile create --no-skills --description "Production Engineer for API integration, security review, test infra, and release readiness" production-specialist
```
3. **Set the model** (Section 2) in each `config.yaml`; put `HERMES_CUSTOM_9ROUTER_API_KEY` in each `.env`.
4. **Deploy SOUL.md:** `cp roles/<profile>.md "$HERMES_PROFILES/<profile>/SOUL.md"`
5. **Install skills** (Section 3) — from the official repo / `$HOME/AppData/Local/hermes/skills`.
6. **Web search** (Section 4) — add `plugins/localgw-web/`, enable, set `web.search_backend=localgw`.
7. **Delegation** (Section 5) — manager `profile_routes` (optional) + leaf enforcement.

---

## 8. Verification

```bash
for p in langchain-engineer langchain-specialist langgraph-specialist agent-systems-specialist rag-specialist evaluation-specialist production-specialist; do
  echo "== $p"; hermes -p "$p" skills list; hermes -p "$p" config get web.search_backend; hermes -p "$p" plugins list | grep -i localgw
done

# Web search end-to-end
hermes -p production-specialist chat -q "Call web_search once for 'LangGraph human in the loop' limit 2; reply only titles+urls."

# Delegation workflow
hermes -p langchain-engineer -z "Delegate to langchain-specialist to list its available skills and confirm its scope."
```

---

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `web_search` -> `SSL: UNEXPECTED_EOF` / keyless rescue failed | Hit `api.perplexity.ai` / `api.keenable.ai` directly | Ensure `web.search_backend=localgw` + plugin enabled (Section 4). |
| `POST /v1/search` -> 400 `Missing required field: provider (or model)` | Body lacked `provider`/`model` | `localgw-web` sends `provider:"tavily"`; add it for manual calls. |
| `POST /v1/search` -> 401 | Bad/missing bearer | Use `HERMES_CUSTOM_9ROUTER_API_KEY`. |
| `tool_search` hangs -> fails after **420 s** | `420 s` = outer tool deadline (`_DEFAULT_CONCURRENT_TOOL_TIMEOUT_S`); the hang came from the **missing web-search route** that catalog/availability probes touched. | Add `/v1/search` to the gateway (or keep `localgw`); prefer `tool_describe` with explicit names. |
| Specialist spawned, no report | Crash on provider/model, or very long free-tier latency | `kanban_show <id>`; free-tier single calls can take minutes. |
| Duplicate/stale cards | Repeated retries | `hermes kanban complete --force --summary "..." <id>` |

---

## 10. Repository Structure

```text
.
├── .gitignore
├── README.md              # this file
├── CHANGELOG.md           # dated record of system changes
├── setup.sh / setup.ps1   # automated installers
└── roles/                 # SOUL.md system prompts
    ├── langchain-engineer.md
    ├── langchain-specialist.md
    ├── langgraph-specialist.md
    ├── agent-systems-specialist.md
    ├── rag-specialist.md
    ├── evaluation-specialist.md
    └── production-specialist.md
```

Per-profile runtime artifacts (not in repo): `profiles/<p>/config.yaml`, `.env`, `SOUL.md`, `skills/`, `plugins/localgw-web/`.

---

## License

MIT