# LangChain Engineering System on Hermes Agent
## Comprehensive Project Master Specification, Skills Inventory, Architecture, Security Model, Delegation Design, and Implementation Runbook

**Document language:** English  
**Project:** LangChain Engineering Team for Hermes Agent  
**Document status:** Consolidated design baseline; implementation not yet started  
**Knowledge cut-off for this reconstruction:** 7 November 2026  
**Environment recorded:** Hermes Agent `v0.22.7`, Windows PowerShell, Python `3.14.9`  
**Primary architecture:** One central manager + six specialist profiles  
**Model/provider ownership:** User-managed; deliberately excluded from this design  

> **Important provenance statement:** This document consolidates the project history and technical findings available in the conversation context for “Building Agents in Hermes (1)–(6)”, together with the subsequent architecture discussion. The six links supplied in the conversation used the same conversation URL/ID, so this is not a verbatim export of six independently retrievable transcripts. Details explicitly present in the available record are marked as observed or decided. Recommendations that have not been implemented are marked as proposed. Unknowns and unverified behavior are called out rather than invented.

---

# 0. Document Governance and Evidence Labels

This document is the single working reference for the LangChain/Hermes agent-system project. It should be updated as decisions are validated in the actual Hermes environment.

## 0.1 Evidence labels

The following labels are used throughout:

- **[OBSERVED]** — directly shown by a command output, installation log, file name, or explicit conversation record.
- **[DECIDED]** — an explicit user decision or a design direction accepted in the conversation.
- **[PROPOSED]** — a recommended design that has not yet been implemented or explicitly approved.
- **[NOT VERIFIED]** — plausible or intended behavior for which the installed version has not yet been tested or whose exact command output is not available.
- **[REJECTED]** — an option that was explicitly removed, declined, or excluded from the final baseline.
- **[DEFERRED]** — intentionally postponed to a later stage.

A status label describes the maturity of a statement, not its importance. A proposed security control must not be described as an enforced control until it has been implemented and tested.

## 0.2 Change-control rules

1. Do not silently convert a proposal into a decision.
2. Do not claim a command was executed unless its output exists in the project record.
3. Do not claim an installation, profile creation, configuration change, test, or deployment succeeded unless there is evidence.
4. When new evidence contradicts this document, preserve the old decision in the decision log and record the new decision with its reason and date.
5. Keep unrelated Hermes profiles, global settings, credentials, Skills, and integrations untouched unless the user explicitly authorizes a change.
6. The user owns model and provider selection. The design must not select, recommend as a configuration decision, or silently constrain models for any profile.

## 0.3 Project terminology

- **Hermes profile:** An independently configured Hermes agent identity/environment.
- **Manager:** The single central `langchain-engineer` profile.
- **Specialist:** One of the six domain profiles called by the manager.
- **Skill:** A packaged set of domain instructions/references available to a profile.
- **Toolset:** A group of Hermes tools such as `terminal`, `file`, `web`, or `delegation`.
- **Tool permission:** Permission to invoke a particular tool or toolset. Its exact enforcement granularity must be verified for the installed Hermes version.
- **Delegation:** Internal subagent work initiated using Hermes `delegate_task` and configured through a compatible delegation backend.
- **A2A:** Agent-to-Agent protocol communication. It is distinct from internal Hermes subagent delegation.
- **Workspace:** The project files a task is allowed to read or modify.
- **Runtime isolation:** Technical enforcement that prevents a process from accessing resources outside an approved boundary. A prompt instruction or working-directory default is not runtime isolation.

---

# 1. Executive Summary

The project is to create a professional, multi-specialist LangChain engineering system inside Hermes Agent. It is not simply a collection of prompts, a group of loosely connected chat personas, or a Skill installation exercise. It is an engineering workflow with a central technical owner, explicit areas of specialist ownership, controlled delegation, least-privilege access, testable acceptance criteria, and evidence-based quality control.

The target team is:

1. **LangChain Lead Architect / Engineering Manager** — central manager and sole orchestrator.
2. **LangChain Engineer** — LangChain primitives, models as application components, prompts, runnables, tools, agents, middleware, structured output, and dependencies.
3. **LangGraph Engineer** — stateful graph workflows, state, nodes, edges, reducers, interrupts, checkpointing, persistence, resumption, and recovery.
4. **Agent Systems Engineer** — Deep Agents, planning, subagent patterns, memory architecture, multi-agent collaboration, and agent-level orchestration.
5. **RAG Engineer** — ingestion, document processing, chunking, embeddings, vector stores, retrieval, hybrid search, reranking, grounding, and citations.
6. **Evaluation Engineer** — datasets, evaluation criteria, LLM-as-judge, experiments, trace diagnosis, online evaluation, regression analysis, and LangSmith evaluation workflows.
7. **Production Engineer** — service/API integration, testing, security, secrets handling, reliability, deployment preparation, CI/CD, monitoring, observability, performance, and cost engineering.

The baseline contains **14 approved and installed LangChain/LangSmith Skills**. They were reported as `SAFE` when installed. Three other LangSmith-related Skills were blocked by critical scanner findings and are not part of the approved inventory. `langgraph-persistence` was force-installed once after a high-risk warning and later uninstalled; it is not part of the final 14-Skill inventory.

The preferred internal delegation architecture is Hermes `delegate_task` using the `advanced-delegation` plugin's **`profile_routes`** backend. The plugin was found and inspected, including its official catalogue status and pinned revision, but it has **not** been installed. A2A is not required for the internal team.

No LangChain project profiles have been created yet. No `profile_routes` configuration has been applied. No specialist-specific tool permissions have been configured or verified. The previous eight Hermes profiles and unrelated Skills remain untouched. Models, providers, API keys, and model-to-role assignment are deliberately deferred to the user.

## 1.1 Current overall status

| Workstream | Status | Notes |
|---|---|---|
| Project purpose and scope | [DECIDED] | Professional LangChain engineering system |
| Team topology | [DECIDED] | One manager + six specialists |
| Specialist boundaries | [DESIGNED] | Initial ownership and non-overlap defined |
| 14 LangChain Skills | [OBSERVED] | Installed; reported SAFE at installation |
| Rejected Skills | [OBSERVED] | Three critical LangSmith Skills not installed |
| Removed Skill | [OBSERVED] | `langgraph-persistence` uninstalled |
| `advanced-delegation` discovery | [OBSERVED] | Official plugin version 1.1.1 inspected |
| Plugin installation | [NOT DONE] | No installation evidence |
| New profiles | [NOT DONE] | No profiles created |
| Profile routes | [NOT DONE] | No configuration applied |
| Per-profile tool policy | [PROPOSED / NOT VERIFIED] | Needs version-specific inspection |
| Filesystem isolation | [NOT DONE] | Needs real technical enforcement and tests |
| Model/provider configuration | [DEFERRED] | User-managed |
| End-to-end team test | [NOT DONE] | Must be run after implementation |

---

# 2. Project Goals, Non-Goals, and Success Criteria

## 2.1 Primary goals

The system should:

- Understand and solve practical engineering problems in the LangChain ecosystem.
- Choose an appropriate architecture rather than forcing every problem into one framework component.
- Separate work across real domain specialists with clear ownership.
- Delegate only when doing so adds value; avoid calling all specialists for trivial tasks.
- Preserve a coherent technical design across the work of multiple specialists.
- Use official documentation and the actual installed package versions as authoritative technical references.
- Build maintainable Python-first systems.
- Test changes and distinguish executed tests from proposed tests.
- Diagnose defects with evidence and root-cause analysis.
- Evaluate agent and RAG quality systematically.
- Address security, reliability, deployment, monitoring, performance, and operating cost before declaring a system production-ready.
- Return integrated, usable results rather than disconnected specialist reports.

## 2.2 Non-goals for the current phase

The following are intentionally outside the current architecture-design scope:

- Choosing the model for the manager or any specialist.
- Choosing model providers or gateways.
- Selecting provider-specific API endpoints.
- Setting API keys, credentials, or `.env` contents.
- Replacing or reconfiguring existing Hermes profiles.
- Reorganizing unrelated Skills already installed in Hermes.
- Installing unreviewed community Skills to fill perceived gaps.
- Enabling unrelated integrations, channels, cron jobs, or A2A endpoints.
- Deploying to a real production environment before an explicit approval.

## 2.3 Definition of success

The project is successful only when all of the following are demonstrated:

1. The manager profile is independent and can identify the correct specialist(s).
2. The manager can route work to the intended specialist profiles using the selected delegation backend.
3. Specialists receive the relevant task context, constraints, and acceptance criteria.
4. Specialists use only the Skills and permissions appropriate to their roles.
5. Specialists do not create uncontrolled nested delegation chains.
6. File and runtime access are bounded by enforceable controls, not just written instructions.
7. Independent work can run concurrently without conflicting edits.
8. Dependent work runs in the correct order.
9. The manager evaluates the specialist output before integration.
10. Test reports accurately distinguish passed, failed, skipped, and not-run tests.
11. Sensitive operations require the correct approval.
12. The final response is concise enough for the user but includes technical decisions, actual changes, verification evidence, and limitations.

---

# 3. Environment Inventory and Existing Hermes State

## 3.1 Recorded host environment

| Item | Recorded value | Evidence status |
|---|---|---|
| Operating system | Windows | [OBSERVED] |
| Shell | PowerShell | [OBSERVED] |
| Hermes version | `0.22.7` | [OBSERVED] |
| Hermes version date shown in record | `2026.9.24` | [OBSERVED] |
| Python version | `3.14.9` | [OBSERVED] |
| Hermes executable | `C:\Users\X\AppData\Local\hermes\bin\hermes.exe` | [OBSERVED] |
| User home | `C:\Users\X` | [OBSERVED] |
| Project language preference | Python-first | [DECIDED] |

The exact active profile at the moment of each historical command is not consistently recorded. Do not assume that the currently active profile is `default` or any particular specialist profile without checking.

## 3.2 Existing profiles that must remain untouched

The following profiles existed before the LangChain project was created:

```text
default
agent-1-cto
agent-2-uiux
agent-3-visual
agent-4-frontend
agent-5-creativedev
agent-6-backend
agent-7-security
agent-8-qa
```

**[DECIDED] These profiles are out of scope for modification.** They belong to prior projects and must not be cloned over, renamed, deleted, purged, or used as the basis for the new LangChain team unless the user later gives explicit authorization.

A prior `hermes profile list` showed the `default` profile using a Google/Gemini route and the other profiles using another Gemini route. These historical model values are environment observations only. They are not instructions or recommendations for the LangChain profiles. The user will choose models later.

## 3.3 Existing Skills inventory outside this project

At one point, `hermes skills list --source hub --enabled-only` reported:

```text
50 hub-installed
0 builtin
0 local
50 enabled shown
```

This was a broad Hermes inventory, not a LangChain-specific inventory. The 14 Skills listed in this document are included in the project-approved set. The remaining hub Skills relate to other activities and should not be removed or reassigned automatically.

A separate local Skills listing reported five local Skills:

```text
proxy-collection-tool
vercel-react-best-practices
catalog-aggregation
github-actions-services
telegram-serverless-bots
```

These are not part of the LangChain package. They must remain untouched unless their owners and purpose are reviewed in a separate task.

## 3.4 Existing global toolset state observed

The following was shown by `hermes tools list` at the time of inspection:

```text
Built-in toolsets (cli):
✓ web
✓ browser
✓ terminal
✓ file
✓ code_execution
✓ vision
✓ video
✓ image_gen
✓ video_gen
✓ x_search
✓ tts
✗ stt
✓ skills
✓ todo
✓ kanban
✓ memory
✓ context_engine
✓ session_search
✓ connections
✓ clarify
✓ delegation
✓ cronjob
✓ yuanbao
✓ computer_use

Plugin toolsets (cli):
✓ a2a
```

This is a snapshot of the general CLI/toolset availability shown by that command. It does **not** prove that each profile is entitled to every tool, that each tool is available in each runtime, or that there is a profile-level permission boundary. Profile-specific enforcement must be investigated separately.

---

# 4. Skills Discovery, Screening, Installation, and Governance

## 4.1 Why Skills were reviewed before installation

The project deliberately started with inventory and review rather than bulk installation. The reasons were:

- avoid duplicates;
- avoid adding Skills unrelated to the final role architecture;
- identify official LangChain and LangSmith material;
- evaluate instructions, scripts, references, and dependencies;
- screen for unsafe installation and execution patterns;
- preserve the existing Hermes environment;
- avoid trusting a Skill solely because its repository name looks official or familiar.

The user explicitly preferred consolidated PowerShell workflows and a review-first process. The user also asked for critical judgment rather than automatic agreement with every suggestion.

## 4.2 Relevant Hermes Skills commands observed

The command family used or inspected included:

```powershell
hermes skills list
hermes skills search
hermes skills inspect
hermes skills audit
hermes skills check
hermes skills tap
hermes skills install
hermes skills uninstall
```

The user also inspected help for `hermes skills tap add` and `hermes skills search`. The tap command help showed a repository argument, for example:

```powershell
hermes skills tap add owner/repo
```

Do not assume options or syntax that were not shown by the installed version's own `--help` output.

## 4.3 Official source repositories used

The two repositories recorded as the principal sources were:

```text
https://github.com/langchain-ai/langchain-skills
https://github.com/langchain-ai/langsmith-skills
```

The recorded installation examples used raw GitHub Skill file URLs, such as:

```powershell
hermes skills install "https://raw.githubusercontent.com/langchain-ai/langchain-skills/main/config/skills/langgraph-cli/SKILL.md" --yes
```

The final approved inventory is the 14-item list in Section 5. The fact that a Skill came from an official repository does not remove the need to inspect its content and scan result.

## 4.4 Installation security process observed

The installation log format included steps similar to:

```text
Fetching: ...
Quarantined to .hub\quarantine\...
Running security scan...
Scan: ...
Verdict: ...
```

The scanner label visible in the records was:

```text
skills-guard-v10
```

The 14 approved Skills were reported with `Verdict: SAFE` at the time of installation. This statement is time-bounded: a SAFE result is evidence from that installation scan, not a permanent guarantee that future revisions, references, dependencies, or execution behavior remain safe.

Recommended governance:

1. Pin or record the exact source and revision where possible.
2. Inspect the full Skill directory, not only its name or one-line description.
3. Review scripts and commands before running them.
4. Review outbound network behavior and shell execution patterns.
5. Check dependency pinning and package provenance.
6. Re-run scans when Skills change.
7. Keep the approved Skill inventory explicit.
8. Do not use `--force` to bypass a critical finding without a documented risk decision and explicit user authorization. A tool's ability to force an install is not proof that doing so is safe.

## 4.5 Security events and rejected Skills

### `langsmith-trace`

- Reported finding: `CRITICAL`.
- Location: line 28.
- Scanner pattern: `curl_pipe_shell`.
- Final status: not installed in the approved set.

### `langsmith-dataset`

- Reported finding: `CRITICAL` at line 39 for `curl_pipe_shell`.
- Additional finding: `MEDIUM` for unpinned pip/npm dependencies.
- Final status: not installed in the approved set.

### `langsmith-evaluator`

- Reported finding: `CRITICAL` at line 49 for `curl_pipe_shell`.
- Additional finding: `MEDIUM` for unpinned pip/npm dependencies.
- Final status: not installed in the approved set.

These are recorded scanner findings, not a complete independent malware verdict. They are sufficient to keep the listed Skills out of the approved set unless a later, careful manual review and explicit re-approval changes that decision.

### `langgraph-persistence`

The Skill was flagged with a HIGH caution related to the example:

```python
os.environ["DATABASE_URL"]
```

The context was Postgres checkpointing/persistence. The user once authorized a force installation, but later ran:

```powershell
hermes skills uninstall langgraph-persistence
```

Final status: **uninstalled and excluded from the approved 14-Skill set**.

The Skill's removal does not mean LangGraph persistence is prohibited. Persistence remains a legitimate LangGraph engineering capability. The current decision is only that this particular Skill is not in the approved package. A future replacement or a manually reviewed implementation may be considered after security review.

## 4.6 Other Skills and candidate areas considered

The broader project history included consideration or inspection of multiple LangChain ecosystem Skills. The following names are explicitly present in the available record:

- `langgraph-persistence` — removed, as described above.
- `langsmith-trace` — critical scan finding; not approved.
- `langsmith-dataset` — critical and medium findings; not approved.
- `langsmith-evaluator` — critical and medium findings; not approved.

The project also used review artifacts such as `CORE_SKILLS_REVIEW.txt` and `REMAINING_18_SKILLS_REVIEW.txt`. The exact complete names and per-Skill assessment of every item in the 18-item review list are not all preserved in the available summary. Do not fabricate an 18-row review table from incomplete evidence. If the original text files are reintroduced, they should be reconciled with this master document.

## 4.7 Approved Skills inventory summary

The final project-approved list contains exactly 14 Skills:

1. `ecosystem-primer`
2. `langchain-fundamentals`
3. `langchain-middleware`
4. `langchain-dependencies`
5. `langchain-rag`
6. `langgraph-fundamentals`
7. `langgraph-human-in-the-loop`
8. `langgraph-cli`
9. `deep-agents-core`
10. `deep-agents-orchestration`
11. `deep-agents-memory`
12. `eval-engineering`
13. `langsmith-experiment-diagnosis`
14. `langsmith-online-eval-engineering`

Detailed descriptions and allocation are in Sections 5 and 6.

---

# 5. Complete Approved Skills Catalogue

This section defines the role each Skill plays in the project. Descriptions are based on the recorded names, source context, and the prior project review; they are not a substitute for the full contents of each Skill's `SKILL.md` and reference files.

## 5.1 `ecosystem-primer`

**Assigned profile:** `langchain-engineer` (central manager)  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE  
**Purpose:** Broad orientation across the LangChain ecosystem.

Expected value:

- gives the manager a map of the ecosystem;
- helps distinguish responsibilities across LangChain, LangGraph, Deep Agents, RAG, and LangSmith;
- supports initial problem classification;
- helps route requests to the right specialist;
- supports architecture-level awareness without making the manager the implementation owner of every subsystem.

Manager usage:

- classify the problem before delegation;
- identify cross-cutting dependencies;
- select the right specialists;
- recognize when a request is outside the supported project scope;
- review specialist proposals at system level.

It should not be treated as a replacement for the specialists' deeper domain Skills.

## 5.2 `langchain-fundamentals`

**Assigned profile:** `langchain-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- core LangChain abstractions;
- model interfaces as application components;
- prompt construction;
- runnable composition;
- chains and execution composition;
- tool definitions and tool calling;
- agent construction;
- structured output;
- integration boundaries among components.

The Specialist must verify that APIs and examples match the actual package versions in the project rather than copying an example blindly.

## 5.3 `langchain-middleware`

**Assigned profile:** `langchain-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- middleware architecture;
- runtime interception and lifecycle logic;
- cross-cutting behavior around agent execution;
- policy enforcement points;
- execution instrumentation and controlled behavior.

The specialist should explain whether a concern belongs in middleware, a tool, a node, an application service, or an outer orchestration layer. Middleware should not become an indiscriminate dumping ground for unrelated application logic.

## 5.4 `langchain-dependencies`

**Assigned profile:** `langchain-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- dependency selection and installation;
- package compatibility;
- LangChain package boundaries;
- environment consistency;
- version pinning and upgrades;
- reproducible Python environments.

The specialist should identify the exact package and version requirements and report any dependency conflict. Adding or upgrading dependencies is an L2-sensitive action under this design and may require approval.

## 5.5 `langgraph-fundamentals`

**Assigned profile:** `langgraph-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- StateGraph design;
- state schema and ownership;
- node definitions;
- edge and conditional-edge design;
- reducers and state updates;
- routing and execution flow;
- workflow composition;
- deterministic control-flow boundaries.

The specialist should explicitly define state ownership and update semantics, because unclear state mutation is a common source of multi-step workflow defects.

## 5.6 `langgraph-human-in-the-loop`

**Assigned profile:** `langgraph-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- interrupts;
- human approval points;
- pause/resume behavior;
- approval workflows;
- safe handling of sensitive actions;
- explicit handoff between automated and human-controlled steps.

The specialist should not treat a human-in-the-loop mechanism as a substitute for security controls. A tool or environment boundary must still enforce the action policy.

## 5.7 `langgraph-cli`

**Assigned profile:** `langgraph-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded installation example:** raw GitHub URL under `config/skills/langgraph-cli/SKILL.md`  
**Recorded install verdict:** SAFE

Expected coverage:

- LangGraph CLI workflows;
- project development and operational commands;
- local development lifecycle;
- command-line integration and validation.

All commands must be checked against the installed CLI version. Do not assume the current online documentation exactly matches the environment.

## 5.8 `deep-agents-core`

**Assigned profile:** `agent-systems-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- Deep Agent architecture;
- complex task decomposition;
- agent-level planning;
- long-running or multi-stage work;
- organization of tools and responsibilities.

The specialist must distinguish a genuinely complex agent problem from a workflow that would be simpler and more reliable as ordinary application code or a LangGraph graph.

## 5.9 `deep-agents-orchestration`

**Assigned profile:** `agent-systems-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- agent coordination;
- delegation strategies;
- subagent structures;
- work decomposition;
- orchestration policy;
- coordination and handoff patterns.

This Skill concerns the architecture of agents in the user's LangChain application. It does not grant the Hermes specialist permission to create nested Hermes subagents. Hermes-level orchestration remains centralized in the manager unless changed explicitly.

## 5.10 `deep-agents-memory`

**Assigned profile:** `agent-systems-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- memory architecture for application agents;
- durable and transient memory choices;
- memory retrieval and update patterns;
- context management;
- memory boundaries and lifecycle.

Important distinction: this Skill concerns memory in the LangChain/Deep Agents systems being engineered. It does not imply that the Hermes specialist needs broad access to Hermes profile memory or another profile's private state.

## 5.11 `langchain-rag`

**Assigned profile:** `rag-specialist`  
**Source family:** `langchain-ai/langchain-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- source ingestion;
- document normalization and processing;
- splitting and chunking;
- embeddings;
- vector stores and vector databases;
- retrieval algorithms;
- metadata filters;
- hybrid retrieval;
- reranking;
- context assembly;
- grounded answer generation;
- citations and traceability.

The specialist must optimize retrieval quality and evidence traceability, not merely produce a functioning vector search demo.

## 5.12 `eval-engineering`

**Assigned profile:** `evaluation-specialist`  
**Source family:** `langchain-ai/langchain-skills` or associated official LangChain Skills source family as recorded  
**Recorded install verdict:** SAFE

Expected coverage:

- evaluation methodology;
- datasets and test cases;
- metrics and criteria;
- evaluator design;
- LLM-as-judge patterns;
- regression testing;
- failure categorization;
- measurement validity.

Metrics must reflect user-visible quality and system requirements. The evaluator must not optimize a metric in a way that hides regressions or undermines system correctness.

## 5.13 `langsmith-experiment-diagnosis`

**Assigned profile:** `evaluation-specialist`  
**Source family:** `langchain-ai/langsmith-skills`  
**Recorded install verdict:** SAFE

Expected coverage:

- LangSmith experiment interpretation;
- trace and run diagnosis;
- identifying failure patterns;
- comparing experiment outcomes;
- debugging evaluation results;
- relating observed failures to system components.

The specialist should attach evidence to conclusions: relevant runs, trace IDs, dataset examples, evaluator outputs, and reproduction notes when available.

## 5.14 `langsmith-online-eval-engineering`

**Assigned profile:** `evaluation-specialist`  
**Source family:** `langchain-ai/langsmith-skills`  
**Recorded install verdict:** SAFE

Recorded included files:

```text
SKILL.md
references/evaluator-design.md
references/langsmith-api.md
references/trace-inspection.md
```

Expected coverage:

- online evaluation architecture;
- evaluator design;
- evaluation of production traces;
- LangSmith API reference usage;
- trace inspection;
- continuous quality monitoring.

The specialist should distinguish offline benchmark quality from online production behavior. Credentials and connections to LangSmith remain subject to user-controlled configuration and approval.

---

# 6. Skill-to-Profile Assignment and Loading Policy

## 6.1 Intended mapping

| Profile | Approved Skills |
|---|---|
| `langchain-engineer` | `ecosystem-primer` |
| `langchain-specialist` | `langchain-fundamentals`, `langchain-middleware`, `langchain-dependencies` |
| `langgraph-specialist` | `langgraph-fundamentals`, `langgraph-human-in-the-loop`, `langgraph-cli` |
| `agent-systems-specialist` | `deep-agents-core`, `deep-agents-orchestration`, `deep-agents-memory` |
| `rag-specialist` | `langchain-rag` |
| `evaluation-specialist` | `eval-engineering`, `langsmith-experiment-diagnosis`, `langsmith-online-eval-engineering` |
| `production-specialist` | No dedicated Skill from the approved 14-item set at this stage |

## 6.2 Assignment principles

- A profile should receive only the Skills it needs for its role.
- Do not install all 14 Skills into every profile by default.
- Do not duplicate the same Skills across profiles without a clear need.
- The manager needs ecosystem-level context, not every specialist's full Skill package.
- The Production Specialist must not be given an unrelated Skill merely to make the table look symmetrical.
- If a later task genuinely needs cross-domain guidance, the manager can include relevant excerpts or context in the task brief rather than expanding every profile's permanent Skill inventory.
- Skill assignment should be verified after profile creation by inspecting the actual per-profile Skill list.

## 6.3 Future Skill additions

A new Skill should be considered only if:

1. It fills a clearly identified capability gap.
2. The current 14 Skills and official documentation do not already cover the need adequately.
3. Its source and maintainer are reviewed.
4. Its full contents and scripts are inspected.
5. Its dependencies are pinned or otherwise justified.
6. Network and shell behavior are understood.
7. The security scanner result is reviewed.
8. The user explicitly approves its addition.

A Skill search result is a candidate, not an installation approval.

---

# 7. Target Agent Architecture

## 7.1 Logical topology

```text
                              USER
                                |
                                v
             +--------------------------------------+
             |       LANGCHAIN LEAD ARCHITECT       |
             |        Profile: langchain-engineer   |
             |                                      |
             | Intake, analysis, architecture,      |
             | task routing, delegation, QA,         |
             | integration, final delivery           |
             +------------------+-------------------+
                                |
              Internal Hermes delegation via routes
                                |
        +-----------+-----------+-----------+-----------+
        |           |           |           |           |
        v           v           v           v           v
  +-----------+ +-----------+ +-----------+ +-----------+ +-----------+
  | LangChain | | LangGraph | |   Agent   | |    RAG    | | Evaluation|
  | Engineer  | | Engineer  | |  Systems  | | Engineer  | | Engineer  |
  +-----------+ +-----------+ +-----------+ +-----------+ +-----------+
                                |
                                v
                         +-------------+
                         | Production  |
                         |  Engineer   |
                         +-------------+
```

The diagram is conceptual. It does not imply that Production is a child of Agent Systems; all six specialists are direct routes from the manager. The layout above simply keeps the diagram compact.

## 7.2 Why one central manager

A central manager avoids:

- multiple agents issuing conflicting instructions;
- untracked nested delegation;
- duplicated work;
- inconsistent architecture decisions;
- unclear ownership of final integration;
- ambiguous responsibility for the answer delivered to the user.

The manager is accountable for system-level coherence. Specialists are accountable for domain-level correctness within assigned tasks.

## 7.3 Why six specialists

The six specialist areas cover distinct engineering disciplines that frequently interact in LangChain systems:

- LangChain component implementation;
- LangGraph workflow control;
- agent-system design and coordination;
- retrieval and grounded knowledge access;
- evaluation and observability of quality;
- production engineering and operational readiness.

The split is intentionally not one agent per library or one agent per tiny feature. Each role is a coherent engineering discipline with enough scope to own a meaningful workstream.

## 7.4 Architecture evolution note

The available project record includes an earlier discussion of alternative team sizes and role allocations. The current consolidated LangChain target is **one manager plus six specialists**. Do not revive an earlier larger team count unless the user explicitly reopens the architecture. This project should not inherit the separate website-design project's team structure.

---

# 8. Role Charters: Detailed Responsibilities, Boundaries, Inputs, and Outputs

## 8.1 Central Manager — `langchain-engineer`

### Mission

Own the end-to-end engineering outcome, preserve architecture coherence, and ensure that delegated work is relevant, verifiable, and integrated.

### Core responsibilities

1. Understand the user request and resolve its scope from known context.
2. Identify functional and non-functional requirements.
3. Classify the work mode: Design, Implementation, Debugging, or Review.
4. Decide whether to work directly or delegate.
5. Choose only the specialists necessary for the current task.
6. Define task dependencies and parallelizable work.
7. Establish interface and data contracts before parallel implementation.
8. Provide each specialist with the exact relevant context and constraints.
9. Evaluate each specialist's handoff against acceptance criteria.
10. Resolve contradictions among specialist recommendations.
11. Request revisions when the work is incomplete or unsupported.
12. Integrate outputs and check cross-domain compatibility.
13. Ensure tests and safety checks are performed or clearly marked not run.
14. Deliver a user-facing response that accurately represents actual work.
15. Keep a decision record for important architectural choices.

### Authority

The manager may:

- create and assign tasks;
- choose specialists;
- set task ordering and concurrency;
- establish project-level interfaces and contracts;
- reject incomplete or inconsistent handoffs;
- request changes and additional verification;
- coordinate integration;
- recommend a technical path and explain trade-offs;
- decide that a specialist is unnecessary for a simple task.

### Restrictions

The manager may not:

- choose or change models/providers on behalf of the user;
- read or expose credentials without necessity and authorization;
- authorize itself to perform a user-reserved critical action;
- perform destructive actions without required approval;
- change unrelated Hermes profiles or global settings;
- claim that delegated work, code changes, tests, or deployment occurred without evidence;
- treat every specialist opinion as authoritative;
- create arbitrary permanent Skill or tool permissions.

### Inputs

- user request;
- current project documentation;
- repository state and relevant files;
- approved Skills;
- specialist reports;
- previous architectural decisions;
- constraints and approvals explicitly provided by the user.

### Required outputs

- task classification;
- architecture or implementation plan appropriate to scope;
- delegation decisions and task briefs;
- integration decisions;
- verification summary;
- final result and limitations.

### Manager acceptance criteria

- task scope is clear;
- selected specialists are justified;
- no avoidable delegation occurs;
- dependent tasks are ordered correctly;
- parallel work has non-overlapping ownership or isolated branches;
- all handoffs are evaluated;
- unresolved risks are reported;
- user approvals are obtained where required;
- final statements match actual evidence.

## 8.2 LangChain Specialist — `langchain-specialist`

### Mission

Design and implement the core LangChain application components and their integration contracts.

### Owns

- prompt and message construction;
- runnable composition;
- model interface integration as an application-level component (without choosing the user's model/provider configuration);
- tool definitions and tool calling;
- agent construction;
- structured output;
- middleware;
- core LangChain dependency compatibility;
- component-level unit tests;
- LangChain-specific debugging.

### Does not own

- graph-level workflow architecture where LangGraph is the appropriate owner;
- overall multi-agent topology;
- RAG retrieval quality as a whole;
- evaluation strategy for the entire system;
- production deployment authorization.

### Inputs expected

- approved architecture;
- required component behavior;
- interfaces from RAG or other services;
- existing dependency constraints;
- expected input/output schemas;
- task-specific restrictions.

### Handoff must include

- files changed or created;
- component design and interface contracts;
- dependency changes proposed or made;
- exact commands executed;
- tests and outcomes;
- compatibility notes;
- known limitations;
- integration instructions.

## 8.3 LangGraph Specialist — `langgraph-specialist`

### Mission

Own stateful workflow architecture and reliable graph execution.

### Owns

- graph topology;
- state schemas;
- state ownership and update rules;
- nodes and edges;
- conditional routing;
- reducers;
- interrupts and resume behavior;
- human approval points;
- checkpointing and persistence design;
- recovery behavior;
- graph-level integration tests.

### Does not own

- the entire agent ecosystem topology;
- all Deep Agents planning and delegation concerns;
- vector retrieval implementation;
- deployment approval;
- unrelated application services.

### Required design checks

- Is a graph actually needed, or would a simpler chain/service suffice?
- What is the authoritative state schema?
- Which node owns each state field?
- Are state updates deterministic and merge-safe?
- What happens on node failure?
- Can a workflow resume safely after an interrupt?
- What is checkpointed and for how long?
- Are persistence credentials handled without exposing secrets?
- Are repeated or resumed operations idempotent where required?

### Persistence note

The project does not include the rejected `langgraph-persistence` Skill. Persistence itself remains allowed as a technical capability. Implementations must use official documentation and reviewed code; secrets must not be read, printed, or embedded in examples unnecessarily.

## 8.4 Agent Systems Specialist — `agent-systems-specialist`

### Mission

Design the agent-level system: planning, decomposition, multi-agent patterns, subagent roles, memory, and coordination.

### Owns

- Deep Agents patterns;
- agent planning;
- task decomposition;
- subagent architecture within the user's LangChain application;
- inter-agent contracts;
- application-level multi-agent coordination;
- agent memory design;
- context handoff;
- delegation strategy for agents being built as part of the user's product.

### Does not own

- Hermes-level authority to create other Hermes subagents;
- all LangGraph graph implementation details;
- low-level LangChain component implementation;
- production credential administration.

### Important distinction

The `deep-agents-orchestration` Skill is for designing systems in the user's LangChain application. It does not override the Hermes-team policy that the central manager alone performs internal Hermes delegation. These are separate layers of orchestration.

## 8.5 RAG Specialist — `rag-specialist`

### Mission

Build reliable, traceable retrieval systems that provide relevant evidence to generation components.

### Owns

- source discovery and ingestion architecture;
- document parsing and normalization;
- metadata design;
- chunking strategy;
- embeddings integration;
- vector store/database integration;
- lexical and hybrid retrieval;
- filtering;
- reranking;
- context assembly;
- grounding and evidence citation;
- retrieval diagnostics;
- retrieval-specific tests.

### Does not own

- global evaluation methodology;
- arbitrary database administration outside assigned scope;
- unrestricted access to external services;
- final system architecture independent of the manager.

### Required quality checks

- source coverage;
- duplicate handling;
- chunk boundary quality;
- metadata correctness;
- retrieval recall and precision where measurable;
- relevance of top-k results;
- filtering correctness;
- reranking impact;
- stale-source handling;
- citation traceability;
- access-control enforcement for tenant/private data;
- graceful handling of empty or conflicting retrieval results.

## 8.6 Evaluation Specialist — `evaluation-specialist`

### Mission

Create an evidence-based measurement system for the quality, reliability, and regression behavior of the application.

### Owns

- evaluation strategy;
- representative datasets;
- test case design;
- criteria and metrics;
- deterministic and model-based evaluators;
- LLM-as-judge design;
- experiment planning;
- offline evaluation;
- online evaluation;
- LangSmith trace/experiment diagnosis;
- error taxonomy;
- regression reports;
- evaluation validity and limitations.

### Does not own

- unilateral architecture changes merely to improve one metric;
- release authorization;
- modification of application behavior without the owning specialist and manager;
- access to live production traces or credentials without explicit project authorization.

### Required evaluation discipline

- define the question each metric answers;
- identify known blind spots;
- avoid data leakage between test and evaluation sets;
- use human-labeled references when appropriate;
- calibrate and validate LLM judges;
- report sample size and uncertainty;
- segment results by failure type;
- compare changes against a baseline;
- never equate a single aggregate score with production readiness.

## 8.7 Production Specialist — `production-specialist`

### Mission

Make the application testable, secure, operable, and ready for controlled deployment.

### Owns

- API and backend integration;
- application packaging and runtime setup;
- unit/integration/E2E test infrastructure;
- security review and secure coding practices;
- secrets-handling design;
- dependency and supply-chain review;
- timeouts and retries;
- resilience and fault handling;
- logging, monitoring, and observability;
- CI/CD design;
- deployment preparation;
- performance and latency analysis;
- cost and resource optimization;
- operational runbooks.

### Does not own

- independent changes to LangChain, LangGraph, RAG, or evaluation architecture without coordination;
- approval to deploy to a real environment;
- unrestricted production access;
- permanent access to every secret or database.

### Current Skill gap

No dedicated Production Skill is included in the approved 14-item package. This is intentional. The specialist should use current official documentation, repository evidence, tests, and project engineering standards. Candidate Skills may be reviewed later, but no Skill should be installed merely to fill this gap.

---

# 9. Responsibility Matrix and Specialist Collaboration

## 9.1 High-level ownership matrix

Legend: **A** = accountable owner, **R** = responsible contributor, **C** = consulted, **I** = informed.

| Work area | Manager | LangChain | LangGraph | Agent Systems | RAG | Evaluation | Production |
|---|---:|---:|---:|---:|---:|---:|---:|
| Overall architecture | A | C | C | C | C | C | C |
| Core LangChain components | A | R | C | C | C | I | C |
| Stateful graph workflow | A | C | R | C | C | C | C |
| Deep Agent topology | A | C | C | R | C | C | C |
| Retrieval pipeline | A | C | C | C | R | C | C |
| Evaluation strategy | A | C | C | C | C | R | C |
| Production readiness | A | C | C | C | C | C | R |
| Cross-domain integration | A/R | C | C | C | C | C | C |
| Final acceptance | A | C | C | C | C | C | C |

This matrix is a proposed operating model, not a claim about existing runtime authorization.

## 9.2 Common collaboration patterns

| Problem | Primary owner | Supporting specialists |
|---|---|---|
| Basic LangChain agent with tools | LangChain | Production; Evaluation if quality criteria matter |
| Stateful workflow with branches | LangGraph | LangChain; Production |
| Application-level multi-agent system | Agent Systems | LangGraph; LangChain; Evaluation |
| Document RAG application | RAG | LangChain; Evaluation; Production |
| RAG quality regression | Evaluation | RAG; Production if instrumentation is needed |
| LangSmith evaluation setup | Evaluation | Production for secure integration; LangChain as needed |
| Production API around an agent | Production | LangChain; LangGraph or Agent Systems as applicable |
| Incident involving graph resume | LangGraph | Production; Evaluation if traces/datasets help |
| Retrieval latency/cost issue | RAG | Production; Evaluation |
| Full production architecture | Manager | All relevant specialists, not automatically every specialist |

---

# 10. Delegation Operating Protocol

## 10.1 Delegation principle

Delegation is a way to obtain focused expertise and parallel progress. It is not a ritual that must happen for every request.

The manager should decide whether delegation is justified based on:

- technical complexity;
- number of domains involved;
- independence of workstreams;
- need for independent review;
- task duration/size;
- risk of inconsistent outputs;
- expected value relative to coordination overhead.

## 10.2 Delegation thresholds

| Request class | Expected manager behavior |
|---|---|
| Simple explanation or small code question | Handle directly |
| One-domain implementation/debug task | Delegate to the relevant specialist when specialized work is valuable; otherwise handle directly |
| Two-domain issue | Delegate to one or two owners with an explicit interface |
| Cross-domain design | Delegate to relevant specialists, then reconcile through the manager |
| Large project | Break into workstreams, define dependencies, assign owners, and integrate iteratively |
| High-risk/security-sensitive work | Involve Production and relevant domain owner; require approval for sensitive actions |

Do not call all six specialists merely because they exist.

## 10.3 Standard task contract

Every delegated task should carry the following information:

1. **Task** — one precise objective.
2. **Context** — only the project facts and files needed.
3. **Constraints** — technical, security, scope, and version limitations.
4. **Expected Output** — exact artifacts or decisions expected.
5. **Acceptance Criteria** — observable conditions for acceptance.
6. **Dependencies** — prerequisite decisions, interfaces, or outputs.
7. **Risks** — likely failure modes and sensitive operations.
8. **Verification** — tests, commands, or evidence required.
9. **Handoff** — file list, decisions, open questions, test results, and limitations.

### Delegation task template

```text
TASK
[One clear task statement]

CONTEXT
[Relevant project background, repository state, prior decisions]

SCOPE
[What is included]

OUT OF SCOPE
[What must not be changed or decided]

CONSTRAINTS
[Versions, interfaces, security rules, dependencies, coding standards]

EXPECTED OUTPUT
[Files, design, code, tests, report, or decision]

ACCEPTANCE CRITERIA
[Specific, observable pass conditions]

DEPENDENCIES
[Prerequisites and owners]

RISKS
[Failure modes, security concerns, compatibility risks]

VERIFICATION
[Commands/tests/review evidence to provide]

HANDOFF
[Changed files, key decisions, test results, known limitations, next steps]
```

## 10.4 Parallel execution policy

Tasks may be parallelized only when:

- their dependencies are satisfied;
- ownership boundaries are explicit;
- shared interfaces have been defined;
- they do not edit the same files simultaneously, or they have isolated worktrees/branches;
- integration responsibility remains with the manager.

Tasks must be sequential when:

- later work depends on a prior interface or schema;
- one specialist must review or validate another's output;
- database migrations or state changes have ordering constraints;
- a design decision is unresolved and would cause rework if parallelized.

## 10.5 Nested delegation policy

**[DECIDED]** Specialists are leaf agents by default. They do not call other Hermes subagents. The manager controls the delegation tree.

If a future use case needs specialist-level delegation, it requires a deliberate architecture revision, a clear reason, and tests for recursion, resource usage, failure propagation, and accountability. The current baseline does not permit it.

## 10.6 Concurrent subagent limit

An earlier discussion mentioned a possible default concurrency limit of three subagents. The exact behavior for Hermes `v0.22.7` was not verified in the available project record. Treat this as **[NOT VERIFIED]**, not as a hard design constraint. Inspect the installed implementation/documentation or run a controlled test before relying on a numerical limit.

## 10.7 Delegation handoff review

The manager must inspect each handoff for:

- completeness against the task contract;
- compatibility with the existing architecture;
- consistency with other specialists' outputs;
- evidence supporting claims;
- test status and actual command output;
- unresolved assumptions;
- security and permission compliance;
- unexpected scope expansion;
- dependency changes;
- file ownership and integration risks.

An incomplete handoff must be returned for revision or accepted with explicit caveats; it must not be silently integrated.

---

# 11. Hermes Delegation Modes and `advanced-delegation`

## 11.1 Default delegation behavior

The installed `default` delegation plugin/strategy was described as using delegation settings from `config.yaml` (including a delegation provider/model/base URL configuration) or inheriting the parent's model and credentials when no explicit delegation route is configured.

This behavior is not the desired final model for this project because the goal is to invoke independent Hermes profiles with their own profile-level configuration.

## 11.2 `advanced-delegation` discovery record

The user ran:

```powershell
hermes plugins search advanced-delegation
```

The catalogue returned an official result, version `1.1.1`.

The user then ran:

```powershell
hermes plugins info advanced-delegation
```

Recorded information:

| Attribute | Value |
|---|---|
| Plugin | `advanced-delegation` |
| Catalogue/source | Official |
| Maintainer | NousResearch |
| Version | `1.1.1` |
| Pinned SHA | `13b2c1c9c8204bf333df240b2aacf98c3e6250b7` |
| Minimum Hermes version | `0.22.5` |
| Installed Hermes | `0.22.7` |
| New tools | None listed |
| Hooks | None listed |
| Middleware | None listed |
| Python dependencies | None listed |
| Configuration writes | `delegation.backend` and `delegation.backends.*` in active profile's `config.yaml` |

The plugin documentation described two extra `delegate_task` modes alongside the built-in default:

- `model_map` — named model routes;
- `profile_routes` — route to independent Hermes profiles.

## 11.3 Preferred backend: `profile_routes`

**[DECIDED AS DESIGN DIRECTION]** The appropriate backend for this architecture is `profile_routes`.

Why:

- the six specialists are intended to be independent Hermes profiles;
- each specialist should own its own Skills;
- each specialist should have its own `SOUL.md` and profile-level policies;
- the user will independently manage model/provider configuration for each profile;
- the manager should select a specialist route rather than selecting a model directly.

The plugin description says that only route names and one-line descriptions reach the manager model. A routed subagent runs using the selected profile's own model, credentials, Skills, `SOUL.md`, and terminal policy.

## 11.4 Why not `model_map`

`model_map` is designed for named model routing. It is unnecessary for this project because the user explicitly owns model/provider configuration.

The plugin information also warned that an optional `api_key` for a model route is stored in `config.yaml` in plaintext. Although this is not the selected mode, the warning reinforces the decision not to design model routes here.

## 11.5 Installation scope

The recorded recommendation was to install `advanced-delegation` only in the manager profile, because the manager is the sole orchestrator. It should not be installed on every specialist unless a future design change specifically needs it.

**Current status:** discovered and inspected, **not installed**.

## 11.6 A2A distinction

A2A is for protocol-level communication with other agents/services. Internal Hermes profile delegation is handled through `delegate_task` and the selected delegation backend.

For the current team:

- internal manager-to-specialist calls: `delegate_task` + `profile_routes`;
- external agent interoperability: A2A only if a future requirement justifies it;
- do not use A2A as a substitute for profile routing;
- do not expose A2A network endpoints merely to make internal delegation work.

---

# 12. Profile Design and Creation Strategy

## 12.1 Target profile names

```text
langchain-engineer          # Central manager
langchain-specialist        # LangChain domain specialist
langgraph-specialist        # LangGraph domain specialist
agent-systems-specialist    # Deep Agents and multi-agent specialist
rag-specialist              # Retrieval-augmented generation specialist
evaluation-specialist       # Evaluation and LangSmith specialist
production-specialist       # Production engineering specialist
```

The profile naming scheme is a proposed convention based on the architecture. Confirm naming collisions in the live environment before creation.

## 12.2 Independent profile creation

The inspected CLI help showed profile creation options including:

```text
--clone
--clone-all
--clone-from SOURCE
--clone-channels
--sync-imports
--no-alias
--no-skills
--description DESCRIPTION
```

The recorded design recommendation is to create new project profiles without cloning another profile. The reason is that cloning may copy configuration, `.env`, `SOUL.md`, and Skills, which risks importing unrelated credentials or permissions.

A manager creation command was proposed as an example:

```powershell
hermes profile create --no-skills --description "LangChain Lead Architect and Engineering Manager" langchain-engineer
```

**This command is a plan/example, not an executed command.**

The six specialist profiles should likewise be created independently with `--no-skills`, then assigned only their approved Skills.

## 12.3 Profile independence checklist

For each new profile, verify:

- the profile exists under the intended name;
- it was not cloned from an unrelated profile;
- its own `config.yaml` is present;
- its own `SOUL.md` is present and role-specific;
- only approved Skills are assigned;
- no unrelated `.env` or authentication data was copied;
- channel bindings are absent unless explicitly required;
- the selected model/provider remains user-managed;
- tool permissions match the approved access design;
- terminal policy and runtime isolation are understood;
- the profile does not possess Hermes delegation by default.

## 12.4 Profile routing allowlist

The manager's `profile_routes` should expose only these six specialist profile names. It should not include:

- `default`;
- `agent-1-cto` through `agent-8-qa`;
- profiles belonging to website-development or unrelated projects;
- any profile whose credential or terminal policy has not been reviewed.

---

# 13. Tool Access and Least-Privilege Design

## 13.1 Three distinct layers

The project must not confuse these concepts:

1. **Role policy:** What an agent is supposed to do.
2. **Tool permission:** Which Hermes capabilities the profile can actually invoke.
3. **Runtime/resource isolation:** What the process is technically prevented from accessing.

A `SOUL.md` instruction is role policy. It is not a filesystem sandbox. A global `hermes tools list` is a tool availability snapshot. It is not proof of per-profile access control.

## 13.2 Proposed manager tool access

The manager's proposed baseline includes:

- `skills` — read/use the manager's approved Skill;
- `web` — official documentation and current technical research;
- `file` — inspect relevant project files and reports;
- `terminal` — controlled project-level commands where necessary;
- `code_execution` — calculations or controlled code validation if useful;
- `todo` — task planning;
- `memory` — manager-level durable project context, if appropriately isolated;
- `session_search` — retrieve relevant project history where available;
- `clarify` — obtain user clarification when essential;
- `delegation` — invoke the six specialist profiles.

Tools such as `browser`, `computer_use`, `cronjob`, media generation, X search, messaging integrations, and A2A should not be enabled for the manager by default merely because they are globally available. Add them only for a concrete requirement and after reviewing the associated permissions.

## 13.3 Proposed specialist tool access

Specialists need development-oriented capabilities:

- `skills`;
- `web`;
- `file`;
- `terminal`;
- `code_execution`.

Specialists should not have Hermes-level `delegation` in the baseline. They should not need `browser`, `computer_use`, `cronjob`, A2A, messaging channels, image/video/audio generation, or unrelated integrations for ordinary LangChain engineering tasks.

Memory access is not automatically required. The preferred source of project truth is the repository and the task brief. If a specialist-specific persistent memory is later enabled, its scope and privacy must be explicitly defined.

## 13.4 Proposed access matrix

| Capability | Manager | LangChain | LangGraph | Agent Systems | RAG | Evaluation | Production |
|---|---:|---:|---:|---:|---:|---:|---:|
| Skills | Yes | Yes | Yes | Yes | Yes | Yes | If needed |
| Web/documentation | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| File read | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| File write | Scoped | Scoped | Scoped | Scoped | Scoped | Scoped | Scoped |
| Terminal | Controlled | Task-scoped | Task-scoped | Task-scoped | Task-scoped | Task-scoped | Task-scoped |
| Code execution | As needed | Yes | Yes | Yes | Yes | Yes | Yes |
| Hermes delegation | Yes | No | No | No | No | No | No |
| Browser automation | Case-specific | No by default | No by default | No by default | No by default | No by default | Case-specific |
| Computer use | No by default | No | No | No | No | No | No by default |
| Persistent Hermes memory | Manager-only baseline | No by default | No by default | No by default | No by default | No by default | No by default |
| Cron jobs | No by default | No | No | No | No | No | No |
| A2A | No by default | No | No | No | No | No | No |
| Image/video/audio generation | No by default | No | No | No | No | No | No |

This is an intended least-privilege policy, not an implemented configuration. Toolset-level and individual-tool enforcement must be confirmed against the installed Hermes version.

## 13.5 File tool granularity

A prior discussion noted that the File toolset may contain distinct operations such as reading, writing, searching, or editing. It may be preferable to permit read operations more broadly while restricting write operations to scoped tasks. The exact names and policy controls must be confirmed from the installed version's tool help and configuration schema before writing a configuration.

## 13.6 Do not confuse availability with authorization

A globally enabled toolset does not imply:

- that every profile should have it;
- that every tool inside the toolset should be allowed;
- that the agent may use it for any purpose;
- that its filesystem/network scope is limited;
- that a prompt instruction is an effective security boundary.

---

# 14. Operational Approval Levels

The project uses four proposed operation levels to make authorization predictable.

## L0 — Read and inspect

Examples:

- read project files;
- inspect source code;
- review documentation;
- inspect non-secret configuration;
- search official documentation;
- analyze test output;
- diagnose errors without changing state.

Policy: ordinarily allowed within the assigned workspace and access scope.

## L1 — Reversible development

Examples:

- create or edit project code;
- add tests;
- produce local artifacts;
- run local unit or integration tests;
- make scoped changes in a dedicated branch/worktree.

Policy: allowed only within the assigned Task and workspace, with the change summarized in the handoff. The actual repository policy and user instructions take precedence.

## L2 — Sensitive or externally connected operations

Examples:

- add or update packages;
- alter dependency lock files;
- connect to external APIs or databases;
- change environment configuration;
- create or modify database schema;
- perform migrations in non-production environments;
- access secrets or privileged resources;
- modify system-level settings.

Policy: require explicit task-level authorization and, when sensitive or beyond the user's standing instructions, user approval. Never print secret values.

## L3 — Critical or irreversible operations

Examples:

- production deployment;
- deleting persistent or customer data;
- destructive database migrations;
- changing production permissions;
- enabling paid resources or creating billable services;
- rotating or revoking critical credentials;
- irreversible infrastructure changes.

Policy: explicit user approval is required. A manager's internal delegation instruction cannot substitute for user approval.

## 14.1 Secret-handling rules

- Never print the contents of `.env`, authentication files, tokens, passwords, or private keys.
- Do not copy credentials between profiles.
- Do not attach secrets to specialist task briefs.
- Prefer environment-based or platform-supported secret injection.
- A specialist should report that a credential is missing without attempting to reveal it.
- Do not store secrets in source code, Skill files, Markdown reports, logs, or task handoffs.
- Treat profile credentials as isolated assets.

## 14.2 Dependency governance

Before adding a dependency, report:

- package name;
- version or version range;
- source/index;
- purpose;
- why the standard library or existing dependency is insufficient;
- compatibility with the Python and framework versions;
- license and maintenance concerns where relevant;
- security scan/advisory considerations;
- files changed;
- rollback path.

Pin dependencies for reproducible environments according to the project's packaging strategy. Do not silently upgrade a framework package as part of an unrelated fix.

---

# 15. Workspace Isolation, Windows Runtime, and Git Worktrees

## 15.1 The core risk

A profile's `terminal.cwd` is a starting directory, not necessarily a security boundary. An agent may still be able to use absolute paths, parent-directory traversal, shell commands, or other available tools to access files outside that directory unless the runtime enforces restrictions.

Likewise, a written instruction such as “only edit the assigned project directory” is not a technical sandbox.

## 15.2 Isolation options to evaluate

Potential controls include:

- a dedicated project workspace;
- filesystem permissions enforced by the operating system;
- a container or other isolated runtime;
- a restricted execution environment;
- separate Git branches or worktrees;
- narrowly scoped file tools where supported;
- explicit command allowlists or execution policies where supported.

The actual available and compatible mechanism must be verified on the user's Windows installation. Do not assume that Linux container instructions apply directly to this Windows environment.

## 15.3 Git Worktree proposal

Hermes CLI help was observed to include a `--worktree` option. Worktrees may help isolate parallel code changes by assigning each workstream a separate working tree or branch.

Potential benefits:

- reduce simultaneous writes to the same files;
- make parallel tasks easier to review;
- permit clean diffs and rollback;
- make ownership of changes visible;
- reduce integration conflicts.

Unverified questions:

- whether Hermes profile delegation automatically creates a worktree;
- whether each `profile_routes` task can be bound to a distinct worktree;
- how branch names and cleanup are handled;
- whether the manager can reliably collect and integrate changes;
- whether filesystem restrictions are enforced beyond Git's directory layout.

Git worktrees are a collaboration/isolation mechanism for changes, not a complete security sandbox by themselves.

## 15.4 File ownership during parallel tasks

Before parallel edits:

1. define file/module ownership;
2. agree on shared interfaces;
3. create isolated branches/worktrees if available;
4. avoid multiple writers for the same file;
5. require each specialist to report changed files;
6. let the manager integrate and resolve conflicts;
7. run tests after integration, not only before it.

---

# 16. Memory, Project Truth, and Knowledge Handoffs

## 16.1 Source of truth hierarchy

Recommended source-of-truth order:

1. explicit current user instruction;
2. approved project decisions and constraints;
3. current repository code, configuration, and tests;
4. current official documentation for the installed version;
5. verified specialist findings;
6. prior conversation context and memory;
7. unverified assumptions.

If repository code conflicts with an old conversation summary, inspect the repository and ask the manager to reconcile the decision.

## 16.2 Manager memory

Manager memory may store durable project context such as:

- architecture decisions;
- approved role boundaries;
- user preferences relevant to the project;
- known environment constraints;
- unresolved technical questions;
- recurring workflow conventions.

Do not use memory as a substitute for repository documentation or configuration.

## 16.3 Specialist memory

The baseline should not grant broad cross-profile memory access. Specialists should receive the current task brief and relevant project files. Any specialist-specific memory should be independent, scoped, and documented.

## 16.4 Durable project documents

Recommended repository documentation (names are proposals):

```text
README.md
ARCHITECTURE.md
AGENT_TEAM.md
DECISIONS.md
SECURITY.md
TOOL_ACCESS_POLICY.md
DELEGATION_PROTOCOL.md
SKILL_INVENTORY.md
TEST_STRATEGY.md
OPERATIONS.md
```

These documents should be kept in the project repository if the user wants a persistent engineering record. The present Markdown file is the consolidated project master specification, not proof that the repository has been created.

---

# 17. Engineering Standards Across the Team

## 17.1 Python-first implementation

**[DECIDED]** Python is the primary implementation language for this project.

General standards:

- use readable, maintainable Python;
- preserve type clarity where practical;
- isolate framework-specific code behind understandable interfaces;
- prefer explicit data contracts;
- avoid unnecessary abstractions;
- keep business logic separate from framework wiring;
- validate untrusted input;
- handle exceptions intentionally;
- use structured logging rather than ad hoc prints in production code;
- keep configuration separate from source code;
- use reproducible dependencies;
- include tests for critical behavior.

## 17.2 Version compatibility

For every implementation:

- inspect the project's existing Python version;
- inspect installed LangChain-related package versions;
- inspect lock files and package metadata;
- use documentation matching the installed version;
- state when an example uses a newer or older API;
- avoid mixing deprecated and current APIs;
- do not upgrade packages without approval where the change is material.

The host's recorded Python version (`3.14.9`) is not necessarily the version of every project virtual environment. Always inspect the actual project interpreter and environment before making compatibility claims.

## 17.3 Architecture simplicity

Do not use LangGraph, Deep Agents, or multi-agent orchestration merely because those technologies are in scope. Choose the simplest architecture that satisfies the requirements.

Examples:

- a straightforward deterministic operation may be ordinary Python;
- a simple sequence may use a chain or runnable composition;
- branching, resumable, stateful workflow may justify LangGraph;
- a complex planning and tool-using agent may justify a Deep Agent;
- document-grounded answering may justify RAG;
- evaluation infrastructure should be designed around the risk and quality requirements.

## 17.4 Error handling

Every important component should define:

- expected errors;
- retryable versus non-retryable conditions;
- timeout behavior;
- recovery or compensation behavior;
- user-visible error semantics;
- logging and tracing requirements;
- safe failure behavior.

Avoid indiscriminate retries that can duplicate writes, charges, or external actions.

## 17.5 Documentation

Document non-obvious decisions, interfaces, state transitions, security-sensitive operations, and operational procedures. Do not write documentation that simply repeats code or creates maintenance burden without improving understanding.

---

# 18. LangChain Engineering Standards

The LangChain Specialist should consider the following design questions for each system:

1. What is the responsibility of each runnable/component?
2. What are the input and output schemas?
3. Which parts are deterministic code and which require model inference?
4. What tools are available to the agent, and what are their side effects?
5. Are tool arguments validated?
6. Are tool results bounded and normalized?
7. Does structured output have schema validation and failure handling?
8. Are middleware behaviors transparent and testable?
9. Are retries and timeouts consistent with tool side effects?
10. Are dependencies compatible with the project's lockfile?
11. Can components be tested independently?
12. Is the implementation more complex than necessary?

## 18.1 Tools and side effects

Tools should declare and document:

- purpose;
- input schema;
- output schema;
- side effects;
- required permissions;
- possible failures;
- timeout/retry behavior;
- idempotency characteristics;
- whether human approval is required.

Do not expose a powerful tool to an agent when a narrower tool can perform the task.

## 18.2 Structured output

For structured results:

- define a schema;
- validate all fields;
- handle missing or malformed fields;
- distinguish a model refusal from a parsing error;
- do not assume schema-constrained generation guarantees semantic correctness;
- test malformed and boundary cases.

## 18.3 Middleware

Middleware should be used for well-defined cross-cutting concerns. Each middleware component should have a clear order, scope, error policy, and test coverage. Avoid hidden state mutation or surprising behavior across unrelated requests.

---

# 19. LangGraph Engineering Standards

The LangGraph Specialist must define the graph contract before implementing nodes.

## 19.1 Graph design checklist

- What problem requires graph-based orchestration?
- What is the state schema?
- Which node owns each state field?
- What does each node consume and produce?
- What are the graph entry and terminal conditions?
- Which edges are unconditional or conditional?
- How are routing decisions validated?
- What state updates may occur concurrently?
- Which reducers are appropriate?
- How are errors represented?
- What happens after interruption?
- How is resume behavior verified?
- What persistence/checkpoint configuration is required?
- What is the retention and cleanup policy?
- How are sensitive state values protected?

## 19.2 Human-in-the-loop

Approval points should be inserted for meaningful human decisions, especially actions that are sensitive, irreversible, or outside a pre-approved scope. The workflow must preserve enough state to resume safely and must not assume approval merely because an interrupt was reached.

## 19.3 Persistence and checkpointing

The design may use persistence when the workflow requires resumability, durable state, or long-running execution. However:

- choose storage based on project requirements;
- keep connection secrets outside source code;
- do not print secret values;
- assess retention and data sensitivity;
- test resume and failure behavior;
- verify compatibility with the actual installed LangGraph packages;
- do not install the removed `langgraph-persistence` Skill as a shortcut.

---

# 20. Deep Agents and Multi-Agent System Standards

The Agent Systems Specialist should justify the use of multi-agent architecture rather than assuming that more agents means better performance.

## 20.1 When multiple agents are justified

Potential reasons:

- distinct bounded domains;
- meaningful parallel research or implementation;
- different tool or data permissions;
- independent review;
- specialized context that would otherwise overload one agent;
- complex planning that benefits from decomposition.

## 20.2 When multi-agent architecture is not justified

Avoid it when:

- the task is small and deterministic;
- specialists would duplicate the same work;
- the agents need the same context and do not have independent responsibilities;
- integration cost exceeds the benefit;
- parallelization creates shared-state hazards;
- the system cannot reliably evaluate the subagent outputs.

## 20.3 Agent contracts

Every agent in the application being built should have:

- one defined purpose;
- bounded tool access;
- explicit inputs and outputs;
- handoff rules;
- failure behavior;
- memory policy;
- evaluation criteria;
- termination conditions.

The application's own multi-agent design must remain separate from the Hermes team structure described in this document.

---

# 21. RAG Engineering Standards

The RAG Specialist should design the full retrieval lifecycle, not only the vector database connection.

## 21.1 Retrieval lifecycle

```text
Source Systems
     |
     v
Ingestion and Access Checks
     |
     v
Parsing / Normalization / Metadata
     |
     v
Chunking and Document Versioning
     |
     v
Embedding and Indexing
     |
     v
Lexical / Vector / Hybrid Retrieval
     |
     v
Filtering and Reranking
     |
     v
Context Assembly and Evidence Selection
     |
     v
Generation / Grounded Answer
     |
     v
Citation, Trace, and Evaluation
```

## 21.2 Design considerations

- source formats and parser quality;
- document versioning and update detection;
- duplicate and near-duplicate handling;
- metadata schema;
- chunk size and overlap rationale;
- parent-child retrieval where useful;
- embedding model compatibility (chosen later by the user, not by this architecture document);
- index rebuild strategy;
- hybrid retrieval trade-offs;
- filtering and access control;
- reranking latency and benefit;
- context window management;
- citation mapping to original sources;
- deletion and source revocation propagation;
- privacy and tenant separation.

## 21.3 RAG evaluation dimensions

Evaluation should consider:

- retrieval relevance;
- recall of required evidence;
- precision of returned context;
- ranking quality;
- answer faithfulness to retrieved evidence;
- answer completeness;
- citation correctness;
- abstention when evidence is insufficient;
- robustness to ambiguous queries;
- source freshness;
- latency and cost.

The Evaluation Specialist owns measurement design; the RAG Specialist owns retrieval-system implementation and retrieval-specific diagnostics.

---

# 22. Evaluation Engineering and LangSmith Standards

## 22.1 Evaluation lifecycle

```text
Requirements and Failure Risks
             |
             v
      Evaluation Plan
             |
             v
   Dataset and Test Cases
             |
             v
     Baseline Evaluation
             |
             v
  Experiments / Candidate Changes
             |
             v
     Comparative Analysis
             |
             v
 Regression Gate / Acceptance
             |
             v
     Online Monitoring
             |
             v
 Failure Analysis and Iteration
```

## 22.2 Dataset design

Datasets should cover:

- normal/common requests;
- edge cases;
- ambiguous inputs;
- missing evidence;
- contradictory evidence;
- malformed tool outputs;
- tool failures;
- long contexts;
- security-sensitive requests;
- regression examples from previous incidents.

Keep development, validation, and held-out test data separated where appropriate. Avoid leaking expected answers into prompt context or evaluator logic.

## 22.3 Evaluator design

For each evaluator, document:

- the behavior being measured;
- input fields;
- output schema;
- score/rubric definition;
- known limitations;
- calibration/validation procedure;
- disagreement handling;
- human review requirements;
- threshold rationale.

LLM-as-judge evaluators must be calibrated and periodically checked against human judgments. An LLM judge score alone is not proof of correctness.

## 22.4 LangSmith usage

The approved online-evaluation Skill includes API and trace-inspection references. Use the actual installed API and current project credentials only when configured by the user.

The project must not use the three rejected Skills (`langsmith-trace`, `langsmith-dataset`, `langsmith-evaluator`) as shortcuts. Use the approved Skills, official documentation, and reviewed implementation instead.

## 22.5 Evaluation reporting

Every evaluation report should state:

- dataset/version;
- sample count;
- evaluator versions;
- metrics and thresholds;
- baseline comparison;
- segment-level results;
- failure examples;
- confidence/uncertainty where meaningful;
- known blind spots;
- recommendation and rationale.

---

# 23. Production Engineering Standards

The Production Specialist owns the operational path from a working prototype to an operable service.

## 23.1 Application architecture

Review:

- API boundary and request validation;
- authentication and authorization;
- separation of business logic from framework wiring;
- dependency injection/configuration;
- state and session lifecycle;
- background work and task execution;
- resource limits;
- error response contracts;
- observability hooks.

## 23.2 Reliability

Review:

- timeouts;
- bounded retries;
- idempotency;
- circuit breaking or equivalent failure containment where appropriate;
- queue/backpressure behavior;
- graceful degradation;
- cancellation handling;
- state recovery;
- dependency outages;
- partial failure behavior.

## 23.3 Security

Review:

- authentication and authorization;
- least privilege;
- secret storage and rotation;
- input validation;
- output handling;
- prompt-injection exposure where tools or retrieval are involved;
- tool side effects;
- dependency supply chain;
- logging of sensitive information;
- tenant boundaries;
- data retention;
- network exposure;
- deployment permissions.

## 23.4 Testing

Include, as appropriate:

- unit tests;
- integration tests;
- API contract tests;
- end-to-end tests;
- failure injection;
- timeout/retry tests;
- security tests;
- load/performance tests;
- migration tests;
- recovery/resume tests.

## 23.5 Observability

Capture useful signals without leaking sensitive data:

- structured application logs;
- traces;
- request and workflow identifiers;
- latency by component;
- model/tool failure counts;
- retry counts;
- token/resource usage where available;
- retrieval quality indicators;
- evaluation outcomes;
- service health.

## 23.6 Deployment readiness

A deployment plan should contain:

- target environment;
- prerequisites;
- configuration requirements;
- secrets handling;
- build process;
- migrations;
- rollback plan;
- health checks;
- observability;
- access control;
- operator instructions;
- explicit approval gate.

Preparing a deployment plan is not the same as executing a deployment. Real deployment remains L3 and requires explicit user approval.

---

# 24. Quality Gates and Definition of Done

## 24.1 Design completion gate

A design is ready for implementation when:

- requirements and non-goals are explicit;
- architecture choices are justified;
- role ownership is clear;
- interfaces and data contracts are documented;
- security risks are identified;
- version assumptions are checked;
- test strategy exists;
- open questions are visible.

## 24.2 Implementation completion gate

Implementation is complete when:

- requested files/code changes exist;
- code follows project conventions;
- required interfaces are respected;
- error cases are handled;
- unit and integration tests have been run where applicable;
- test results are reported accurately;
- no unauthorized sensitive action occurred;
- documentation is updated where necessary;
- known limitations are listed.

## 24.3 Integration completion gate

Integration is complete when:

- specialist outputs are compatible;
- shared schemas and interfaces match;
- state ownership is clear;
- dependency versions are consistent;
- tests pass after integration;
- no unreviewed file conflict remains;
- security-sensitive changes are reviewed;
- the manager has accepted each handoff.

## 24.4 Production readiness gate

Production readiness requires, as relevant:

- defined operational SLOs or service expectations;
- health checks;
- logging and traces;
- failure/recovery behavior;
- secrets and access controls;
- performance testing;
- cost estimates/limits;
- deployment and rollback plans;
- data retention and privacy review;
- monitoring and incident procedures;
- user approval for the actual release action.

---

# 25. Standard Workflows

## 25.1 New project architecture workflow

1. Manager reads the request and identifies requirements.
2. Manager classifies the task as Design.
3. Manager determines whether LangChain, LangGraph, Deep Agents, RAG, or ordinary application code is justified.
4. Manager delegates architecture questions to the necessary specialists.
5. Specialists return options, constraints, and risks.
6. Manager compares trade-offs and resolves conflicts.
7. Manager produces a coherent design and identifies open decisions.
8. User approves material architecture choices where required.
9. Manager records the decision.

## 25.2 Implementation workflow

1. Manager checks that the design and dependencies are ready.
2. Manager defines file/module ownership and interfaces.
3. Manager assigns tasks with the full delegation contract.
4. Independent tasks may run in parallel.
5. Dependent tasks run after prerequisites are accepted.
6. Specialists implement and test their scoped changes.
7. Specialists submit structured handoffs.
8. Manager reviews and requests changes where needed.
9. Manager integrates changes.
10. Tests run again after integration.
11. Manager reports actual modifications and verification evidence.

## 25.3 Debugging workflow

1. Reproduce the issue if possible.
2. Capture exact error, versions, inputs, and execution context.
3. Identify the owning domain.
4. Delegate root-cause analysis to the appropriate specialist.
5. Ask for evidence, not guesses.
6. Separate root cause from symptoms.
7. Propose a minimal fix.
8. Implement within scope.
9. Run regression tests.
10. Report whether the issue is resolved, partially resolved, or not reproduced.

## 25.4 Review workflow

1. Manager defines review scope and severity criteria.
2. Relevant specialist inspects the code/design.
3. Review findings identify location, issue, impact, evidence, and remediation.
4. Production Specialist reviews security/operational risks where relevant.
5. Evaluation Specialist assesses measurable quality regressions where relevant.
6. Manager deduplicates and prioritizes findings.
7. Final report separates confirmed defects from suggestions.

## 25.5 RAG delivery workflow

1. RAG Specialist designs ingestion and retrieval.
2. LangChain Specialist defines generation/tool interfaces.
3. Evaluation Specialist defines a retrieval and answer-quality test set.
4. Production Specialist reviews service integration, secrets, and monitoring.
5. Manager defines the integration contract.
6. Specialists implement their workstreams.
7. Manager integrates the retrieval-to-answer path.
8. Evaluation runs against baseline and edge cases.
9. Production readiness is reviewed.

## 25.6 Multi-agent application workflow

1. Agent Systems Specialist proposes agent boundaries and responsibilities.
2. LangGraph Specialist assesses graph/state control requirements.
3. LangChain Specialist defines tools and component interfaces.
4. Evaluation Specialist defines collaboration and task-success metrics.
5. Production Specialist reviews permissions and reliability.
6. Manager rejects unnecessary agent complexity and approves the final topology.

---

# 26. Project Artifacts and Repository Documentation

The following structure is proposed for the user's future LangChain application repository. It is not an existing directory listing.

```text
project-root/
├── README.md
├── pyproject.toml
├── uv.lock / requirements.lock (depending on chosen package workflow)
├── .env.example
├── .gitignore
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DECISIONS.md
│   ├── AGENT_TEAM.md
│   ├── DELEGATION_PROTOCOL.md
│   ├── SECURITY.md
│   ├── TOOL_ACCESS_POLICY.md
│   ├── DATA_AND_STATE_CONTRACTS.md
│   ├── TEST_STRATEGY.md
│   ├── EVALUATION_PLAN.md
│   └── OPERATIONS.md
├── src/
│   └── application_package/
│       ├── __init__.py
│       ├── config/
│       ├── domain/
│       ├── services/
│       ├── agents/
│       ├── graphs/
│       ├── rag/
│       ├── evaluation/
│       ├── api/
│       └── observability/
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── e2e/
│   ├── evaluation/
│   └── security/
├── scripts/
└── deployment/
```

The exact package layout should follow the real application requirements. Do not impose this structure on every project.

---

# 27. Manager Response and Specialist Handoff Formats

## 27.1 Specialist handoff template

```markdown
# Specialist Handoff

## 1. Task
[Original task]

## 2. Result
[What was completed]

## 3. Technical decisions
[Important decisions and reasons]

## 4. Files changed
[Exact paths and change summary]

## 5. Interfaces and dependencies
[Contracts, package changes, assumptions]

## 6. Verification
- Command:
- Result:
- Tests passed:
- Tests failed:
- Tests skipped/not run:

## 7. Security and permissions
[Relevant findings; confirm no unauthorized actions]

## 8. Risks and limitations
[Remaining concerns]

## 9. Integration instructions
[What the manager needs to do]

## 10. Questions / required decisions
[Only genuinely blocking questions]
```

## 27.2 Final manager report template

Use only relevant sections for small tasks:

```markdown
# Result
[Direct outcome]

## Technical decision
[Why this approach was selected]

## Implementation
[Files or artifacts changed]

## Verification
[Commands/tests actually executed and exact outcomes]

## Limitations
[What remains incomplete or unverified]
```

## 27.3 Truthfulness rules

- “Implemented” means code/files were actually changed.
- “Tested” means a test command actually ran.
- “Passed” means the observed result passed.
- “Verified” means evidence was inspected and supports the claim.
- “Ready for deployment” requires a defined readiness review; it does not mean deployed.
- “Deployed” must never be stated unless a deployment really occurred.

---

# 28. CLI Reference and Safe Inspection Plan

This section separates commands that were observed from commands suggested for later inspection.

## 28.1 Commands already run or explicitly inspected

```powershell
hermes tools --help
hermes tools list
hermes profile --help
hermes profile create --help
hermes plugins
hermes plugins search advanced-delegation
hermes plugins info advanced-delegation
hermes plugins install --help
hermes skills tap add --help
hermes skills search --help
hermes skills uninstall langgraph-persistence
```

The uninstall command above was executed according to the recorded history.

## 28.2 Commands previously proposed for read-only investigation

The following commands were suggested as a next diagnostic step but their outputs are not present in the available record. Run only if they remain valid in the installed CLI; inspect `--help` if a command is rejected.

```powershell
hermes tools disable --help
hermes tools enable --help
hermes config --help
hermes config get toolsets
hermes config get platform_toolsets
hermes config get terminal.backend
hermes config get terminal.cwd
```

The objective is to establish:

- how toolsets are configured;
- whether settings are profile-scoped;
- whether individual tools can be allowed/denied independently;
- whether the `file` tool exposes separate read/write controls;
- what terminal backend is actually used;
- whether terminal working-directory settings have enforceable boundaries;
- which settings are global versus per-profile.

Do not change configuration merely to discover its schema.

## 28.3 Recommended safe inspection sequence

1. Confirm the active profile and profile list.
2. Inspect the relevant `hermes config` help and read-only configuration commands.
3. Inspect the profile's configuration file without printing secrets.
4. Identify the actual tool permission configuration schema for version `0.22.7`.
5. Inspect terminal backend and filesystem controls.
6. Inspect plugin install/enable behavior and backup/rollback options.
7. Compare installed-version documentation/source to the online latest documentation.
8. Record findings before applying any changes.

## 28.4 Do not run yet

Until the user approves implementation, do not run commands that:

- install or enable `advanced-delegation`;
- create or delete profiles;
- write `delegation.backend` or `delegation.backends.*`;
- alter tool enable/disable state;
- change terminal policy;
- copy `.env` or authentication files;
- modify existing profiles;
- install more Skills;
- change global Hermes configuration.

---

# 29. Risk Register

| ID | Risk | Impact | Current status | Required mitigation |
|---|---|---|---|---|
| R-01 | Profile route runs with specialist credentials and terminal policy | High | Known plugin behavior | Allowlist only six reviewed profiles; isolate credentials |
| R-02 | `terminal.cwd` mistaken for a security sandbox | High | Design risk identified | Use enforceable runtime/OS isolation and test boundary escapes |
| R-03 | Specialists modify overlapping files | Medium/High | Not implemented | Task ownership, branches/worktrees, manager integration |
| R-04 | Nested delegation causes uncontrolled agent trees | Medium/High | Baseline prohibits it | Remove delegation from specialist profiles and test |
| R-05 | Skill content changes after initial SAFE scan | Medium | Ongoing supply-chain risk | Pin/review revisions and re-scan changes |
| R-06 | Critical scanner findings bypassed with `--force` | High | Historical risk encountered | Do not force without explicit documented review and approval |
| R-07 | Secrets leak through task context, logs, or tool output | High | Policy drafted, not enforced | Secret minimization, tool controls, redaction, tests |
| R-08 | Documentation for latest Hermes differs from v0.22.7 | Medium | Version gap known | Verify every configuration against installed version |
| R-09 | Global tool availability confused with per-profile permissions | High | Not yet resolved | Inspect actual profile-level enforcement |
| R-10 | Model/provider design accidentally overrides user choices | High | Explicitly excluded | Leave model settings untouched and user-managed |
| R-11 | Dependency drift breaks integration | Medium/High | Policy drafted | Lockfiles, compatibility checks, controlled updates |
| R-12 | Evaluation metrics reward incorrect behavior | High | Design consideration | Metric validation, human review, failure segmentation |
| R-13 | RAG citations do not map to source evidence | High | Design consideration | Source IDs, offsets, versioning, citation tests |
| R-14 | Graph resume repeats non-idempotent side effects | High | Design consideration | Idempotency keys, checkpoints, side-effect boundaries |
| R-15 | Production operations happen without user approval | Critical | Policy drafted | Explicit L3 approval gates and no automatic deploy privilege |
| R-16 | Concurrent subagent limit is assumed incorrectly | Medium | Not verified | Test installed version before setting concurrency policy |
| R-17 | Existing profiles or Skills are changed accidentally | High | Explicitly protected | New independent profiles; inspect active profile before commands |
| R-18 | Specialist handoffs omit test evidence | Medium | Protocol drafted | Mandatory handoff schema and manager acceptance gate |

---

# 30. Decision Log

| Decision ID | Decision | Status | Rationale |
|---|---|---|---|
| D-001 | Build a specialized LangChain engineering system inside Hermes | DECIDED | End-to-end engineering goal |
| D-002 | Use one central manager plus six specialists | DECIDED | Clear ownership and controlled coordination |
| D-003 | Keep existing Hermes profiles untouched | DECIDED | Preserve unrelated projects and credentials |
| D-004 | Use Python-first engineering | DECIDED | Project implementation preference |
| D-005 | Use the approved 14 Skill set | DECIDED/OBSERVED | Reviewed official-source Skills with SAFE installation results |
| D-006 | Exclude three critical LangSmith Skills | DECIDED | Critical scanner findings |
| D-007 | Exclude removed `langgraph-persistence` Skill | DECIDED | It was uninstalled after a HIGH caution |
| D-008 | Do not install unreviewed Skills to fill gaps | DECIDED | Supply-chain and relevance control |
| D-009 | Manager is the only Hermes orchestrator | DECIDED | Accountability and bounded delegation |
| D-010 | Specialists are leaf agents by default | DECIDED | Prevent uncontrolled nested delegation |
| D-011 | Prefer `profile_routes` for internal specialist routing | DECIDED AS DESIGN | Independent profile execution |
| D-012 | Do not use `model_map` in this design | DECIDED | Models are user-managed |
| D-013 | A2A is not required for internal team delegation | DECIDED | `delegate_task` is the internal path |
| D-014 | Do not clone unrelated profiles when creating the new team | PROPOSED/APPROVED DESIGN DIRECTION | Avoid copying `.env`, Skills, and unrelated policy |
| D-015 | Use least-privilege tool access | DECIDED AS POLICY | Reduce unnecessary attack surface |
| D-016 | Treat workspace isolation as a technical enforcement problem | DECIDED AS DESIGN PRINCIPLE | CWD and prompts are not sandbox boundaries |
| D-017 | Require user approval for L3 operations | DECIDED AS POLICY | Protect destructive/irreversible actions |
| D-018 | User manages all profile models/providers | DECIDED | Explicit user instruction |

---

# 31. Implementation Roadmap

The implementation sequence is deliberately staged. Do not skip ahead to profile creation before the access and runtime questions are understood.

## Phase 0 — Preserve baseline

Tasks:

- confirm the active profile;
- capture the existing profile list;
- capture relevant toolset state;
- back up any configuration that might later be changed;
- avoid secrets in logs or exported reports;
- confirm the 14 Skills remain available and their names match the approved list.

Exit criteria:

- baseline inventory is recorded;
- unrelated profiles and settings are protected;
- no changes have been made.

## Phase 1 — Verify version-specific tool permissions

Tasks:

- inspect `hermes tools` help;
- inspect `hermes config` help and read-only settings;
- identify global versus profile-level settings;
- inspect toolset and individual-tool permissions;
- inspect file read/write granularity;
- inspect terminal backend and policy controls;
- establish filesystem isolation options.

Exit criteria:

- a verified configuration design exists for the installed version;
- security boundaries are distinguished from behavioral instructions;
- no unsupported configuration syntax is assumed.

## Phase 2 — Finalize role instructions

Tasks:

- write the manager `SOUL.md` or equivalent profile instruction;
- write the six specialist role instructions;
- define boundaries and refusal/escalation rules;
- add the delegation contract;
- define the standard handoff schema;
- define report truthfulness requirements.

Exit criteria:

- seven role instructions are complete and consistent;
- no specialist claims manager-level authority;
- model/provider settings are absent from the instructions.

## Phase 3 — Review delegation plugin installation

Tasks:

- re-check official plugin details and pinned SHA;
- confirm installed Hermes version compatibility;
- confirm install scope and rollback method;
- confirm plugin configuration schema for profile routes;
- ensure installation affects only the active manager profile.

Exit criteria:

- plugin installation plan approved;
- route syntax is verified;
- no unintended global or unrelated profile changes are expected.

## Phase 4 — Create independent profiles

Tasks:

- create `langchain-engineer`;
- create the six specialist profiles;
- do not clone unrelated profiles;
- verify profile configuration and identity separation;
- ensure model/provider fields remain user-managed.

Exit criteria:

- seven profiles exist;
- existing profiles remain unchanged;
- no unintended `.env` or credential copying occurred.

## Phase 5 — Assign Skills

Tasks:

- manager: `ecosystem-primer`;
- LangChain: three LangChain fundamentals/middleware/dependency Skills;
- LangGraph: three LangGraph Skills;
- Agent Systems: three Deep Agents Skills;
- RAG: `langchain-rag`;
- Evaluation: three evaluation/LangSmith Skills;
- Production: none from the current 14 unless a reviewed need emerges.

Exit criteria:

- each profile has the intended Skills and no unintended Skill duplication;
- the 14-item approved inventory remains intact.

## Phase 6 — Configure tool permissions and runtime boundaries

Tasks:

- manager receives controlled delegation capability;
- specialists do not receive Hermes delegation in the baseline;
- remove unnecessary toolsets from each profile where supported;
- separate file read and write permissions where possible;
- constrain file/terminal execution with enforceable boundaries;
- test denied access to protected paths;
- test that secrets are not exposed.

Exit criteria:

- actual tool access matches the approved matrix;
- runtime boundary tests pass;
- no claim of isolation is made without evidence.

## Phase 7 — Configure `profile_routes`

Tasks:

- install `advanced-delegation` only on the manager if approved;
- configure `profile_routes` for the six specialists;
- provide concise route names and descriptions;
- exclude all unrelated profiles;
- confirm each route invokes the intended profile;
- verify specialist Skills, identity, and terminal policy are used.

Exit criteria:

- all six routes work;
- no route points to `default` or another project;
- profile-level configuration remains independent.

## Phase 8 — Validate delegation and leaf-agent behavior

Tests:

- manager routes to each specialist correctly;
- a specialist does not invoke nested Hermes delegation;
- invalid route fails safely;
- specialist errors are returned to manager;
- timeout and incomplete handoff are handled;
- context and expected outputs are preserved;
- one specialist cannot access another specialist's credentials or memory.

Exit criteria:

- delegation is predictable and bounded;
- failure behavior is understood;
- manager remains accountable.

## Phase 9 — Validate parallel work and integration

Tests:

- two independent specialists work on isolated tasks;
- overlapping file ownership is prevented or safely resolved;
- integration detects incompatible interfaces;
- manager runs final tests after merge;
- rollback is possible for local changes.

Exit criteria:

- parallel execution improves work without creating uncontrolled conflicts.

## Phase 10 — End-to-end pilot project

Choose a small but representative LangChain application task that touches more than one domain but does not require production deployment. Example:

- a small document-ingestion and retrieval application;
- a simple stateful graph workflow;
- a tool-using LangChain agent with a defined evaluation set.

The pilot should test:

- task analysis;
- specialist selection;
- task contracts;
- implementation;
- evaluation;
- integration;
- security controls;
- final reporting.

Exit criteria:

- the team completes the pilot with evidence;
- defects and coordination costs are recorded;
- role boundaries and tool permissions are refined based on actual results.

## Phase 11 — Operational maturity

Only after the pilot:

- expand test coverage;
- establish recurring evaluation workflows if required;
- add reviewed Skills only where justified;
- consider external A2A connections if a real use case appears;
- define monitoring/incident procedures;
- consider broader automation only with explicit scope and approval.

---

# 32. End-to-End Acceptance Test Matrix

| Test ID | Test | Expected result | Status |
|---|---|---|---|
| AT-01 | Manager receives a simple request | Handles directly without unnecessary delegation | Not run |
| AT-02 | LangChain-specific task | Routes only to LangChain Specialist when appropriate | Not run |
| AT-03 | Graph-specific task | Routes to LangGraph Specialist | Not run |
| AT-04 | Deep Agent architecture task | Routes to Agent Systems Specialist | Not run |
| AT-05 | Retrieval design task | Routes to RAG Specialist | Not run |
| AT-06 | Evaluation methodology task | Routes to Evaluation Specialist | Not run |
| AT-07 | Production review task | Routes to Production Specialist | Not run |
| AT-08 | Cross-domain task | Selects only relevant specialists and defines interfaces | Not run |
| AT-09 | Specialist nested delegation attempt | Denied or unavailable | Not run |
| AT-10 | Specialist accesses unrelated profile data | Denied by enforced policy | Not run |
| AT-11 | Specialist reads secret file | Denied or safely redacted by enforced control | Not run |
| AT-12 | Specialist writes outside assigned workspace | Denied by enforced boundary | Not run |
| AT-13 | L3 operation requested | Requires explicit user approval | Not run |
| AT-14 | Missing dependency | Reports exact issue; does not silently install | Not run |
| AT-15 | Test command not run | Final report says not run | Not run |
| AT-16 | Specialist provides unsupported claim | Manager requests evidence or marks unverified | Not run |
| AT-17 | Two independent tasks run concurrently | No conflicting writes; changes integrate | Not run |
| AT-18 | Plugin route fails | Manager reports failure and follows safe fallback | Not run |
| AT-19 | Wrong route name | No accidental call to unrelated profile | Not run |
| AT-20 | Model/provider settings | Remain user-managed and unmodified | Not run |
| AT-21 | Existing profiles | Remain unchanged | Not run |
| AT-22 | Final integration | Post-integration tests are run and reported | Not run |

No acceptance test above has been reported as executed. This matrix defines future verification.

---

# 33. Open Questions Requiring Evidence Before Implementation

1. What is the exact profile-level tool permission schema in Hermes `0.22.7`?
2. Can built-in toolsets be controlled per profile, or only globally in this installation?
3. Can individual tools within the `file` toolset be restricted independently?
4. Can terminal access be sandboxed on this Windows environment?
5. Which terminal backend is currently active for each relevant profile?
6. Does a profile's terminal policy enforce filesystem boundaries or only command behavior?
7. How does Hermes `--worktree` interact with profile-routed `delegate_task` calls?
8. What are the actual concurrency limits and timeout semantics in `0.22.7`?
9. Can the manager reliably detect and reject nested delegation by a specialist?
10. What is the exact `profile_routes` configuration schema in the installed plugin revision?
11. Does plugin installation alter only the active manager profile as expected in the live environment?
12. How are tool failures, timeouts, and partial subagent results surfaced to the manager?
13. How are profile Skills resolved and isolated in a profile-routed subagent?
14. What is the clean rollback path if plugin installation or route configuration fails?

These questions should be answered with installed-version help, configuration inspection, official source, or controlled tests. Do not guess syntax.

---

# 34. Explicit Do-Not-Do List

Until a later user-approved implementation phase, do not:

- create the seven profiles;
- install or enable `advanced-delegation`;
- configure `profile_routes`;
- select or change models/providers;
- set API keys or credentials;
- copy `.env` files between profiles;
- clone existing profiles;
- modify `default` or the eight existing project profiles;
- alter global Hermes tool configuration;
- install additional Skills;
- reinstall `langgraph-persistence`;
- install the three critical LangSmith Skills;
- enable A2A for internal delegation;
- enable nested delegation for specialists;
- grant production deployment permissions;
- claim that filesystem isolation exists before it is tested;
- treat `terminal.cwd` or `SOUL.md` as a sandbox;
- perform destructive or billable actions without the appropriate approval.

---

# 35. Conversation-by-Conversation Reconstruction

This chronology consolidates the project sequence represented in the available context. It is not a verbatim transcript of the six chats.

## 35.1 “Building Agents in Hermes (1)” — Initial inventory and review approach

Primary themes recorded:

- inspect current Hermes Skills before installing new ones;
- use PowerShell to collect inventories and review Skills;
- avoid duplicates;
- examine official LangChain Skills and candidate sets;
- preserve a clear list of approved and rejected items;
- perform security review before installation.

Files/records associated with the work:

```text
CORE_SKILLS_REVIEW.txt
Pasted text(5).txt
```

The user wanted consolidated scripts and a practical way to review the remaining Skills, not generic instructions to manually inspect everything one at a time.

## 35.2 “Building Agents in Hermes (2)” — Remaining Skills and pre-install inventory

Primary themes recorded:

- review the remaining 18 candidate Skills;
- generate a review artifact;
- examine the pre-install inventory;
- decide which items are genuinely useful for the intended LangChain engineering roles;
- maintain an explicit installation allowlist.

Associated files:

```text
REMAINING_18_SKILLS_REVIEW.txt
HERMES_PRE_INSTALL_INVENTORY.txt
```

The available record does not preserve every row of these files. Their original content should be reattached if an exact line-by-line reconstruction of all 18 candidates is required.

## 35.3 “Building Agents in Hermes (3)” — Skill installation and security output

Primary themes recorded:

- install selected official LangChain Skills;
- examine Hermes quarantine and scan behavior;
- review `langgraph-persistence` and its HIGH caution;
- distinguish safe items from items requiring manual decisions;
- do not equate `--force` with a security approval.

The installed `langgraph-cli` command example was explicitly recorded. The Skill later appears in the final approved 14-item list.

## 35.4 “Building Agents in Hermes (4)” — Continued install review and security decisions

Primary themes recorded:

- continue inspecting installation logs;
- evaluate LangSmith candidates;
- identify critical shell-pipeline findings;
- keep unsafe Skills out of the final package;
- later remove `langgraph-persistence` after the earlier force-install.

Final outcome from the consolidated history:

- `langsmith-trace`, `langsmith-dataset`, and `langsmith-evaluator` were not approved;
- `langgraph-persistence` was uninstalled;
- the final approved inventory consists of 14 Skills.

## 35.5 “Building Agents in Hermes (5)” — Team architecture and responsibilities

Primary themes recorded:

- move beyond a large, vague multi-agent design;
- define one central manager and specialist roles;
- give each specialist a coherent engineering domain;
- avoid excessive micro-specialization;
- define practical responsibilities and boundaries;
- make the architecture operational rather than merely lengthy.

The design converged on one manager plus six specialists, covering LangChain, LangGraph, Agent Systems, RAG, Evaluation, and Production.

## 35.6 “Building Agents in Hermes (6)” — Execution policy, delegation, and access

Primary themes recorded:

- define what the manager can decide;
- specify when and how specialists are called;
- standardize the output from each role;
- investigate Hermes delegation and profile routing;
- compare default delegation with advanced profile routes;
- keep models user-managed;
- proceed to least-privilege tool access and runtime isolation.

Important CLI and plugin findings recorded in this phase include:

- `delegation` toolset was active in the CLI listing;
- A2A was active as a plugin toolset but was not selected as the internal delegation mechanism;
- `advanced-delegation` version `1.1.1` was inspected;
- `profile_routes` was selected as the design direction;
- the plugin was not installed;
- no LangChain profile was created;
- access matrix and workspace isolation remained design/verification work.

---

# 36. Continuity Instructions for Future Project Sessions

Any future assistant or engineer continuing this project should follow these instructions:

1. Read this master specification before proposing changes.
2. Do not ask the user to repeat facts already contained here.
3. Do not reopen decisions explicitly marked DECIDED unless new evidence creates a material problem.
4. Do not treat proposed configurations as implemented.
5. Do not add Skills without a specific gap analysis and security review.
6. Do not modify the user's existing Hermes profiles.
7. Do not choose or configure models/providers; the user owns that work.
8. Keep the architecture at one manager plus six specialists unless the user explicitly revises it.
9. Keep Hermes-level delegation centralized in the manager.
10. Treat application-level multi-agent design as separate from the Hermes team topology.
11. Verify every command against Hermes `0.22.7` before using it; online documentation may describe newer releases.
12. Prefer official documentation and source code over assumptions.
13. Use read-only diagnostics before any configuration changes.
14. Explain the difference between a policy instruction and an enforced security boundary.
15. Do not claim that terminal access is sandboxed merely because `cwd` is set.
16. Preserve security findings and installation history, including removed/rejected Skills.
17. Report exact evidence for successful tests and clearly identify tests not run.
18. Make practical, critical recommendations; do not simply agree with the user's suggestions without evaluating them.
19. Keep the implementation simple enough to maintain. Complexity must serve a real engineering requirement.
20. Obtain user authorization before L2/L3 operations when required by the policy in this document.

---

# 37. Immediate Next Step

The next task is not profile creation. It is a read-only verification of the tool permission and runtime-isolation mechanisms supported by the installed Hermes version.

The previously proposed diagnostic commands are:

```powershell
hermes tools disable --help
hermes tools enable --help
hermes config --help
hermes config get toolsets
hermes config get platform_toolsets
hermes config get terminal.backend
hermes config get terminal.cwd
```

Run them only after confirming the syntax with the installed CLI. Send the outputs for analysis. From those results, produce a **version-correct** access-control implementation plan that identifies exactly which restrictions can be enforced per profile, which are global, and which require an OS/container-level boundary.

Only after that plan is validated should the project proceed to:

1. finalize seven profile instruction files;
2. install `advanced-delegation` on the manager if approved;
3. create the seven independent profiles;
4. assign the 14 Skills according to the mapping;
5. configure six profile routes;
6. implement and test least-privilege tool access;
7. validate workspace isolation;
8. run delegation, integration, and end-to-end pilot tests.

---

# Appendix A — Quick Reference: Final Team

| # | Profile | Role | Skills |
|---:|---|---|---|
| 1 | `langchain-engineer` | Lead Architect / Manager | `ecosystem-primer` |
| 2 | `langchain-specialist` | LangChain Engineer | `langchain-fundamentals`, `langchain-middleware`, `langchain-dependencies` |
| 3 | `langgraph-specialist` | LangGraph Engineer | `langgraph-fundamentals`, `langgraph-human-in-the-loop`, `langgraph-cli` |
| 4 | `agent-systems-specialist` | Agent Systems Engineer | `deep-agents-core`, `deep-agents-orchestration`, `deep-agents-memory` |
| 5 | `rag-specialist` | RAG Engineer | `langchain-rag` |
| 6 | `evaluation-specialist` | Evaluation Engineer | `eval-engineering`, `langsmith-experiment-diagnosis`, `langsmith-online-eval-engineering` |
| 7 | `production-specialist` | Production Engineer | None from current approved 14-item set |

# Appendix B — Quick Reference: Skill Security Status

| Skill | Final status | Recorded reason |
|---|---|---|
| `ecosystem-primer` | Approved / installed | SAFE at installation |
| `langchain-fundamentals` | Approved / installed | SAFE at installation |
| `langchain-middleware` | Approved / installed | SAFE at installation |
| `langchain-dependencies` | Approved / installed | SAFE at installation |
| `langchain-rag` | Approved / installed | SAFE at installation |
| `langgraph-fundamentals` | Approved / installed | SAFE at installation |
| `langgraph-human-in-the-loop` | Approved / installed | SAFE at installation |
| `langgraph-cli` | Approved / installed | SAFE at installation |
| `deep-agents-core` | Approved / installed | SAFE at installation |
| `deep-agents-orchestration` | Approved / installed | SAFE at installation |
| `deep-agents-memory` | Approved / installed | SAFE at installation |
| `eval-engineering` | Approved / installed | SAFE at installation |
| `langsmith-experiment-diagnosis` | Approved / installed | SAFE at installation |
| `langsmith-online-eval-engineering` | Approved / installed | SAFE at installation |
| `langsmith-trace` | Not approved | CRITICAL `curl_pipe_shell` at line 28 |
| `langsmith-dataset` | Not approved | CRITICAL `curl_pipe_shell` line 39; MEDIUM unpinned dependencies |
| `langsmith-evaluator` | Not approved | CRITICAL `curl_pipe_shell` line 49; MEDIUM unpinned dependencies |
| `langgraph-persistence` | Removed | HIGH caution involving `DATABASE_URL`; force-installed once, later uninstalled |

# Appendix C — Quick Reference: Plugins and Delegation

| Item | Status | Decision |
|---|---|---|
| Default delegation strategy | Present/active in observed plugin menu | Not sufficient as final independent-profile routing by itself |
| `advanced-delegation` | Discovered and inspected, not installed | Preferred for manager `profile_routes` after approval |
| `model_map` | Available mode described by plugin | Not used; models are user-managed |
| `profile_routes` | Available mode described by plugin | Selected design direction |
| A2A Platform | Enabled in observed plugin toolset | Not needed for internal manager-to-specialist delegation |
| Security Guidance | Disabled in observed menu | No activation decision recorded |

# Appendix D — Non-Negotiable Project Principles

1. One manager; six specialists.
2. Manager is the only Hermes orchestrator.
3. Specialists are independent profiles and default to leaf behavior.
4. Approved Skills are role-scoped, not copied to every profile.
5. No unreviewed Skill installation.
6. No model/provider decisions by the architecture.
7. Existing profiles remain untouched.
8. Profile routing must use an explicit allowlist.
9. Tool availability, role instructions, and runtime isolation are different things.
10. `terminal.cwd` is not a sandbox guarantee.
11. No secret exposure in prompts, logs, source files, or handoffs.
12. No critical action without explicit user approval.
13. No claim of execution or verification without evidence.
14. Keep the implementation useful, testable, and maintainable.

---

**End of master specification.**
