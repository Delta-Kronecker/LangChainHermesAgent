#!/usr/bin/env bash
# Setup Script for the LangChain Engineering System on Hermes Agent (Linux/macOS/Git-Bash)
# Target: Hermes Agent v0.23.2+  |  Model: tokenharbor/deepseek-v4.1-flash:free via 9router
set -e

echo "=== LangChain Engineering Team Automated Setup ==="

# --- Resolve Hermes home (Windows MSYS vs Linux/macOS) ---
if [ -n "${HERMES_HOME:-}" ]; then
  :
elif [ -d "$HOME/AppData/Local/hermes" ]; then
  HERMES_HOME="$HOME/AppData/Local/hermes"
else
  HERMES_HOME="$HOME/.local/share/hermes"
fi
PROFILES_DIR="$HERMES_HOME/profiles"
GLOBAL_SKILLS="$HERMES_HOME/skills"

# --- Runtime model (single source of truth) ---
MODEL="tokenharbor/deepseek-v4.1-flash:free"
PROVIDER="9router"
BASE_URL="http://localhost:20128/v1"
API_MODE="chat_completions"
KEY_ENV="HERMES_CUSTOM_9ROUTER_API_KEY"

PROFILES="langchain-engineer langchain-specialist langgraph-specialist agent-systems-specialist rag-specialist evaluation-specialist production-specialist"
SPECIALISTS="langchain-specialist langgraph-specialist agent-systems-specialist rag-specialist evaluation-specialist production-specialist"

# Step 1: Optional advanced-delegation plugin (enables profile_routes)
echo "[1/9] Installing advanced-delegation plugin (optional)..."
hermes plugins install advanced-delegation --enable --yes-deps || true

# Step 2: Create the 7 isolated profiles
echo "[2/9] Creating 7 independent profiles..."
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer || true
hermes profile create --no-skills --description "LangChain Engineer for core abstractions, tools, runnables, and middleware" langchain-specialist || true
hermes profile create --no-skills --description "LangGraph Engineer for stateful workflows, state schemas, and checkpointing" langgraph-specialist || true
hermes profile create --no-skills --description "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems" agent-systems-specialist || true
hermes profile create --no-skills --description "RAG Engineer for ingestion, vector search, reranking, and grounded citations" rag-specialist || true
hermes profile create --no-skills --description "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics" evaluation-specialist || true
hermes profile create --no-skills --description "Production Engineer for API integration, security review, test infra, and release readiness" production-specialist || true

# Step 3: Set the shared runtime model on every profile
echo "[3/9] Setting runtime model ($MODEL via $PROVIDER)..."
for p in $PROFILES; do
  hermes -p "$p" config set model.default "$MODEL"     || true
  hermes -p "$p" config set model.provider "$PROVIDER" || true
  hermes -p "$p" config set model.base_url "$BASE_URL" || true
  hermes -p "$p" config set model.api_mode "$API_MODE" || true
  hermes -p "$p" config set model.key_env "$KEY_ENV"   || true
done
echo "   NOTE: ensure $KEY_ENV is present in each profile's .env"

# Step 4: Deploy SOUL.md role charters
echo "[4/9] Deploying role charters (SOUL.md)..."
for p in $PROFILES; do
  cp "roles/$p.md" "$PROFILES_DIR/$p/SOUL.md"
done

# Step 5: Install legacy skills from the global skills dir (if present)
echo "[5/9] Installing legacy skills from $GLOBAL_SKILLS ..."
cp -r "$GLOBAL_SKILLS/ecosystem-primer"            "$PROFILES_DIR/langchain-engineer/skills/"       2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langchain-fundamentals"      "$PROFILES_DIR/langchain-specialist/skills/"     2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langchain-middleware"        "$PROFILES_DIR/langchain-specialist/skills/"     2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langchain-dependencies"      "$PROFILES_DIR/langchain-specialist/skills/"     2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langgraph-fundamentals"      "$PROFILES_DIR/langgraph-specialist/skills/"     2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langgraph-human-in-the-loop" "$PROFILES_DIR/langgraph-specialist/skills/"     2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langgraph-cli"               "$PROFILES_DIR/langgraph-specialist/skills/"     2>/dev/null || true
cp -r "$GLOBAL_SKILLS/deep-agents-core"            "$PROFILES_DIR/agent-systems-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/deep-agents-orchestration"   "$PROFILES_DIR/agent-systems-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/deep-agents-memory"          "$PROFILES_DIR/agent-systems-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langchain-rag"               "$PROFILES_DIR/rag-specialist/skills/"           2>/dev/null || true
cp -r "$GLOBAL_SKILLS/eval-engineering"            "$PROFILES_DIR/evaluation-specialist/skills/"    2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langsmith-experiment-diagnosis"     "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true
cp -r "$GLOBAL_SKILLS/langsmith-online-eval-engineering" "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true

# Step 6: Install the CURRENT official 4-skill set (langchain-ai/langchain-skills)
echo "[6/9] Installing current official skills (build-agent, eval-engineering, monitoring, tracing)..."
TMP_LC="$(mktemp -d)"
if git clone --depth 1 https://github.com/langchain-ai/langchain-skills.git "$TMP_LC/lc" 2>/dev/null; then
  SRC="$TMP_LC/lc/skills"
  for p in langchain-specialist langgraph-specialist agent-systems-specialist rag-specialist; do
    cp -R "$SRC/langchain-build-agent" "$PROFILES_DIR/$p/skills/" 2>/dev/null || true
  done
  cp -R "$SRC/langchain-eval-engineering"  "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true
  cp -R "$SRC/langchain-agent-monitoring"  "$PROFILES_DIR/evaluation-specialist/skills/" 2>/dev/null || true
  cp -R "$SRC/langchain-agent-monitoring"  "$PROFILES_DIR/production-specialist/skills/" 2>/dev/null || true
  cp -R "$SRC/langchain-agent-tracing"     "$PROFILES_DIR/production-specialist/skills/" 2>/dev/null || true
else
  echo "   WARN: could not clone langchain-ai/langchain-skills; skipping current official set"
fi
rm -rf "$TMP_LC"

# Step 7: Install + enable the localgw-web provider plugin and pin web.search_backend
echo "[7/9] Wiring web_search to the local gateway (localgw-web plugin)..."
for p in $PROFILES; do
  PLUG="$PROFILES_DIR/$p/plugins/localgw-web"
  mkdir -p "$PLUG"
  cat > "$PLUG/provider.py" <<'PYEOF'
"""Local 9router gateway web search provider (web_search -> /v1/search)."""
from __future__ import annotations

import logging

import httpx

from plugins.web._common import (
    SEARCH_LIMIT_CAP, BaseWebSearchProvider, provider_env, run_search,
    search_fail, search_ok, title_hit,
)

logger = logging.getLogger(__name__)

_DEFAULT_BASE = "http://localhost:20128/v1"


class LocalGatewayWebSearchProvider(BaseWebSearchProvider):
    NAME = "localgw"
    DISPLAY_NAME = "Local Gateway (9router)"
    KEY_ENV = "HERMES_CUSTOM_9ROUTER_API_KEY"
    EXTRACT = False
    KEYLESS = False

    def search(self, query: str, limit: int = 5):
        def _body():
            key = provider_env(self.KEY_ENV) or provider_env("LOCALGW_API_KEY")
            if not key:
                return search_fail("HERMES_CUSTOM_9ROUTER_API_KEY not set for localgw")
            base = (provider_env("LOCALGW_BASE_URL") or _DEFAULT_BASE).rstrip("/")
            payload = {
                "provider": provider_env("LOCALGW_PROVIDER") or "tavily",
                "query": query,
                "search_type": "web",
                "max_results": min(max(1, int(limit)), SEARCH_LIMIT_CAP),
            }
            try:
                r = httpx.post(
                    f"{base}/search",
                    json=payload,
                    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
                    timeout=60,
                )
            except Exception as exc:
                return search_fail(f"localgw request failed: {exc}")
            if r.status_code >= 400:
                return search_fail(f"localgw HTTP {r.status_code}: {(r.text or '')[:300]}")
            try:
                data = r.json()
            except Exception:
                return search_fail("localgw returned non-JSON")
            return search_ok([
                title_hit(
                    x.get("title", "") or "",
                    x.get("url", "") or "",
                    x.get("snippet") or x.get("content") or x.get("description") or "",
                    i + 1,
                )
                for i, x in enumerate(data.get("results") or [])
            ])

        return run_search("LocalGW", logger, _body)

    def get_setup_schema(self):
        return {"name": self.DISPLAY_NAME, "badge": "", "tag": "", "env_vars": []}
PYEOF
  cat > "$PLUG/__init__.py" <<'PYEOF'
"""localgw-web plugin — routes web_search through the local 9router gateway."""
from __future__ import annotations

from .provider import LocalGatewayWebSearchProvider


def register(ctx) -> None:
    ctx.register_web_search_provider(LocalGatewayWebSearchProvider())
PYEOF
  cat > "$PLUG/plugin.yaml" <<'YAMLEOF'
name: localgw-web
label: Local Gateway Web Search
kind: standalone
version: 1.0.0
author: local
description: >
  Routes the web_search tool through the local 9router gateway at
  http://localhost:20128/v1/search. Auth reuses HERMES_CUSTOM_9ROUTER_API_KEY.
provides_tools: []
provides_hooks: []
YAMLEOF
  hermes -p "$p" plugins enable localgw-web --no-allow-tool-override || true
  hermes -p "$p" config set web.search_backend localgw || true
done

# Step 8: Configure manager profile_routes (optional inline delegation)
echo "[8/9] Configuring manager profile_routes..."
python3 - "$PROFILES_DIR" <<'PYEOF'
import os, sys
try:
    import yaml
except Exception:
    print("   WARN: pyyaml not available; skipping profile_routes block"); raise SystemExit(0)
profiles_dir = sys.argv[1]
path = os.path.join(profiles_dir, "langchain-engineer", "config.yaml")
if os.path.exists(path):
    data = yaml.safe_load(open(path, encoding="utf-8")) or {}
    routes = {
        "langchain-specialist": "LangChain Engineer for core abstractions, tools, runnables, and middleware",
        "langgraph-specialist": "LangGraph Engineer for stateful workflows, state schemas, and checkpointing",
        "agent-systems-specialist": "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems",
        "rag-specialist": "RAG Engineer for ingestion, vector search, reranking, and grounded citations",
        "evaluation-specialist": "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics",
        "production-specialist": "Production Engineer for API integration, security review, test infra, and release readiness",
    }
    data["delegation"] = {"backend": "profile_routes", "backends": {"profile_routes": {k: {"profile": k, "description": d} for k, d in routes.items()}}}
    yaml.safe_dump(data, open(path, "w", encoding="utf-8"), default_flow_style=False, sort_keys=False)
    print("   profile_routes written")
PYEOF

# Step 9: Enforce leaf-agent policy + verify
echo "[9/9] Enforcing leaf agents and verifying..."
for p in $SPECIALISTS; do
  hermes -p "$p" tools disable delegation || true
done

echo "--- Verification ---"
for p in $PROFILES; do
  printf "%-26s " "$p"
  printf "model=%s " "$(hermes -p "$p" config get model.default 2>/dev/null)"
  printf "web=%s " "$(hermes -p "$p" config get web.search_backend 2>/dev/null)"
  printf "localgw=%s\n" "$(hermes -p "$p" plugins list 2>/dev/null | grep -ci localgw)"
done

echo "=== Setup Completed Successfully! ==="
echo "Next: ensure $KEY_ENV is set in each profile's .env, then run a web_search smoke test."