# Setup Script for the LangChain Engineering System on Hermes Agent (Windows PowerShell)
# Target: Hermes Agent v0.23.2+  |  Model: tokenharbor/deepseek-v4.1-flash:free via 9router

$ErrorActionPreference = "Continue"

Write-Host "=== LangChain Engineering Team Automated Setup ===" -ForegroundColor Green

$PROFILES_DIR = "$env:LOCALAPPDATA\hermes\profiles"
$GLOBAL_SKILLS = "$env:LOCALAPPDATA\hermes\skills"

# --- Runtime model (single source of truth) ---
$MODEL    = "tokenharbor/deepseek-v4.1-flash:free"
$PROVIDER = "9router"
$BASE_URL = "http://localhost:20128/v1"
$API_MODE = "chat_completions"
$KEY_ENV  = "HERMES_CUSTOM_9ROUTER_API_KEY"

$PROFILES    = @("langchain-engineer","langchain-specialist","langgraph-specialist","agent-systems-specialist","rag-specialist","evaluation-specialist","production-specialist")
$SPECIALISTS = @("langchain-specialist","langgraph-specialist","agent-systems-specialist","rag-specialist","evaluation-specialist","production-specialist")

# Step 1: Optional advanced-delegation plugin
Write-Host "[1/9] Installing advanced-delegation plugin (optional)..." -ForegroundColor Cyan
hermes plugins install advanced-delegation --enable --yes-deps

# Step 2: Create the 7 isolated profiles
Write-Host "[2/9] Creating 7 independent profiles..." -ForegroundColor Cyan
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer
hermes profile create --no-skills --description "LangChain Engineer for core abstractions, tools, runnables, and middleware" langchain-specialist
hermes profile create --no-skills --description "LangGraph Engineer for stateful workflows, state schemas, and checkpointing" langgraph-specialist
hermes profile create --no-skills --description "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems" agent-systems-specialist
hermes profile create --no-skills --description "RAG Engineer for ingestion, vector search, reranking, and grounded citations" rag-specialist
hermes profile create --no-skills --description "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics" evaluation-specialist
hermes profile create --no-skills --description "Production Engineer for API integration, security review, test infra, and release readiness" production-specialist

# Step 3: Set the shared runtime model
Write-Host "[3/9] Setting runtime model ($MODEL via $PROVIDER)..." -ForegroundColor Cyan
foreach ($p in $PROFILES) {
    hermes -p $p config set model.default  $MODEL
    hermes -p $p config set model.provider $PROVIDER
    hermes -p $p config set model.base_url $BASE_URL
    hermes -p $p config set model.api_mode $API_MODE
    hermes -p $p config set model.key_env  $KEY_ENV
}
Write-Host "   NOTE: ensure $KEY_ENV is present in each profile's .env" -ForegroundColor Yellow

# Step 4: Deploy SOUL.md
Write-Host "[4/9] Deploying role charters (SOUL.md)..." -ForegroundColor Cyan
foreach ($p in $PROFILES) {
    Copy-Item -Path "roles\$p.md" -Destination "$PROFILES_DIR\$p\SOUL.md" -Force
}

# Step 5: Legacy skills from the global skills dir
Write-Host "[5/9] Installing legacy skills from $GLOBAL_SKILLS ..." -ForegroundColor Cyan
$legacy = @{
    "langchain-engineer"        = @("ecosystem-primer")
    "langchain-specialist"      = @("langchain-fundamentals","langchain-middleware","langchain-dependencies")
    "langgraph-specialist"      = @("langgraph-fundamentals","langgraph-human-in-the-loop","langgraph-cli")
    "agent-systems-specialist"  = @("deep-agents-core","deep-agents-orchestration","deep-agents-memory")
    "rag-specialist"            = @("langchain-rag")
    "evaluation-specialist"     = @("eval-engineering","langsmith-experiment-diagnosis","langsmith-online-eval-engineering")
}
foreach ($p in $legacy.Keys) {
    foreach ($s in $legacy[$p]) {
        if (Test-Path "$GLOBAL_SKILLS\$s") { Copy-Item -Path "$GLOBAL_SKILLS\$s" -Destination "$PROFILES_DIR\$p\skills\" -Recurse -Force }
    }
}

# Step 6: Current official 4-skill set
Write-Host "[6/9] Installing current official skills (build-agent, eval-engineering, monitoring, tracing)..." -ForegroundColor Cyan
$TMP_LC = Join-Path $env:TEMP ("lcskills_" + [System.Guid]::NewGuid().ToString("N"))
if (git clone --depth 1 https://github.com/langchain-ai/langchain-skills.git $TMP_LC) {
    $SRC = Join-Path $TMP_LC "skills"
    foreach ($p in @("langchain-specialist","langgraph-specialist","agent-systems-specialist","rag-specialist")) {
        Copy-Item -Path "$SRC\langchain-build-agent" -Destination "$PROFILES_DIR\$p\skills\" -Recurse -Force
    }
    Copy-Item -Path "$SRC\langchain-eval-engineering" -Destination "$PROFILES_DIR\evaluation-specialist\skills\" -Recurse -Force
    Copy-Item -Path "$SRC\langchain-agent-monitoring" -Destination "$PROFILES_DIR\evaluation-specialist\skills\" -Recurse -Force
    Copy-Item -Path "$SRC\langchain-agent-monitoring" -Destination "$PROFILES_DIR\production-specialist\skills\" -Recurse -Force
    Copy-Item -Path "$SRC\langchain-agent-tracing"    -Destination "$PROFILES_DIR\production-specialist\skills\" -Recurse -Force
} else {
    Write-Host "   WARN: could not clone langchain-ai/langchain-skills; skipping current official set" -ForegroundColor Yellow
}
Remove-Item -Recurse -Force $TMP_LC -ErrorAction SilentlyContinue

# Step 7: localgw-web provider plugin + pin web.search_backend
Write-Host "[7/9] Wiring web_search to the local gateway (localgw-web plugin)..." -ForegroundColor Cyan

$providerPy = @'
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
'@

$initPy = @'
"""localgw-web plugin — routes web_search through the local 9router gateway."""
from __future__ import annotations

from .provider import LocalGatewayWebSearchProvider


def register(ctx) -> None:
    ctx.register_web_search_provider(LocalGatewayWebSearchProvider())
'@

$pluginYaml = @'
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
'@

foreach ($p in $PROFILES) {
    $PLUG = "$PROFILES_DIR\$p\plugins\localgw-web"
    New-Item -ItemType Directory -Force -Path $PLUG | Out-Null
    Set-Content -Path "$PLUG\provider.py" -Value $providerPy -Encoding UTF8
    Set-Content -Path "$PLUG\__init__.py" -Value $initPy -Encoding UTF8
    Set-Content -Path "$PLUG\plugin.yaml" -Value $pluginYaml -Encoding UTF8
    hermes -p $p plugins enable localgw-web --no-allow-tool-override
    hermes -p $p config set web.search_backend localgw
}

# Step 8: Manager profile_routes (optional inline delegation)
Write-Host "[8/9] Configuring manager profile_routes..." -ForegroundColor Cyan
$configPath = "$PROFILES_DIR\langchain-engineer\config.yaml"
$yamlBlock = @'

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
'@
if (Select-String -Path $configPath -Pattern '^delegation:' -Quiet) {
    Write-Host "   delegation block already present; skipping" -ForegroundColor Yellow
} else {
    Add-Content -Path $configPath -Value $yamlBlock
}

# Step 9: Enforce leaf agents + verify
Write-Host "[9/9] Enforcing leaf agents and verifying..." -ForegroundColor Cyan
foreach ($p in $SPECIALISTS) {
    hermes -p $p tools disable delegation
}

Write-Host "--- Verification ---" -ForegroundColor Cyan
foreach ($p in $PROFILES) {
    $m = (hermes -p $p config get model.default 2>$null)
    $w = (hermes -p $p config get web.search_backend 2>$null)
    $g = ((hermes -p $p plugins list 2>$null) | Select-String -Pattern "localgw").Count
    Write-Host ("{0,-26} model={1} web={2} localgw={3}" -f $p, $m, $w, $g)
}

Write-Host "=== Setup Completed Successfully! ===" -ForegroundColor Green
Write-Host "Next: ensure $KEY_ENV is set in each profile's .env, then run a web_search smoke test."