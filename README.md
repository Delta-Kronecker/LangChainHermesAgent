# LangChain Engineering Team on Hermes Agent

An architecture, delegation framework, and role-based multi-profile agent system built on [Hermes Agent](https://hermes-agent.nousresearch.com/docs).

## Overview

This repository contains the complete specification, role definition profiles (`SOUL.md`), delegation configuration, and operational standards for a 7-profile specialized LangChain engineering team inside Hermes Agent.

### Team Topology

- **`langchain-engineer`** — Central Lead Architect & Manager (sole orchestrator using `profile_routes`).
- **`langchain-specialist`** — Core LangChain abstractions, tools, runnables, structured output, and middleware.
- **`langgraph-specialist`** — Stateful workflows, `StateGraph` design, reducers, interrupts (HITL), and persistence.
- **`agent-systems-specialist`** — Deep Agents architecture, planning loops, and multi-agent memory.
- **`rag-specialist`** — Document ingestion, text splitters, vector stores, hybrid search, and grounded citations.
- **`evaluation-specialist`** — Benchmark datasets, LLM-as-judge rubrics, and LangSmith trace diagnosis.
- **`production-specialist`** — API packaging, test infrastructure, security threat modeling, and release readiness.

## Repository Contents

```text
.
├── LANGCHAIN_HERMES_AGENT_MASTER.md   # Master specification and architectural blueprint
├── README.md                           # Project overview
└── roles/                              # Per-profile SOUL.md system prompts
    ├── langchain-engineer.md           # Manager role charter & delegation contract
    ├── langchain-specialist.md         # LangChain specialist charter
    ├── langgraph-specialist.md         # LangGraph specialist charter
    ├── agent-systems-specialist.md     # Agent Systems specialist charter
    ├── rag-specialist.md               # RAG specialist charter
    ├── evaluation-specialist.md        # Evaluation specialist charter
    └── production-specialist.md        # Production specialist charter
```

## Key Architectural Principles

1. **Single Orchestrator:** Only `langchain-engineer` invokes `delegate_task`.
2. **Leaf Specialists:** All 6 specialists act as leaf agents with `delegation` tool disabled.
3. **`profile_routes` Backend:** Delegates tasks to independent Hermes profiles preserving individual identity, skills, and constraints.
4. **Least-Privilege Tool Access:** Skills and capabilities are strictly role-scoped.
5. **Evidence-Based Verification:** Every task handoff requires real tool execution evidence.

## License

MIT
