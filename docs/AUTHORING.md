# AUTHORING.md — Complete Schema Reference

This document consolidates schemas, field definitions, gotchas, and canonical patterns for building interactive enablement trainings. Inline `<!-- LAB_QUESTION -->` comments reference anchors here.

---

## Content types — not only hands-on trainings

The same authoring format produces every kind of training. What changes is the content:

- **Hands-On** — the repo ships a codespaces-framework container (`.devcontainer/devcontainer.json`). The app provisions a **live environment** (Kubernetes + terminal). `shell-verification` and `STEP_SETUP` run in that environment.
- **Self-paced** — docs-only repo (no `.devcontainer`). Markdown + quizzes, no environment. Use for Learning Bytes, onboarding modules, quizzes.

Delivery is **auto-detected** from the `.devcontainer` presence — you do not declare it.

A single repo can hold **one** training (a top-level `nav` entry points at a file) or **many** (every top-level `nav` entry is a section — each becomes its own training).

---

## Front-matter (catalog metadata) {#front-matter}

Add YAML **front-matter** to a training's **intro page** (the first `nav` entry of a single-training repo; each module's `00-*.md` of a multi-training repo). It powers the app catalog card/table (description, filters) and is invisible to the learner.

```yaml
---
description: One-line summary shown on the catalog card/table.
tags: [kubernetes, observability]
difficulty: beginner        # beginner | intermediate | advanced | expert
duration: 90                # minutes
---
```

All fields optional. `tags`, `difficulty`, and `duration` drive the catalog filters; `description` shows on the card. MkDocs Material renders this as page metadata (hidden); the app importer (`extractFrontMatter`) strips it before rendering.

---

## Preview locally (with the quiz plugin)

Author repos ship `hooks.py` (the quiz-preview MkDocs plugin) so quizzes render during preview:

```bash
pip install -r requirements.txt   # mkdocs-material + PyYAML
mkdocs serve                       # http://127.0.0.1:8000
```

Each `<!-- LAB_QUESTION -->` shows as a card (question, options with the correct one marked, collapsible explanation) — the same block the app imports and grades.

---

## shell-verification {#shell-verification}

Runs a shell command in the Orbital container and compares the output to an `expect` condition.

```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Human-readable question text"
buttonText: "Button Label"
command: "shell command to execute"
expect:
  operator: gt | gte | eq | not-empty
  value: 0
hint: "What the learner should do if the check fails."
explanation: "What it means when the check passes."
-->
```

### Fields

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | yes | string | Must be `shell-verification` |
| `question` | yes | string | Displayed above the button |
| `buttonText` | yes | string | Button label (keep short: "Check X") |
| `command` | yes | string | Runs in the Orbital container shell |
| `expect.operator` | yes | string | `gt`, `gte`, `eq`, `not-empty` |
| `expect.value` | conditional | number | Required unless operator is `not-empty` |
| `hint` | yes | string | Shown on failure |
| `explanation` | yes | string | Shown on success |

### Command patterns

```bash
# Count matching lines (use with operator: gt, value: 0)
kubectl get pods -n <ns> --no-headers 2>/dev/null | grep -c Running

# Check an annotation on pods
kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations.oneagent\.dynatrace\.com/injected}' 2>/dev/null | tr ' ' '\n' | grep -c true

# Verify a CRD resource exists
kubectl get dynakube -n dynatrace --no-headers 2>/dev/null | grep -c ''

# Check a file was generated
test -f .devcontainer/yaml/gen/dynakube.yaml && echo 1 || echo 0
```

### Gotchas

- Always redirect stderr: `2>/dev/null` prevents error messages from polluting the output that `grep -c` counts.
- Use `grep -c` (not `wc -l`) — `grep -c` returns 0 instead of failing when there are no matches.
- `not-empty` compares the raw output string; use it for DQL or commands that print content, not counts.

---

## multiple-choice (inline) {#multiple-choice-inline}

Inline knowledge check. No separate file needed.

```markdown
<!-- LAB_QUESTION
type: multiple-choice
question: "Question text?"
options:
  - "First option text (index 0)"
  - "Second option text (index 1)"
  - "Third option text (index 2)"
  - "Fourth option text (index 3)"
correct: 0
explanation: "Shown after the learner answers."
-->
```

### Fields

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | yes | string | Must be `multiple-choice` |
| `question` | yes | string | Question text |
| `options` | yes | list of strings | 2–4 options recommended |
| `correct` | yes | int | 0-based index of the correct option |
| `explanation` | yes | string | Shown after answering |

---

## Template variables {#template-variables}

The session player substitutes these placeholders into lesson markdown and `dql-verification` queries before rendering/execution:

| Placeholder | Resolves to | Purpose |
|---|---|---|
| `{{DT_SESSION_ID}}` | `<user>-<yyyymmdd>` (e.g. `alice-20260714`) | Per-user Grail-isolation id. The framework bakes the same id into the session's DynaKube name and `hostGroup` (via `DT_HOSTGROUP`), so the learner's cluster identity in the tenant ends with it. |

**The isolation rule:** many learners run the same training against ONE shared tenant (bootcamps run 100+ parallel sessions). Every Grail query — inline ```` ```dql ```` blocks and `dql-verification` questions — MUST scope to the learner's own cluster:

```dql
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
```

Use `endsWith` (not `==`): the cluster name is `<repo>-<session-id>` and the repo part may be truncated, but the session id always survives as the suffix. Inside the Orbital container the same id is available to shell steps as `$DT_HOSTGROUP`.

---

## dql-verification (inline) {#dql-verification-inline}

Runs a DQL query against the learner's Dynatrace tenant and validates the result.

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Human-readable question text"
buttonText: "Button Label"
dql: |
  fetch logs
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "my-namespace"
  | filter timestamp > now() - 10m
  | limit 1
expect:
  operator: not-empty | gt | gte | eq
  field: fieldName
  value: 1
hint: "What to do if the check fails."
explanation: "What it means when the check passes."
-->
```

### Fields

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | yes | string | Must be `dql-verification` |
| `question` | yes | string | Displayed above the button |
| `buttonText` | yes | string | Button label |
| `dql` | yes | string | DQL query; use YAML literal block (`\|`) for multi-line |
| `expect.operator` | yes | string | `not-empty`, `gt`, `gte`, `eq` |
| `expect.field` | conditional | string | Field name from DQL result; required when operator is not `not-empty` |
| `expect.value` | conditional | number | Required when operator is not `not-empty` |
| `hint` | yes | string | Shown on failure |
| `explanation` | yes | string | Shown on success |

### DQL patterns

```dql
-- Check any rows returned (use with not-empty)
fetch logs
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
| filter k8s.namespace.name == "todoapp"
| filter timestamp > now() - 10m
| limit 1

-- Count entities (use with gte, field: count, value: 1)
fetch dt.entity.cloud_application_namespace
| filter matchesPhrase(entity.name, "todoapp")
| summarize count = count()

-- Verify a specific metric exists
fetch metrics
| filter metric.key == "dt.kubernetes.workload.pods"
| limit 1
```

### Gotchas

- Time-bounded queries prevent false positives from previous training sessions: `filter timestamp > now() - 10m`.
- The `matchesPhrase` function is fuzzy — use exact `==` comparisons when precision matters.
- `dql-verification` runs in the learner's tenant, not the Orbital container. Do not reference local filesystem paths.
- **Always scope log/span queries to the learner's cluster** with `| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")` — see [Template variables](#template-variables). Without it, a classmate's session in the same tenant can give a false pass (namespace names like `todoapp` are identical across sessions). Entity queries (`fetch dt.entity.*`) can't always carry the filter — prefer log/metric checks for multi-user trainings.

---

## STEP_SETUP {#step-setup}

Runs one or more framework functions before the page renders. No UI element is shown to the learner.

```markdown
<!-- STEP_SETUP
commands:
  - commandOrFunctionName
  - anotherCommand && chainedCommand
-->
```

### Fields

| Field | Required | Type | Notes |
|---|---|---|---|
| `commands` | yes | list of strings | Each string is a shell command; chaining with `&&` is supported |

### When to use STEP_SETUP

- Generating config files before the lesson (e.g., `generateDynakube`)
- Reading and saving credentials (`dynatraceEvalReadSaveCredentials`)
- Starting a background process the lesson depends on
- Calling a custom function that sets up the training scenario

### Gotchas

- STEP_SETUP runs every time the learner navigates to the page, not just once. Make commands idempotent.
- Errors in STEP_SETUP may block the page from rendering. Test commands manually first.
- Use `&&` to chain dependent commands: if the first fails, the second won't run.

---

## boundScenarioId {#bound-scenario-id}

Binds a scored assessment scenario (`.assessment/<id>.json`) to the current lesson page.

```markdown
<!-- boundScenarioId: my-assessment-id retake=false -->
```

### Fields

| Field | Required | Type | Notes |
|---|---|---|---|
| `boundScenarioId` | yes | string | Must match the `id` field in the JSON file |
| `retake` | yes | boolean | `false` prevents re-takes; `true` allows unlimited |

### Gotchas

- The `id` in the JSON and the `boundScenarioId` value must match exactly (case-sensitive).
- Place `boundScenarioId` at the end of the page, after all shell/DQL checks.
- Use `retake=true` during testing to reset the assessment for each run.

---

## Assessment JSON schema {#assessment-json}

Full schema for `.assessment/<id>.json`:

```json
{
  "templateVersion": "1.0.0",
  "id": "my-assessment-id",
  "category": "CO",
  "title": "Assessment Title",
  "description": "Short description shown in the Dynatrace assessment picker.",
  "difficulty": "beginner | intermediate | advanced",
  "estimatedTime": 8,
  "imagine": "Framing paragraph: what situation is the learner in?",
  "yourGoal": "What the learner must accomplish to pass.",
  "tools": [
    { "label": "kubectl" },
    { "label": "Dynatrace Operator" }
  ],
  "story": {
    "introduction": "One paragraph introduction.",
    "context": "Where learners can find the answers."
  },
  "questions": [...],
  "maxScore": 5600,
  "tags": ["tag1", "tag2"],
  "learningObjectives": [
    "State a concrete, measurable skill the learner gains."
  ]
}
```

### Assessment question: `multiple-choice`

```json
{
  "id": "q1-unique-id",
  "type": "multiple-choice",
  "title": "Short question title",
  "content": "Full question text. May include markdown: `code`, **bold**, tables.",
  "options": [
    {
      "id": "a",
      "text": "Correct answer text",
      "isCorrect": true,
      "explanation": "Why this is correct."
    },
    {
      "id": "b",
      "text": "Wrong answer text",
      "isCorrect": false,
      "explanation": "Why this is wrong."
    },
    {
      "id": "c",
      "text": "Wrong answer text",
      "isCorrect": false,
      "explanation": "Why this is wrong."
    },
    {
      "id": "d",
      "text": "Wrong answer text",
      "isCorrect": false,
      "explanation": "Why this is wrong."
    }
  ],
  "correctAnswer": "a",
  "explanation": "Full explanation shown after the learner answers — repeat and expand on the correct reasoning.",
  "points": 1000,
  "hints": [
    "First hint — revealed on request, progressive disclosure.",
    "Second hint — more specific if first wasn't enough."
  ]
}
```

### Assessment question: `dql-verification`

```json
{
  "id": "q7-dql-namespace",
  "type": "dql-verification",
  "title": "Question title",
  "content": "Instruction text. Show the learner an exploration query first, then ask them to validate.\n\n```dql\nfetch dt.entity.cloud_application_namespace\n| fields entity.name\n| limit 20\n```",
  "dql": "fetch dt.entity.cloud_application_namespace | filter matchesPhrase(entity.name, \"todoapp\") | summarize count = count()",
  "expect": {
    "operator": "gte",
    "field": "count",
    "value": 1
  },
  "buttonText": "Validate",
  "explanation": "Why this confirms the expected state.",
  "points": 1500,
  "hints": [
    "Navigate to the relevant Dynatrace app to visually confirm.",
    "The query uses matchesPhrase — check spelling if no results appear."
  ]
}
```

### Points guidelines

| Difficulty | Points |
|---|---|
| Recall | 600–800 |
| Understanding | 1000 |
| Application | 1200–1500 |
| DQL verification | 1500 |

---

## hs-video {#hs-video}

Embeds a video hosted on the Orbital server.

```markdown
[hs-video](https://autonomous-enablements.whydevslovedynatrace.com/videos/enablement/app/<path>.mp4%7CTitle%7CDescription.)
```

The URL after `.mp4` uses `%7C` (URL-encoded `|`) to separate: `url|Title|Description`.

**Gotcha:** The video file must be uploaded to the Orbital server first. Contact the Orbital administrator to upload training videos.

---

## dt-app deep links {#dt-app}

Opens a specific Dynatrace App from a lesson button.

```markdown
[dt-app|<app-id>|Link text](placeholder)
```

| App | ID |
|---|---|
| Kubernetes | `dynatrace.kubernetes` |
| Services | `dynatrace.services` |
| Logs | `dynatrace.logs` |
| Notebooks | `dynatrace.notebooks` |
| Workflows | `dynatrace.automations` |

---

## Custom functions {#custom-functions}

Add functions to `.devcontainer/util/my_functions.sh`. They are sourced into every terminal session automatically.

```bash
#!/bin/bash
# .devcontainer/util/my_functions.sh

mySetupFunction(){
  printInfoSection "Setting up training scenario"
  # ... setup logic
  printInfo "Setup complete"
}

myValidationFunction(){
  local result
  result=$(kubectl get pods -n my-namespace --no-headers 2>/dev/null | grep -c Running)
  if [[ "$result" -gt 0 ]]; then
    printInfo "Validation passed: $result Running pods"
    return 0
  else
    printInfo "Validation failed: no Running pods found"
    return 1
  fi
}
```

Available framework helpers (from `functions.sh`):

| Helper | Purpose |
|---|---|
| `printInfoSection "text"` | Bold section header |
| `printInfo "text"` | Info line |
| `printWarning "text"` | Warning line |
| `assertRunningPod <ns> <label>` | Integration test assertion |

---

## MkDocs snippets {#snippets}

```markdown
--8<-- "snippets/disclaimer.md"
--8<-- "snippets/feedback.md"
--8<-- "snippets/grail-requirements.md"
```

Named section extraction:

```bash
# In the snippet file:
# --8<-- [start:MySection]
content here
# --8<-- [end:MySection]
```

```markdown
--8<-- "snippets/myfile.sh:MySection"
```

---

## Common gotchas

1. **`return` not `exit` in functions** — `my_functions.sh` is sourced. `exit` kills the shell session.
2. **Always redirect stderr in shell commands** — use `2>/dev/null` to prevent error noise from affecting `grep -c`.
3. **STEP_SETUP must be idempotent** — it runs every time the page loads.
4. **MkDocs does not render `<!-- -->` comments** — interactive blocks are invisible in the static site; they only work in the Dynatrace app.
5. **Assessment `id` is case-sensitive** — `boundScenarioId` must match exactly.
6. **`retake=false` is irreversible per learner** — use `retake=true` during development.
7. **DQL queries run in the learner's tenant** — they cannot access the Orbital container filesystem.
8. **Nav order = lesson order** — the Dynatrace app builds the menu from `mkdocs.yaml` nav in order; list pages in the intended sequence.
9. **Comment out `installMkdocs` before going live** — avoids slow container startup and keeps learners on GitHub Pages (RUM tracking).
10. **framework version** — `FRAMEWORK_VERSION` in `source_framework.sh` is updated by `sync push-update`. Do not pin manually.
