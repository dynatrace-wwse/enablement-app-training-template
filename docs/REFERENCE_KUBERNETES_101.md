# Reference: `enablement-kubernetes-101` Interactive Mechanism Inventory

This document catalogs every interactive mechanism found in `enablement-kubernetes-101`. It is the authoritative source for this template's authoring surface. All examples below are copy-paste-ready from the reference repo.

---

## 1. Shell Verification (`shell-verification`)

Renders a button that runs a shell command against the live Orbital container and validates the output.

### Syntax (inline HTML comment in markdown)

```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify the Dynatrace Operator is running in the dynatrace namespace"
buttonText: "Check Operator"
command: "kubectl get pods -n dynatrace --no-headers 2>/dev/null | grep -c Running"
expect:
  operator: gt
  value: 0
hint: "Run the three Helm commands above in the Terminal tab. Wait a few seconds for the operator pod to reach Running state."
explanation: "Operator manager pod is Running — ready to deploy the DynaKube."
-->
```

### Fields

| Field | Type | Description |
|---|---|---|
| `type` | string | `shell-verification` |
| `question` | string | Displayed above the button |
| `buttonText` | string | Button label |
| `command` | string | Shell command executed in the container |
| `expect.operator` | string | `gt`, `gte`, `eq`, `not-empty` |
| `expect.value` | number/string | Value to compare against command output |
| `hint` | string | Shown when check fails |
| `explanation` | string | Shown when check passes |

### `expect.operator` values observed

- `gt` — output integer is greater than value
- `gte` — output integer is greater than or equal to value
- `not-empty` — output is non-empty

### Real examples from kubernetes-101

```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify the cluster node is Ready"
buttonText: "Check Cluster"
command: "kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready'"
expect:
  operator: gt
  value: 0
hint: "The cluster is provisioned automatically. Wait 30 seconds and try again if it is not ready yet."
explanation: "Cluster node is Ready — you are good to proceed."
-->
```

```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify OneAgent was injected into the todoapp pods"
buttonText: "Check Injection"
command: "kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations.oneagent\\.dynatrace\\.com/injected}' 2>/dev/null | tr ' ' '\\n' | grep -c true"
expect:
  operator: gt
  value: 0
hint: "Run `kubectl rollout restart deployment -n todoapp` in the Terminal tab, then wait for the rollout to complete."
explanation: "OneAgent injected — the todoapp pods have the annotation confirming agent injection."
-->
```

---

## 2. Inline Multiple-Choice (`multiple-choice`)

Renders a multiple-choice question inline in the lesson page (not part of a `.assessment/` scenario).

### Syntax

```markdown
<!-- LAB_QUESTION
type: multiple-choice
question: "With AppOnly mode, what does the Dynatrace Operator use instead of a OneAgent DaemonSet?"
options:
  - "A CSI driver that mounts code modules into each pod, combined with a mutating webhook that injects the agent at startup"
  - "A OneAgent DaemonSet that runs on every node and instruments all processes"
  - "Manual sidecar injection — the developer must add an init container to every pod YAML"
  - "A Prometheus exporter sidecar that is automatically added to every pod"
correct: 0
explanation: "AppOnly uses a CSI driver (for code module delivery) and a mutating webhook (for automatic injection at pod creation). No kernel-level DaemonSet is needed."
-->
```

### Fields

| Field | Type | Description |
|---|---|---|
| `type` | string | `multiple-choice` |
| `question` | string | Question text |
| `options` | list of strings | Answer choices |
| `correct` | int | 0-based index of the correct answer |
| `explanation` | string | Shown after the learner answers |

---

## 3. DQL Verification (`dql-verification`)

Renders a button that executes a DQL query against the learner's Dynatrace tenant and validates the result.

### Syntax (inline)

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify Dynatrace is collecting logs from the todoapp namespace"
buttonText: "Check DT Logs"
dql: |
  fetch logs
  | filter k8s.namespace.name == "todoapp"
  | filter contains(content, "Adding a new todo: ")
  | filter timestamp > now() - 10m
  | limit 1
expect:
  operator: not-empty
hint: "Open the TODO app, create a new item, then wait 1–2 minutes for logs to appear in Dynatrace."
explanation: "Dynatrace is collecting logs from todoapp — full observability is active."
-->
```

### Fields

| Field | Type | Description |
|---|---|---|
| `type` | string | `dql-verification` |
| `question` | string | Displayed above the button |
| `buttonText` | string | Button label |
| `dql` | string | DQL query (YAML literal block `\|`) |
| `expect.operator` | string | `gt`, `gte`, `eq`, `not-empty` |
| `expect.field` | string | Field from DQL result to evaluate (optional) |
| `expect.value` | number | Value to compare (when `operator` is not `not-empty`) |
| `hint` | string | Shown on failure |
| `explanation` | string | Shown on success |

### `expect` patterns

```yaml
# Any result row returned
expect:
  operator: not-empty

# Aggregated count >= 1
expect:
  operator: gte
  field: count
  value: 1
```

---

## 4. Assessment Scenario Files (`.assessment/`)

Stand-alone JSON assessment scenarios linked from a lesson page. More complex than inline questions — supports scoring, hints, story framing, and mixed question types.

### File location

`.assessment/<id>.json` — lives at repo root level (hidden directory).

### Binding in markdown

```markdown
<!-- boundScenarioId: k8s-101-fundamentals retake=false -->
```

- `boundScenarioId` — matches the `id` field in the JSON file
- `retake` — `false` prevents re-takes; `true` allows unlimited

### JSON schema (abridged)

```json
{
  "templateVersion": "1.0.0",
  "id": "my-assessment-id",
  "category": "CO",
  "title": "Assessment Title",
  "description": "Short description shown in the assessment picker.",
  "difficulty": "beginner",
  "estimatedTime": 8,
  "imagine": "Framing for the learner: what situation are they in?",
  "yourGoal": "What the learner must accomplish.",
  "tools": [
    { "label": "kubectl" },
    { "label": "Dynatrace Operator" }
  ],
  "story": {
    "introduction": "One paragraph intro.",
    "context": "Where to find the answers."
  },
  "questions": [...],
  "maxScore": 5600,
  "tags": ["kubernetes", "dynatrace"],
  "learningObjectives": [
    "State a concrete skill the learner gains."
  ]
}
```

### Question: `multiple-choice`

```json
{
  "id": "q1-namespace",
  "type": "multiple-choice",
  "title": "What is a Kubernetes namespace?",
  "content": "The lab used two namespaces: `dynatrace` and `todoapp`. What is the main purpose of namespaces?",
  "options": [
    {
      "id": "a",
      "text": "A logical partition that groups related resources and allows separate access control",
      "isCorrect": true,
      "explanation": "Correct! Namespaces let you isolate teams, applications, or environments."
    },
    {
      "id": "b",
      "text": "A physical network boundary that prevents pods from talking to each other",
      "isCorrect": false,
      "explanation": "Namespaces are logical, not physical."
    }
  ],
  "correctAnswer": "a",
  "explanation": "Full explanation shown after answering.",
  "points": 800,
  "hints": [
    "First hint revealed on request.",
    "Second hint if needed."
  ]
}
```

### Question: `dql-verification` (inside `.assessment/`)

```json
{
  "id": "q7-dql-namespace",
  "type": "dql-verification",
  "title": "Verify Dynatrace discovered the todoapp namespace",
  "content": "Run this DQL in Notebooks to explore, then click Validate:\n\n```dql\nfetch dt.entity.cloud_application_namespace\n| fields entity.name\n| limit 20\n```",
  "dql": "fetch dt.entity.cloud_application_namespace | filter matchesPhrase(entity.name, \"todoapp\") | summarize count = count()",
  "expect": {
    "operator": "gte",
    "field": "count",
    "value": 1
  },
  "buttonText": "Validate",
  "explanation": "Dynatrace discovered the todoapp namespace automatically.",
  "points": 1500,
  "hints": [
    "Navigate to Kubernetes in Dynatrace to visually confirm namespaces are visible."
  ]
}
```

---

## 5. Step Setup (`STEP_SETUP`)

Runs one or more framework functions before a lesson page renders. Used to generate configuration files, read credentials, or provision resources that the lesson depends on.

### Syntax

```markdown
<!-- STEP_SETUP
commands:
  - dynatraceEvalReadSaveCredentials && generateDynakube
-->
```

### Observed usages

| Command | What it does |
|---|---|
| `dynatraceEvalReadSaveCredentials` | Reads `DT_ENVIRONMENT`, `DT_OPERATOR_TOKEN`, `DT_INGEST_TOKEN` env vars and generates the Kubernetes Secret manifest |
| `generateDynakube` | Generates `.devcontainer/yaml/gen/dynakube.yaml` from the AppOnly template using the saved credentials |

Custom functions from `my_functions.sh` can also be called here.

---

## 6. Custom Helper Functions (`my_functions.sh`)

Framework functions are available in every container terminal session and can be called from lesson pages via `STEP_SETUP`. Add custom functions to `.devcontainer/util/my_functions.sh`.

### File location

`.devcontainer/util/my_functions.sh` — sourced by `source_framework.sh`.

### Framework functions available (not exhaustive)

| Function | Purpose |
|---|---|
| `printInfoSection "text"` | Prints a bold section header to terminal |
| `printInfo "text"` | Prints an info line |
| `deployTodoApp` | Deploys the TODO application to k3d |
| `deployAstroshop` | Deploys the Astroshop demo application |
| `startK3dCluster` | Provisions the k3d Kubernetes cluster |
| `installK9s` | Installs k9s terminal UI |
| `installMkdocs` | Installs and starts MkDocs local server |
| `exposeMkdocs` | Exposes MkDocs on port 8000 |
| `deployGhdocs` | Publishes docs to GitHub Pages |
| `deleteCodespace` | Self-deletes the current Codespace |
| `dynatraceEvalReadSaveCredentials` | Reads DT env vars and creates K8s Secret |
| `generateDynakube` | Generates DynaKube CR from template |
| `dynatraceDeployOperator` | Deploys Dynatrace Operator via Helm |
| `deployCloudNative` | Deploys DynaKube in CloudNative mode |
| `deployApplicationMonitoring` | Deploys DynaKube in AppOnly mode |
| `finalizePostCreation` | Sends instantiation telemetry; runs e2e checks |
| `assertRunningPod <ns> <label>` | Asserts a pod is Running (for integration tests) |

### Custom function example (from kubernetes-101)

```bash
#!/bin/bash
# .devcontainer/util/my_functions.sh

customFunction(){
  printInfoSection "This is a custom function that calculates 1 + 1"
  printInfo "1 + 1 = $(( 1 + 1 ))"
}
```

Functions defined here are immediately available in any terminal session inside the Codespace.

---

## 7. Video Embedding (`hs-video`)

Embeds a hosted video at the top of a lesson page.

### Syntax

```markdown
[hs-video](https://autonomous-enablements.whydevslovedynatrace.com/videos/enablement/app/<repo-slug>/<video-file>.mp4%7CVideo Title%7CVideo Description.)
```

- URL is `%7C`-encoded pipes separating: `url|Title|Description`
- Video must be hosted on the Orbital Operations server

### Example

```markdown
[hs-video](https://autonomous-enablements.whydevslovedynatrace.com/videos/enablement/app/kubernetes-monitoring.mp4%7CKubernetes%20101%20%E2%80%94%20Kubernetes%20Overview%7COverview%20of%20Kubernetes%20monitoring%20with%20Dynatrace.)
```

---

## 8. Dynatrace App Deep Links (`dt-app`)

Renders a button that opens a specific Dynatrace App within the learner's tenant.

### Syntax

```markdown
[dt-app|<app-id>|Link text](placeholder)
```

### Examples from kubernetes-101

```markdown
[dt-app|dynatrace.kubernetes|Open Kubernetes App](placeholder)
[dt-app|dynatrace.services|Open Services App](placeholder)
```

The app-id is the Dynatrace App identifier (see Dynatrace App Toolkit for the full list).

---

## 9. MkDocs Snippets (`--8<--`)

Reusable content blocks. Snippet files live in `docs/snippets/`. Named sections allow embedding partial content.

### Full file inclusion

```markdown
--8<-- "snippets/disclaimer.md"
```

### Named section inclusion

```bash
# In the snippet file:
# --8<-- [start:SayHello]
echo "Hello"
# --8<-- [end:SayHello]
```

```markdown
<!-- In the lesson: -->
--8<-- "snippets/e2e-sample.sh:SayHello"
```

### Standard snippets in the framework

| File | Content |
|---|---|
| `snippets/disclaimer.md` | Standard DT disclaimer |
| `snippets/dt-enablement.md` | About the enablement framework |
| `snippets/feedback.md` | Feedback call-to-action |
| `snippets/admonitions.md` | Admonition style reference |
| `snippets/view-code.md` | "View source" note |
| `snippets/grail-requirements.md` | Grail/DPS tenant requirement note |

---

## 10. Admonitions

MkDocs Material admonition blocks.

```markdown
!!! tip "Before you start"
    Click Start Environment in the status bar above.

!!! note "Verify the install"
    After the command returns, run `kubectl get pods -n dynatrace`.

!!! warning "Warning"
    This is a Warning.

!!! success "Training complete!"
    Your cluster is now fully instrumented with Dynatrace.
```

Types: `tip`, `note`, `warning`, `success`, `info`, `danger`, `example`, `quote`.

---

## 11. Grid Cards Navigation

MkDocs Material card grid for "continue to next page" navigation.

```markdown
<div class="grid cards" markdown>
- [Next section :octicons-arrow-right-24:](next-page.md)
</div>
```

---

## 12. RUM / BizEvents Tracking

Automatic via `docs/overrides/main.html` + `rum_snippet` URL in `mkdocs.yaml`. Every page load fires a `page_load` BizEvent using the page title from the `nav` section. No per-page JavaScript needed — just set `rum_snippet` correctly.

```yaml
# mkdocs.yaml
extra:
  rum_snippet: "https://js-cdn.dynatrace.com/jstag/1612cf70810/<tenant-id>/<app-id>_complete.js"
```

---

## 13. MkDocs Configuration Pattern

```yaml
# mkdocs.yaml
INHERIT: mkdocs-base.yaml

site_name: "Dynatrace Enablement Lab: <Lab Name>"
repo_name: "View Code on GitHub"
repo_url: "https://github.com/dynatrace-wwse/<repo-name>"
nav:
  - "Welcome": index.md
  - "1. First section": 1-first.md
extra:
  rum_snippet: "https://js-cdn.dynatrace.com/jstag/..."
```

`mkdocs-base.yaml` is pulled from the framework cache — do not create it manually.

---

## 14. DevContainer Lifecycle

| Hook | Script | When it runs |
|---|---|---|
| `postCreateCommand` | `.devcontainer/post-create.sh` | Once, when container first created |
| `postStartCommand` | `.devcontainer/post-start.sh` | On every Codespace resume/start |

### Key `post-create.sh` call order (from kubernetes-101)

```bash
source .devcontainer/util/source_framework.sh  # loads all framework functions
setUpTerminal           # configures zsh + p10k
startK3dCluster         # provisions the k3d cluster
installK9s              # installs k9s TUI
deployTodoApp           # deploys the demo application
finalizePostCreation    # sends telemetry, runs e2e checks, shows greeting
```

### `source_framework.sh` — two-tier cache

1. **DEV MODE**: if `functions.sh` exists locally (framework dev only), sources directly
2. **Container cache** (`~/.cache/dt-framework/<version>/`): fast, lost on rebuild
3. **Host cache** (`.devcontainer/.cache/dt-framework/<version>/`): persists across rebuilds (volume-mounted)
4. **Git clone**: fallback if neither cache exists

---

## 15. Integration Tests

```bash
# .devcontainer/test/integration.sh
source .devcontainer/util/source_framework.sh
assertRunningPod dynatrace operator
assertRunningPod dynatrace activegate
assertRunningPod todoapp todoapp
```

Triggered by GitHub Actions on PRs via `.github/workflows/integration-tests.yaml`.

---

## 16. Framework Version Pinning

```bash
# .devcontainer/util/source_framework.sh
FRAMEWORK_VERSION="${FRAMEWORK_VERSION:-1.4.0}"
```

`sync push-update` (from the synchronizer) bumps this line across all repos when a new framework version is released.

---

## Summary: All Interactive Block Types

| Block type | Where | Rendered as |
|---|---|---|
| `shell-verification` | Inline markdown comment | Button → runs command in container |
| `multiple-choice` (inline) | Inline markdown comment | In-page MCQ |
| `dql-verification` (inline) | Inline markdown comment | Button → runs DQL in tenant |
| `STEP_SETUP` | Inline markdown comment | Invisible — runs functions before page load |
| `boundScenarioId` | Inline markdown comment | Triggers full assessment from `.assessment/` JSON |
| `.assessment/*.json` | Repo root hidden dir | Full scored assessment with MCQ + DQL questions |
| `[hs-video](...)` | Markdown shortcode | Embedded video player |
| `[dt-app\|id\|text](placeholder)` | Markdown shortcode | Deep-link button to DT App |
| `--8<-- "snippets/..."` | Markdown include | Reusable content block |
| Admonitions `!!! type` | MkDocs Material | Styled callout box |
| Grid cards | MkDocs Material | Navigation card grid |
