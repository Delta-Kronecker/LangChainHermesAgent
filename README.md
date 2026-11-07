# LangChain Engineering System for Hermes Agent

A complete, production-ready multi-agent engineering system built on [Hermes Agent](https://hermes-agent.nousresearch.com/docs) (`v0.22.7`+).

This repository provides the complete automated setup scripts, role definitions (`SOUL.md`), skill mapping, and delegation configuration to deploy a 7-agent specialized LangChain engineering team.

---

## ⚡ Quick Start (One-Command Automated Installation)

Clone this repository and run the automated setup script for your platform:

### Linux / macOS
```bash
git clone https://github.com/Delta-Kronecker/LangChainHermesAgent.git
cd LangChainHermesAgent
chmod +x setup.sh
./setup.sh
```

### Windows (PowerShell)
```powershell
git clone https://github.com/Delta-Kronecker/LangChainHermesAgent.git
cd LangChainHermesAgent
.\setup.ps1
```

The automated script performs all 6 setup stages: installs `advanced-delegation`, creates the 7 profiles, deploys system prompts (`SOUL.md`), copies approved skills, configures `profile_routes` on the manager, and disables delegation on leaf specialists.

---

## 1. System Architecture & Team Topology

The system uses a **Central Manager + 6 Leaf Specialists** architecture:

```text
                            USER
                             |
                             v
               +---------------------------+
               |     langchain-engineer    |
               | (Lead Architect / Manager) |
               +-------------+-------------+
                             |
                  delegate_task (profile_routes)
                             |
    +----------+----------+--+-------+----------+----------+
    |          |          |          |          |          |
    v          v          v          v          v          v
+-------+  +-------+  +-------+  +-------+  +-------+  +-------+
|lang-  |  |lang-  |  |agent- |  | rag-  |  |evalua-|  |produc-|
|chain- |  |graph- |  |systems|  |speci- |  |speci- |  |speci- |
|speci- |  |speci- |  |-speci-|  |alist  |  |speci- |  |speci- |
|alist  |  |alist  |  |alist  |  |       |  |alist  |  |alist  |
+-------+  +-------+  +-------+  +-------+  +-------+  +-------+
```

### Role Charters

| Profile | Role Name | Mission / Domain Scope |
|---|---|---|
| `langchain-engineer` | Lead Architect & Manager | Central orchestrator, task decomposition, interface design, quality gates, and final integration. |
| `langchain-specialist` | LangChain Engineer | Core abstractions, runnables, prompts, tools, structured output, and middleware. |
| `langgraph-specialist` | LangGraph Engineer | Stateful `StateGraph` workflows, state schemas, reducers, interrupts (HITL), and persistence. |
| `agent-systems-specialist` | Agent Systems Engineer | Deep Agents, planning loops (`TodoList`), memory backends (`StateBackend`/`StoreBackend`), and multi-agent systems. |
| `rag-specialist` | RAG Engineer | Document ingestion, text chunking, vector stores, hybrid search, reranking, and citation grounding. |
| `evaluation-specialist` | Evaluation Engineer | Benchmark datasets, LLM-as-judge rubrics, offline/online evals, and LangSmith trace diagnosis. |
| `production-specialist` | Production Engineer | REST APIs, test infrastructure, security threat modeling, secrets policy, and release readiness. |

---

## 2. Approved Skills Catalogue

The system uses **14 approved and verified skills** from official sources (`langchain-ai/langchain-skills` and `langchain-ai/langsmith-skills`), mapped strictly by role:

| # | Skill Name | Assigned Profile | Purpose & Scope |
|---|---|---|---|
| 1 | `ecosystem-primer` | `langchain-engineer` | High-level ecosystem mapping for task routing and framework selection. |
| 2 | `langchain-fundamentals` | `langchain-specialist` | Core LangChain abstractions, `create_agent`, runnables, and tool schemas. |
| 3 | `langchain-middleware` | `langchain-specialist` | Execution hooks, `HumanInTheLoopMiddleware`, and structured output schemas. |
| 4 | `langchain-dependencies` | `langchain-specialist` | Package compatibility, minimum versions, and lockfile management. |
| 5 | `langgraph-fundamentals` | `langgraph-specialist` | `StateGraph`, node functions, edge routing, reducers, and state updates. |
| 6 | `langgraph-human-in-the-loop` | `langgraph-specialist` | `interrupt()`, `Command(resume=...)`, and human approval workflows. |
| 7 | `langgraph-cli` | `langgraph-specialist` | `langgraph.json` configuration, `langgraph dev`, and deployment scaffolding. |
| 8 | `deep-agents-core` | `agent-systems-specialist` | `create_deep_agent()`, harness architecture, and configuration options. |
| 9 | `deep-agents-orchestration` | `agent-systems-specialist` | Subagent planning loops (`SubAgentMiddleware`, `TodoList`) in user applications. |
| 10 | `deep-agents-memory` | `agent-systems-specialist` | `StateBackend`, `StoreBackend`, and long-term agent memory composition. |
| 11 | `langchain-rag` | `rag-specialist` | Text splitters, embeddings, vector databases (Chroma, FAISS, Pinecone), and reranking. |
| 12 | `eval-engineering` | `evaluation-specialist` | Dataset generation, test case rubrics, and LLM-as-judge calibration. |
| 13 | `langsmith-experiment-diagnosis` | `evaluation-specialist` | Diagnosing failed runs, experiment analysis, and trace-level debugging. |
| 14 | `langsmith-online-eval-engineering` | `evaluation-specialist` | Production trace evaluators, thread rules, sampling, and online monitoring. |

> **Security Note:** Unreviewed community skills and skills with critical security findings (`langsmith-trace`, `langsmith-dataset`, `langsmith-evaluator`, and `langgraph-persistence`) are explicitly excluded.

---

## 3. Step-by-Step Installation & Setup Guide

Follow these steps to recreate and deploy the entire 7-agent team from scratch.

### Step 3.1: Install `advanced-delegation` Plugin

Install the official `advanced-delegation` plugin (v1.1.1+) to enable profile routing:

```bash
hermes plugins install advanced-delegation --enable --yes-deps
```

### Step 3.2: Create the 7 Independent Profiles

Create clean, isolated Hermes profiles without bundled skills or inherited credentials:

```bash
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer
hermes profile create --no-skills --description "LangChain Engineer for core abstractions, tools, runnables, and middleware" langchain-specialist
hermes profile create --no-skills --description "LangGraph Engineer for stateful workflows, state schemas, and checkpointing" langgraph-specialist
hermes profile create --no-skills --description "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems" agent-systems-specialist
hermes profile create --no-skills --description "RAG Engineer for ingestion, vector search, reranking, and grounded citations" rag-specialist
hermes profile create --no-skills --description "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics" evaluation-specialist
hermes profile create --no-skills --description "Production Engineer for API integration, security review, test infra, and release readiness" production-specialist
```

### Step 3.3: Deploy Role Charters (`SOUL.md`)

Copy the system prompts from `roles/` to each profile's directory:

```bash
HERMES_PROFILES="$HOME/AppData/Local/hermes/profiles"  # On Windows MSYS / Git Bash
# For Linux/macOS use: HERMES_PROFILES="$HOME/.local/share/hermes/profiles"

cp roles/langchain-engineer.md        "$HERMES_PROFILES/langchain-engineer/SOUL.md"
cp roles/langchain-specialist.md      "$HERMES_PROFILES/langchain-specialist/SOUL.md"
cp roles/langgraph-specialist.md      "$HERMES_PROFILES/langgraph-specialist/SOUL.md"
cp roles/agent-systems-specialist.md  "$HERMES_PROFILES/agent-systems-specialist/SOUL.md"
cp roles/rag-specialist.md            "$HERMES_PROFILES/rag-specialist/SOUL.md"
cp roles/evaluation-specialist.md     "$HERMES_PROFILES/evaluation-specialist/SOUL.md"
cp roles/production-specialist.md     "$HERMES_PROFILES/production-specialist/SOUL.md"
```

### Step 3.4: Install & Assign Approved Skills

Copy the approved skills into the respective profile skill directories:

```bash
GLOBAL_SKILLS="$HOME/AppData/Local/hermes/skills"

# Manager
cp -r "$GLOBAL_SKILLS/ecosystem-primer" "$HERMES_PROFILES/langchain-engineer/skills/"

# LangChain Specialist
cp -r "$GLOBAL_SKILLS/langchain-fundamentals" "$HERMES_PROFILES/langchain-specialist/skills/"
cp -r "$GLOBAL_SKILLS/langchain-middleware"   "$HERMES_PROFILES/langchain-specialist/skills/"
cp -r "$GLOBAL_SKILLS/langchain-dependencies" "$HERMES_PROFILES/langchain-specialist/skills/"

# LangGraph Specialist
cp -r "$GLOBAL_SKILLS/langgraph-fundamentals"     "$HERMES_PROFILES/langgraph-specialist/skills/"
cp -r "$GLOBAL_SKILLS/langgraph-human-in-the-loop" "$HERMES_PROFILES/langgraph-specialist/skills/"
cp -r "$GLOBAL_SKILLS/langgraph-cli"              "$HERMES_PROFILES/langgraph-specialist/skills/"

# Agent Systems Specialist
cp -r "$GLOBAL_SKILLS/deep-agents-core"          "$HERMES_PROFILES/agent-systems-specialist/skills/"
cp -r "$GLOBAL_SKILLS/deep-agents-orchestration" "$HERMES_PROFILES/agent-systems-specialist/skills/"
cp -r "$GLOBAL_SKILLS/deep-agents-memory"        "$HERMES_PROFILES/agent-systems-specialist/skills/"

# RAG Specialist
cp -r "$GLOBAL_SKILLS/langchain-rag" "$HERMES_PROFILES/rag-specialist/skills/"

# Evaluation Specialist
cp -r "$GLOBAL_SKILLS/eval-engineering"                    "$HERMES_PROFILES/evaluation-specialist/skills/"
cp -r "$GLOBAL_SKILLS/langsmith-experiment-diagnosis"     "$HERMES_PROFILES/evaluation-specialist/skills/"
cp -r "$GLOBAL_SKILLS/langsmith-online-eval-engineering" "$HERMES_PROFILES/evaluation-specialist/skills/"
```

### Step 3.5: Configure Manager Profile Routing

Add the `profile_routes` delegation block to `$HERMES_PROFILES/langchain-engineer/config.yaml`:

```yaml
delegation:
  backend: profile_routes
  backends:
    profile_routes:
      langchain-specialist:
        profile: langchain-specialist
        description: "LangChain Engineer for core abstractions, tools, runnables, and middleware"
      langgraph-specialist:
        profile: langgraph-specialist
        description: "LangGraph Engineer for stateful workflows, state schemas, and checkpointing"
      agent-systems-specialist:
        profile: agent-systems-specialist
        description: "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems"
      rag-specialist:
        profile: rag-specialist
        description: "RAG Engineer for ingestion, vector search, reranking, and grounded citations"
      evaluation-specialist:
        profile: evaluation-specialist
        description: "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics"
      production-specialist:
        profile: production-specialist
        description: "Production Engineer for API integration, security review, test infra, and release readiness"
```

### Step 3.6: Enforce Leaf Agent Restrictions (Disable Delegation on Specialists)

Disable the `delegation` toolset on all 6 specialist profiles to prevent uncontrolled nested subagents:

```bash
hermes -p langchain-specialist tools disable delegation
hermes -p langgraph-specialist tools disable delegation
hermes -p agent-systems-specialist tools disable delegation
hermes -p rag-specialist tools disable delegation
hermes -p evaluation-specialist tools disable delegation
hermes -p production-specialist tools disable delegation
```

---

## 4. Verification & Usage

### Verify Installed Skills Per Agent

```bash
hermes -p langchain-engineer skills list
hermes -p langchain-specialist skills list
hermes -p langgraph-specialist skills list
hermes -p agent-systems-specialist skills list
hermes -p rag-specialist skills list
hermes -p evaluation-specialist skills list
hermes -p production-specialist skills list
```

### Test Delegation Workflow

Run an end-to-end task delegation query through the manager profile:

```bash
hermes -p langchain-engineer -z "Delegate to langchain-specialist to list its available skills and confirm its scope."
```

---

## 5. Repository Structure

```text
.
├── .gitignore                      # Git ignore rules for secrets and temporary files
├── README.md                       # Complete setup, architecture, and skill documentation
└── roles/                          # System prompts (SOUL.md) for all 7 team profiles
    ├── langchain-engineer.md       # Manager role charter & delegation contract
    ├── langchain-specialist.md     # LangChain specialist charter
    ├── langgraph-specialist.md     # LangGraph specialist charter
    ├── agent-systems-specialist.md # Agent Systems specialist charter
    ├── rag-specialist.md           # RAG specialist charter
    ├── evaluation-specialist.md    # Evaluation specialist charter
    └── production-specialist.md    # Production specialist charter
```

---

## License

MIT
