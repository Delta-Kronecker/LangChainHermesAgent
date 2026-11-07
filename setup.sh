#!/usr/bin/env bash
# Quick Setup Script for LangChain Engineering System on Hermes Agent (Linux/macOS)

set -e

echo "=== LangChain Engineering Team Automated Setup ==="

# Determine Hermes Home
HERMES_HOME="${HERMES_HOME:-$HOME/.local/share/hermes}"
PROFILES_DIR="$HERMES_HOME/profiles"
GLOBAL_SKILLS="$HERMES_HOME/skills"

# Step 1: Install advanced-delegation plugin
echo "[1/6] Installing advanced-delegation plugin..."
hermes plugins install advanced-delegation --enable --yes-deps || true

# Step 2: Create Profiles
echo "[2/6] Creating 7 independent profiles..."
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer || true
hermes profile create --no-skills --description "LangChain Engineer for core abstractions, tools, runnables, and middleware" langchain-specialist || true
hermes profile create --no-skills --description "LangGraph Engineer for stateful workflows, state schemas, and checkpointing" langgraph-specialist || true
hermes profile create --no-skills --description "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems" agent-systems-specialist || true
hermes profile create --no-skills --description "RAG Engineer for ingestion, vector search, reranking, and grounded citations" rag-specialist || true
hermes profile create --no-skills --description "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics" evaluation-specialist || true
hermes profile create --no-skills --description "Production Engineer for API integration, security review, test infra, and release readiness" production-specialist || true

# Step 3: Deploy SOUL.md system prompts
echo "[3/6] Deploying role charters (SOUL.md)..."
cp roles/langchain-engineer.md "$PROFILES_DIR/langchain-engineer/SOUL.md"
cp roles/langchain-specialist.md "$PROFILES_DIR/langchain-specialist/SOUL.md"
cp roles/langgraph-specialist.md "$PROFILES_DIR/langgraph-specialist/SOUL.md"
cp roles/agent-systems-specialist.md "$PROFILES_DIR/agent-systems-specialist/SOUL.md"
cp roles/rag-specialist.md "$PROFILES_DIR/rag-specialist/SOUL.md"
cp roles/evaluation-specialist.md "$PROFILES_DIR/evaluation-specialist/SOUL.md"
cp roles/production-specialist.md "$PROFILES_DIR/production-specialist/SOUL.md"

# Step 4: Install/Copy Skills
echo "[4/6] Assigning skills to profiles..."
cp -r "$GLOBAL_SKILLS/ecosystem-primer" "$PROFILES_DIR/langchain-engineer/skills/" 2>/dev/null || true

cp -r "$GLOBAL_SKILLS/langchain-fundamentals" "$PROFILES_DIR/langchain-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langchain-middleware" "$PROFILES_DIR/langchain-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langchain-dependencies" "$PROFILES_DIR/langchain-specialist/skills/" 2>/dev/null || true

cp -r "$GLOBAL_SKILLS/langgraph-fundamentals" "$PROFILES_DIR/langgraph-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langgraph-human-in-the-loop" "$PROFILES_DIR/langgraph-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langgraph-cli" "$PROFILES_DIR/langgraph-specialist/skills/" 2>/dev/null || true

cp -r "$GLOBAL_SKILLS/deep-agents-core" "$PROFILES_DIR/agent-systems-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/deep-agents-orchestration" "$PROFILES_DIR/agent-systems-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/deep-agents-memory" "$PROFILES_DIR/agent-systems-specialist/skills/" 2>/dev/null || true

cp -r "$GLOBAL_SKILLS/langchain-rag" "$PROFILES_DIR/rag-specialist/skills/" 2>/dev/null || true

cp -r "$GLOBAL_SKILLS/eval-engineering" "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langsmith-experiment-diagnosis" "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langsmith-online-eval-engineering" "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true

# Step 5: Configure Manager Profile Routing
echo "[5/6] Configuring Manager profile routes..."
python3 - <<'EOF'
import os, yaml

profile_dir = os.path.expanduser(os.environ.get("PROFILES_DIR", "~/.local/share/hermes/profiles"))
config_path = os.path.join(profile_dir, "langchain-engineer", "config.yaml")

if os.path.exists(config_path):
    with open(config_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    data["delegation"] = {
        "backend": "profile_routes",
        "backends": {
            "profile_routes": {
                "langchain-specialist": {
                    "profile": "langchain-specialist",
                    "description": "LangChain Engineer for core abstractions, tools, runnables, and middleware"
                },
                "langgraph-specialist": {
                    "profile": "langgraph-specialist",
                    "description": "LangGraph Engineer for stateful workflows, state schemas, and checkpointing"
                },
                "agent-systems-specialist": {
                    "profile": "agent-systems-specialist",
                    "description": "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems"
                },
                "rag-specialist": {
                    "profile": "rag-specialist",
                    "description": "RAG Engineer for ingestion, vector search, reranking, and grounded citations"
                },
                "evaluation-specialist": {
                    "profile": "evaluation-specialist",
                    "description": "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics"
                },
                "production-specialist": {
                    "profile": "production-specialist",
                    "description": "Production Engineer for API integration, security review, test infra, and release readiness"
                }
            }
        }
    }

    with open(config_path, "w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, default_flow_style=False)
EOF

# Step 6: Disable Delegation on Leaf Specialists
echo "[6/6] Enforcing leaf agent restrictions..."
for p in langchain-specialist langgraph-specialist agent-systems-specialist rag-specialist evaluation-specialist production-specialist; do
    hermes -p "$p" tools disable delegation || true
done

echo "=== Setup Completed Successfully! ==="
