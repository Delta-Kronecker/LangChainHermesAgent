# Quick Setup Script for LangChain Engineering System on Hermes Agent (Windows PowerShell)

$ErrorActionPreference = "Continue"

Write-Host "=== LangChain Engineering Team Automated Setup ===" -ForegroundColor Green

# Determine Hermes Profiles Directory
$PROFILES_DIR = "$env:LOCALAPPDATA\hermes\profiles"
$GLOBAL_SKILLS = "$env:LOCALAPPDATA\hermes\skills"

# Step 1: Install advanced-delegation plugin
Write-Host "[1/6] Installing advanced-delegation plugin..." -ForegroundColor Cyan
hermes plugins install advanced-delegation --enable --yes-deps

# Step 2: Create Profiles
Write-Host "[2/6] Creating 7 independent profiles..." -ForegroundColor Cyan
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer
hermes profile create --no-skills --description "LangChain Engineer for core abstractions, tools, runnables, and middleware" langchain-specialist
hermes profile create --no-skills --description "LangGraph Engineer for stateful workflows, state schemas, and checkpointing" langgraph-specialist
hermes profile create --no-skills --description "Agent Systems Engineer for Deep Agents, planning, and multi-agent systems" agent-systems-specialist
hermes profile create --no-skills --description "RAG Engineer for ingestion, vector search, reranking, and grounded citations" rag-specialist
hermes profile create --no-skills --description "Evaluation Engineer for benchmark datasets, LLM judges, and LangSmith diagnostics" evaluation-specialist
hermes profile create --no-skills --description "Production Engineer for API integration, security review, test infra, and release readiness" production-specialist

# Step 3: Deploy SOUL.md system prompts
Write-Host "[3/6] Deploying role charters (SOUL.md)..." -ForegroundColor Cyan
Copy-Item -Path "roles\langchain-engineer.md" -Destination "$PROFILES_DIR\langchain-engineer\SOUL.md" -Force
Copy-Item -Path "roles\langchain-specialist.md" -Destination "$PROFILES_DIR\langchain-specialist\SOUL.md" -Force
Copy-Item -Path "roles\langgraph-specialist.md" -Destination "$PROFILES_DIR\langgraph-specialist\SOUL.md" -Force
Copy-Item -Path "roles\agent-systems-specialist.md" -Destination "$PROFILES_DIR\agent-systems-specialist\SOUL.md" -Force
Copy-Item -Path "roles\rag-specialist.md" -Destination "$PROFILES_DIR\rag-specialist\SOUL.md" -Force
Copy-Item -Path "roles\evaluation-specialist.md" -Destination "$PROFILES_DIR\evaluation-specialist\SOUL.md" -Force
Copy-Item -Path "roles\production-specialist.md" -Destination "$PROFILES_DIR\production-specialist\SOUL.md" -Force

# Step 4: Install/Copy Skills
Write-Host "[4/6] Assigning skills to profiles..." -ForegroundColor Cyan
if (Test-Path "$GLOBAL_SKILLS\ecosystem-primer") { Copy-Item -Path "$GLOBAL_SKILLS\ecosystem-primer" -Destination "$PROFILES_DIR\langchain-engineer\skills\" -Recurse -Force }

if (Test-Path "$GLOBAL_SKILLS\langchain-fundamentals") { Copy-Item -Path "$GLOBAL_SKILLS\langchain-fundamentals" -Destination "$PROFILES_DIR\langchain-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\langchain-middleware") { Copy-Item -Path "$GLOBAL_SKILLS\langchain-middleware" -Destination "$PROFILES_DIR\langchain-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\langchain-dependencies") { Copy-Item -Path "$GLOBAL_SKILLS\langchain-dependencies" -Destination "$PROFILES_DIR\langchain-specialist\skills\" -Recurse -Force }

if (Test-Path "$GLOBAL_SKILLS\langgraph-fundamentals") { Copy-Item -Path "$GLOBAL_SKILLS\langgraph-fundamentals" -Destination "$PROFILES_DIR\langgraph-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\langgraph-human-in-the-loop") { Copy-Item -Path "$GLOBAL_SKILLS\langgraph-human-in-the-loop" -Destination "$PROFILES_DIR\langgraph-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\langgraph-cli") { Copy-Item -Path "$GLOBAL_SKILLS\langgraph-cli" -Destination "$PROFILES_DIR\langgraph-specialist\skills\" -Recurse -Force }

if (Test-Path "$GLOBAL_SKILLS\deep-agents-core") { Copy-Item -Path "$GLOBAL_SKILLS\deep-agents-core" -Destination "$PROFILES_DIR\agent-systems-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\deep-agents-orchestration") { Copy-Item -Path "$GLOBAL_SKILLS\deep-agents-orchestration" -Destination "$PROFILES_DIR\agent-systems-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\deep-agents-memory") { Copy-Item -Path "$GLOBAL_SKILLS\deep-agents-memory" -Destination "$PROFILES_DIR\agent-systems-specialist\skills\" -Recurse -Force }

if (Test-Path "$GLOBAL_SKILLS\langchain-rag") { Copy-Item -Path "$GLOBAL_SKILLS\langchain-rag" -Destination "$PROFILES_DIR\rag-specialist\skills\" -Recurse -Force }

if (Test-Path "$GLOBAL_SKILLS\eval-engineering") { Copy-Item -Path "$GLOBAL_SKILLS\eval-engineering" -Destination "$PROFILES_DIR\evaluation-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\langsmith-experiment-diagnosis") { Copy-Item -Path "$GLOBAL_SKILLS\langsmith-experiment-diagnosis" -Destination "$PROFILES_DIR\evaluation-specialist\skills\" -Recurse -Force }
if (Test-Path "$GLOBAL_SKILLS\langsmith-online-eval-engineering") { Copy-Item -Path "$GLOBAL_SKILLS\langsmith-online-eval-engineering" -Destination "$PROFILES_DIR\evaluation-specialist\skills\" -Recurse -Force }

# Step 5: Configure Manager Profile Routing
Write-Host "[5/6] Configuring Manager profile routes..." -ForegroundColor Cyan
$configPath = "$PROFILES_DIR\langchain-engineer\config.yaml"
$yamlBlock = @"

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
"@
Add-Content -Path $configPath -Value $yamlBlock

# Step 6: Disable Delegation on Leaf Specialists
Write-Host "[6/6] Enforcing leaf agent restrictions..." -ForegroundColor Cyan
$specialists = @("langchain-specialist", "langgraph-specialist", "agent-systems-specialist", "rag-specialist", "evaluation-specialist", "production-specialist")
foreach ($p in $specialists) {
    hermes -p $p tools disable delegation
}

Write-Host "=== Setup Completed Successfully! ===" -ForegroundColor Green
