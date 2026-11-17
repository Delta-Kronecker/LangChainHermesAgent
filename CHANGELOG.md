# Changelog

All notable changes to the LangChain Engineering System specification.
This file records **runtime-relevant** changes so a fresh deploy reproduces the current environment.

---

## [2026-11-17] — Runtime hardening, local web search, skills refresh

### Runtime
- Target runtime updated to **Hermes Agent v0.23.2** (`2026.9.24` stable, install `git`).
- All seven profiles pinned to one runtime model:
  - `model.default: tokenharbor/deepseek-v4.1-flash:free`
  - `provider: 9router`, `base_url: http://localhost:20128/v1`, `api_mode: chat_completions`
  - key via `HERMES_CUSTOM_9ROUTER_API_KEY` (per-profile `.env`)
- Per-task model pinning documented: `kanban_create(..., model=..., provider=...)`.

### Web search → local gateway (`localgw-web`)
- **Root cause of agent web-search failures:** the gateway's `/v1/search` route was missing; the tool fell through to `api.perplexity.ai` / `api.keenable.ai` and failed with `SSL: UNEXPECTED_EOF_WHILE_READING`.
- **Fix:** added the gateway `/v1/search` route and shipped a custom provider plugin `localgw-web` on all 7 profiles (`web.search_backend: localgw`).
- Plugin POSTs `{provider:"tavily", query, search_type:"web", max_results}` to `http://localhost:20128/v1/search` with `Authorization: Bearer $HERMES_CUSTOM_9ROUTER_API_KEY`.
- Verified end-to-end: `langchain-engineer` 4.9 s, `production-specialist` 4.3 s, real results.
- Gateway requires `provider`/`model` in the body (this is why built-in providers cannot be used directly).

### `tool_search` 420 s hang
- The `420 s` figure is the **outer tool deadline** (`agent/tool_executor.py::_DEFAULT_CONCURRENT_TOOL_TIMEOUT_S`), not an internal cap.
- Measured with `connectors.enabled=false`: still 235 s, so connectors/Nous-portal probe was **not** the cause.
- Actual cause: the unavailable web-search route that `tool_search`'s catalog/availability path touched. Adding `/v1/search` (above) resolves it.
- Operational guidance: prefer `tool_describe` with explicit names over `tool_search` in unattended runs.

### Skills
- Anchored to the official repo `langchain-ai/langchain-skills` (current 4-skill set: `langchain-build-agent`, `langchain-eval-engineering`, `langchain-agent-monitoring`, `langchain-agent-tracing`).
- `production-specialist` gained its first domain skills: **`langchain-agent-monitoring`** + **`langchain-agent-tracing`** (previously only the generic `hermes-agent`).
- Per-profile skill inventory recorded in `README.md §3` and each role charter (§6).

### Delegation
- Documented the **Kanban board** (`kanban_create` → dispatcher → assignee profile) as the **primary** delegation channel.
- `delegate_task` + `profile_routes` retained as an optional inline path (manager only).
- Leaf policy confirmed: `delegation` toolset disabled on all six specialists.

### Verification added
- Per-agent capability inventory (self-audit) run against all six specialists: identity, model/provider, skills, ~39 reachable tools (32 in-schema + 7 deferred), leaf confirmation.
- `evaluation-specialist` previously crashed on the old mis-configured model (`cl/google/gemini-3.6-flash`); now runs correctly on the pinned model.

---

## [2026-11-07] — Initial specification
- 7-profile architecture (manager + 6 leaf specialists), role charters, 14-skill mapping, `advanced-delegation` `profile_routes`, and automated `setup.sh` / `setup.ps1` installers.