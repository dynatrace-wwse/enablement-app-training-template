# 02 — Interactive Building Blocks

One runnable example per block type. Every block on this page is live — click the buttons to verify your environment and see what each block looks like from the learner's perspective.

See `docs/AUTHORING.md` for full schema reference and `docs/REFERENCE_KUBERNETES_101.md` for every pattern extracted from the reference training.

---

## 1. Shell Verification — non-interactive "run-and-verify"

Use when: you want to check that a command produces a specific output without the learner having to run it manually.

**How to use:** Write a shell command that returns a count (via `grep -c`) or a non-empty string. Set `expect.operator` and `expect.value` accordingly.

The block below verifies the k3d cluster node is Ready:

```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify the cluster node is Ready"
buttonText: "Check Cluster"
command: "kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready'"
expect:
  operator: gt
  value: 0
hint: "Wait 30 seconds after the Codespace starts and try again. The cluster provisions automatically."
explanation: "Cluster node is Ready — proceed to the next step."
-->
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the cluster node is Ready"
buttonText: "Check Cluster"
command: "kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready'"
expect:
  operator: gt
  value: 0
hint: "Wait 30 seconds after the Codespace starts and try again. The cluster provisions automatically."
explanation: "Cluster node is Ready — proceed to the next step."
-->

---

## 2. kubectl — interactive (Terminal tab)

Use when: the learner should type kubectl commands themselves in the Terminal tab to explore the cluster. No block needed — the Terminal tab is always available. Document the command in the lesson and explain what to expect.

**How to author:**

```markdown
Open the **Terminal** tab above and run:

```bash
kubectl get pods --all-namespaces
```

You should see pods in `kube-system` and any namespaces your training deploys.
```

Pair with a `shell-verification` block to gate progression on the expected output:

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the todoapp pods are Running"
buttonText: "Check todoapp"
command: "kubectl get pods -n todoapp --no-headers 2>/dev/null | grep -c Running"
expect:
  operator: gt
  value: 0
hint: "Run `kubectl get pods -n todoapp` in the Terminal tab to see the current status."
explanation: "todoapp pods are Running — the demo application is ready."
-->

---

## 3. kubectl — non-interactive (run-and-verify)

Use when: you want to validate a kubectl output without requiring the learner to run it interactively. Write the full command in `command` using jsonpath, grep, or awk to extract the value you need.

**Pattern: count Running pods**

```bash
# In command field:
kubectl get pods -n <namespace> --no-headers 2>/dev/null | grep -c Running
```

**Pattern: check an annotation**

```bash
# In command field:
kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations.oneagent\.dynatrace\.com/injected}' 2>/dev/null | tr ' ' '\n' | grep -c true
```

**Pattern: verify a CRD exists**

```bash
# In command field:
kubectl get dynakube -n dynatrace --no-headers 2>/dev/null | grep -c ''
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the kube-system namespace has Running pods (cluster health check)"
buttonText: "Check kube-system"
command: "kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c Running"
expect:
  operator: gte
  value: 3
hint: "The kube-system pods are started automatically by k3d. If fewer than 3 are Running, wait 60 seconds and try again."
explanation: "kube-system pods are Running — the cluster control plane is healthy."
-->

---

## 4. Custom Helper Functions

Use when: you need repeatable setup steps, environment manipulation, or training scenarios that go beyond what kubectl provides. Define functions in `.devcontainer/util/my_functions.sh` — they are sourced into every terminal session.

**How to author:**

```bash
# .devcontainer/util/my_functions.sh

# Function available interactively in the Terminal tab
injectFault(){
  printInfoSection "Injecting a synthetic failure into the todoapp"
  kubectl scale deployment todoapp -n todoapp --replicas=0
  printInfo "todoapp scaled to 0 replicas — check your Dynatrace dashboard"
}

# Function to restore normal state
restoreApp(){
  printInfoSection "Restoring todoapp to normal"
  kubectl scale deployment todoapp -n todoapp --replicas=1
  kubectl rollout status deployment/todoapp -n todoapp
  printInfo "todoapp restored"
}
```

In the lesson, tell the learner to run the function in the Terminal tab:

```markdown
Open the **Terminal** tab and run:

```bash
injectFault
```

Watch your Dynatrace dashboard — within 60 seconds you should see the service disappear from the Services view.
```

Use `STEP_SETUP` to call a function automatically before the page renders:

```markdown
<!-- STEP_SETUP
commands:
  - mySetupFunction
-->
```

The check below calls the template's example custom function:

<!-- LAB_QUESTION
type: shell-verification
question: "Run the example custom function and verify it outputs a result"
buttonText: "Run customFunction"
command: "source .devcontainer/util/source_framework.sh && customFunction 2>&1 | grep -c '1 + 1'"
expect:
  operator: gt
  value: 0
hint: "The customFunction is defined in .devcontainer/util/my_functions.sh. Make sure the file exists and is not empty."
explanation: "customFunction ran successfully — custom functions are available in your environment."
-->

---

## Template variables — write one query, isolate every learner

Before you author anything that touches Grail, know these three placeholders. The player substitutes them into your lesson markdown and into every `dql-verification` query, so one training can run for 100 learners against ONE tenant and each of them sees only their own data.

| Placeholder | Resolves to | Available in | Use it for |
|---|---|---|---|
| `{{DT_SESSION_ID}}` | `<user>-<yyyymmdd>` — e.g. `alice-20260811` | every player | **Scoping Grail queries to the learner's own cluster.** |
| `{{DT_TENANT}}` | tenant URL, no trailing slash | every player | Deep links. Not needed in DQL — the query already runs in this tenant. |
| `{{JOB_ID}}` | Orbital environment id, `enablement-<12hex>` | session player only (needs a live environment) | Support references, the learner's app URL. **Never a DQL filter** — no telemetry is tagged with it. |

### The isolation rule

The framework names the learner's cluster `<repo>-<session-id>` and truncates the **repo** part to fit the DynaKube name cap — the session id always survives as the suffix. So every log, span, event and metric query gets this line:

```dql
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")   // correct
| filter k8s.cluster.name == "{{DT_SESSION_ID}}"           // never matches
```

Leave it out and a classmate's identically-named `todoapp` namespace can give your learner a false pass.

!!! warning "Placeholders do NOT resolve in shell commands"
    Substitution reaches lesson markdown and the `dql:` field only. In a `shell-verification` `command:`, a `LAB_SOLUTION`, or a `STEP_SETUP`, use the environment variable instead — `$DT_HOSTGROUP` holds the same value. A `{{DT_SESSION_ID}}` left in a shell command stays literal and the check fails silently.

An unresolved variable is left as literal text, never replaced with an empty string — `endsWith(k8s.cluster.name, "")` would match every cluster in the tenant and pass. Full reference, including which fields carry the session id in `apponly` vs `cloudnative` mode: [AUTHORING → Template variables](AUTHORING.md#template-variables).

---

## 5. DQL Query — inline read-only

Use when: you want to show learners an example DQL query to explore their tenant. No validation required — just document the query in a `dql` code block.

**How to author:**

````markdown
Run this DQL query in **Notebooks** to explore your logs:

```dql
fetch logs, from:now()-15m
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
| filter k8s.namespace.name == "todoapp"
| limit 10
```
````

---

## 6. DQL Verification — query with assertion

Use when: you want to gate lesson progression on a Dynatrace entity or observability state. The learner's tenant must return a result that matches `expect`.

**Logs — `expect.operator: not-empty`** passes if DQL returns at least one row. This one is from `enablement-kubernetes-101`, checking that the learner's *own* todo produced a log line:

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify the log line for your todo reached Dynatrace Grail"
buttonText: "Check logs in Grail"
dql: |
  fetch logs, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | filter contains(content, "Adding a new todo")
  | limit 1
expect:
  operator: not-empty
hint: "Add a todo first. Logs take ~1–2 minutes to reach Grail — wait a moment and check again."
explanation: "Your todo's log line is in Grail — captured by the log module, with no code change to the application."
-->
```

**Traces / spans** — same shape, `fetch spans`, filtered to one endpoint:

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify the trace for your todo request reached Dynatrace Grail"
buttonText: "Check traces in Grail"
dql: |
  fetch spans, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | filter span.name == "POST /todos"
  | limit 1
expect:
  operator: not-empty
hint: "Traces exist only for pods restarted AFTER the DynaKube was applied. Restart the workload, add another todo, then wait ~1–2 minutes."
explanation: "The trace is in Grail — the request was recorded from inside the application process."
-->
```

!!! warning "`fetch spans`: bound it with `from:`, never `filter timestamp`"
    On `fetch spans` the `timestamp` field is **null** — a span carries `start_time` / `end_time`. `| filter timestamp > now()-15m` therefore returns nothing, and the check fails as an *empty result rather than an error*, which looks exactly like "the data never arrived". Use the `from:` parameter, as above; it works for `fetch logs` too. `service.name` is null on spans as well (it is an OpenTelemetry resource attribute) — filter on `span.name` or `endpoint.name`.

**`expect.operator: gte` with `field`** — passes if a DQL aggregation meets a threshold:

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify Dynatrace discovered the todoapp namespace"
buttonText: "Validate"
dql: "fetch dt.entity.cloud_application_namespace | filter matchesPhrase(entity.name, \"todoapp\") | summarize count = count()"
expect:
  operator: gte
  field: count
  value: 1
hint: "Navigate to Kubernetes in Dynatrace to visually confirm the namespace is visible."
explanation: "Dynatrace discovered the todoapp namespace — entity data is flowing."
-->
```

<!-- LAB_QUESTION
type: dql-verification
question: "Verify Dynatrace can be reached from your environment (tenant entity check)"
buttonText: "Check DT Connection"
dql: "fetch dt.entity.host | limit 1 | summarize count = count()"
expect:
  operator: gte
  field: count
  value: 1
hint: "Verify that DT_ENVIRONMENT is set: run `echo $DT_ENVIRONMENT` in the Terminal tab."
explanation: "Dynatrace connection verified — your tenant is reachable and returning entity data."
-->

---

## 7. Assessment (multiple-choice + DQL, scored)

Use when: you want to formally score the learner at the end of a lesson section. Create a `.assessment/<id>.json` file and bind it with `boundScenarioId`.

**Step 1 — Create the assessment JSON:**

```json
// .assessment/my-training-quiz.json
{
  "templateVersion": "1.0.0",
  "id": "my-training-quiz",
  "category": "CO",
  "title": "My Training — Knowledge Check",
  "description": "Validate understanding of key concepts.",
  "difficulty": "beginner",
  "estimatedTime": 5,
  "questions": [
    {
      "id": "q1",
      "type": "multiple-choice",
      "title": "Question title",
      "content": "Question body text.",
      "options": [
        { "id": "a", "text": "Correct answer", "isCorrect": true, "explanation": "Why it's correct." },
        { "id": "b", "text": "Wrong answer",   "isCorrect": false, "explanation": "Why it's wrong." }
      ],
      "correctAnswer": "a",
      "explanation": "Full explanation shown after answering.",
      "points": 1000,
      "hints": ["First hint.", "Second hint."]
    }
  ],
  "maxScore": 1000,
  "tags": ["my-training"],
  "learningObjectives": ["State what the learner gains."]
}
```

**Step 2 — Bind to a lesson page:**

```markdown
<!-- boundScenarioId: my-training-quiz retake=false -->
```

This template's example assessment is bound below. Click through it to see the learner experience:

<!-- boundScenarioId: template-authoring-fundamentals retake=true -->

---

## 8. Q&A / Knowledge Check (inline multiple-choice)

Use when: you want a lightweight inline question without the overhead of a full assessment scenario. No separate JSON file needed.

```markdown
<!-- LAB_QUESTION
type: multiple-choice
question: "What is the role of Orbital in the training runtime?"
options:
  - "It provisions and runs the training container, exposing a PTY bridge for the interactive terminal"
  - "It hosts the GitHub Pages site where the lesson markdown is served"
  - "It is the Dynatrace app plugin that renders lesson content"
  - "It manages the GitHub Actions workflow that deploys the training"
correct: 0
explanation: "Orbital is the execution backend. It runs the container, exposes the PTY terminal, and executes shell-verification commands on behalf of the Dynatrace app."
-->
```

<!-- LAB_QUESTION
type: multiple-choice
question: "What is the role of Orbital in the training runtime?"
options:
  - "It provisions and runs the training container, exposing a PTY bridge for the interactive terminal"
  - "It hosts the GitHub Pages site where the lesson markdown is served"
  - "It is the Dynatrace app plugin that renders lesson content"
  - "It manages the GitHub Actions workflow that deploys the training"
correct: 0
explanation: "Orbital is the execution backend. It runs the container, exposes the PTY terminal, and executes shell-verification commands on behalf of the Dynatrace app."
-->

---

!!! success "All block types covered"
    You have seen every interactive block type in action. Continue to the example lesson to see them composed into a complete training.

<div class="grid cards" markdown>
- [03 — Example Lesson :octicons-arrow-right-24:](03-example-lesson.md)
</div>
