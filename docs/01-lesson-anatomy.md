# 01 — Lesson Anatomy

Every lesson is a markdown file in `docs/`. This page explains the structure of a lesson file, the block types available, and how the Dynatrace app processes each section.

---

## Lesson file structure

```
docs/
  index.md                  ← Welcome page (nav entry 1)
  00-getting-started.md     ← Lesson 0 (this template's orientation)
  01-lesson-anatomy.md      ← Lesson 1 (this file)
  02-interactive-blocks.md  ← Lesson 2
  03-example-lesson.md      ← Lesson 3
  04-publishing-validation.md ← Lesson 4
  cleanup.md                ← Cleanup page
  resources.md              ← Resources page
  snippets/                 ← Reusable content includes
  img/                      ← Images
```

---

## Anatomy of a lesson page

```markdown
# Section N — Title

Optional intro paragraph. Describe what the learner will do and why.

<!-- STEP_SETUP (optional — runs framework functions before page renders)
commands:
  - mySetupFunction
-->

## Concept or context heading

Explanation text. Use code blocks, diagrams, admonitions freely.

```bash
# Copy-paste-ready command the learner runs in the Terminal tab
kubectl get pods -n my-namespace
```

## Validation

The check below runs `<command>` and verifies `<condition>`.

<!-- LAB_QUESTION
type: shell-verification
question: "Human-readable question text"
buttonText: "Check Something"
command: "shell command that produces a numeric or string output"
expect:
  operator: gt
  value: 0
hint: "What to do if the check fails."
explanation: "What it means when the check passes."
-->

<!-- LAB_QUESTION (add as many blocks as needed)
type: dql-verification
...
-->

<!-- boundScenarioId: my-assessment-id retake=false  (add at the end for a scored assessment) -->
```

---

## Block types (quick reference)

### `shell-verification` — runs a shell command in the Orbital container

```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify the cluster node is Ready"
buttonText: "Check Cluster"
command: "kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready'"
expect:
  operator: gt
  value: 0
hint: "Wait 30 seconds after the environment starts and try again."
explanation: "Cluster node is Ready — you are good to proceed."
-->
```

### `multiple-choice` — inline knowledge check

```markdown
<!-- LAB_QUESTION
type: multiple-choice
question: "What does `kubectl rollout restart` do?"
options:
  - "Triggers a rolling restart of all pods in a deployment — new pods start before old ones terminate"
  - "Deletes all pods in the namespace immediately"
  - "Reloads the Kubernetes API server configuration"
  - "Restarts the k3d cluster host process"
correct: 0
explanation: "A rolling restart replaces pods gradually, keeping the application available throughout."
-->
```

### `dql-verification` — runs a DQL query against the learner's Dynatrace tenant

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify Dynatrace is collecting logs from your namespace"
buttonText: "Check DT Logs"
dql: |
  fetch logs
  | filter k8s.namespace.name == "my-namespace"
  | filter timestamp > now() - 10m
  | limit 1
expect:
  operator: not-empty
hint: "Generate some logs first by interacting with the app, then wait 2 minutes."
explanation: "Dynatrace is collecting logs from your namespace."
-->
```

### `STEP_SETUP` — runs functions before the page renders (no button shown)

```markdown
<!-- STEP_SETUP
commands:
  - dynatraceEvalReadSaveCredentials && generateDynakube
-->
```

### `boundScenarioId` — attaches a scored assessment from `.assessment/*.json`

```markdown
<!-- boundScenarioId: my-assessment-id retake=false -->
```

---

## The `expect` field

| `operator` | When to use | Example |
|---|---|---|
| `gt` | Command prints a count; must be > N | grep -c returns at least 1 match |
| `gte` | Count must be ≥ N | At least 2 pods running |
| `eq` | Count must be exactly N | Exactly one ActiveGate |
| `not-empty` | Any non-empty output counts | DQL returns at least one row |

---

## MkDocs nav registration

Every lesson file must be listed in `mkdocs.yaml` nav or it will not appear in the lesson menu:

```yaml
# mkdocs.yaml
INHERIT: mkdocs-base.yaml
site_name: "Dynatrace Enablement Lab: My Training"
repo_name: "View Code on GitHub"
repo_url: "https://github.com/dynatrace-wwse/my-training-repo"
nav:
  - "Welcome": index.md
  - "00. Getting Started": 00-getting-started.md
  - "01. Lesson Anatomy": 01-lesson-anatomy.md
  - "02. Interactive Blocks": 02-interactive-blocks.md
  - "03. Example Lesson": 03-example-lesson.md
  - "04. Publishing": 04-publishing-validation.md
  - "Resources": resources.md
extra:
  rum_snippet: "https://js-cdn.dynatrace.com/jstag/1612cf70810/<tenant-id>/<app-id>_complete.js"
```

!!! warning "Nav order = lesson order"
    The Dynatrace app builds the lesson menu from `nav` in order. Always list pages in the order you want learners to follow them.

---

## Page lifecycle (what happens when a learner opens a lesson)

1. Dynatrace app fetches the rendered HTML from GitHub Pages
2. App parses all `<!-- LAB_QUESTION -->` and `<!-- STEP_SETUP -->` comments
3. If `STEP_SETUP` exists, app calls Orbital to run the commands in the container
4. Page renders with all interactive blocks active
5. Learner reads content, runs Terminal commands, clicks check buttons
6. Each `shell-verification` button → Orbital executes command → result compared to `expect` → hint or explanation shown
7. Each `dql-verification` button → DQL runs in tenant → result compared to `expect`
8. If `boundScenarioId` is present → assessment renders after all checks complete

---

## Admonition quick reference

```markdown
!!! tip "Tip heading"
    Content here.

!!! note "Note heading"
    Content here.

!!! warning "Warning heading"
    Content here.

!!! success "Success heading"
    Content here.
```

---

## Grid card navigation

Use at the bottom of each page to guide the learner to the next step:

```markdown
<div class="grid cards" markdown>
- [Next: 02 — Interactive Building Blocks :octicons-arrow-right-24:](02-interactive-blocks.md)
</div>
```

<div class="grid cards" markdown>
- [02 — Interactive Building Blocks :octicons-arrow-right-24:](02-interactive-blocks.md)
</div>
