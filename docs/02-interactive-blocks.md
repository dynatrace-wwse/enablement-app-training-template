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

## 5. DQL Query — inline read-only

Use when: you want to show learners an example DQL query to explore their tenant. No validation required — just document the query in a `dql` code block.

**How to author:**

````markdown
Run this DQL query in **Notebooks** to explore your logs:

```dql
fetch logs
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
| filter k8s.namespace.name == "todoapp"
| filter timestamp > now() - 10m
| limit 10
```
````

!!! important "Scope every Grail query to the learner's cluster"
    `{{DT_SESSION_ID}}` is substituted by the session player with the learner's per-user id (`<user>-<yyyymmdd>`), which the framework also bakes into the session's cluster identity (DynaKube name / `hostGroup`). The `endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")` filter is what lets 100 learners run this training against ONE tenant without seeing each other's data — include it in every log/span query, inline or verification. See [AUTHORING → Template variables](AUTHORING.md#template-variables).

---

## 6. DQL Verification — query with assertion

Use when: you want to gate lesson progression on a Dynatrace entity or observability state. The learner's tenant must return a result that matches `expect`.

**`expect.operator: not-empty`** — passes if DQL returns at least one row:

```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify Dynatrace is collecting logs from todoapp"
buttonText: "Check DT Logs"
dql: |
  fetch logs
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | filter timestamp > now() - 10m
  | limit 1
expect:
  operator: not-empty
hint: "Interact with the app first to generate some logs, then wait 2 minutes."
explanation: "Dynatrace is collecting logs — observability is active."
-->
```

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
