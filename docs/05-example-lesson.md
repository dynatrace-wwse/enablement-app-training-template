# 05 — Example Lesson

A complete lesson that puts everything together, modelled on [Kubernetes 101](https://github.com/dynatrace-wwse/enablement-kubernetes-101): the learner instruments the TODO app that `post-create.sh` deployed, and every action is **checked** in the container, **proven** in Grail and **solvable** by automation.

!!! note "One page here, one page per step in your training"
    To keep the template short this lesson is a single page, so its solutions are merged into one. In your training, give each section its own page (its own `nav` entry): the app treats a page as a step, and resume and the nightly test work step by step. Kubernetes 101 splits exactly these sections into three pages.

<!-- STEP_SETUP
commands:
  - dynatraceEvalReadSaveCredentials && generateDynakube
-->

---

## 1. Deploy the Dynatrace Operator

The operator manages everything Dynatrace runs in the cluster. Install it with Helm, in the **terminal**:

```bash
helm install dynatrace-operator oci://public.ecr.aws/dynatrace/dynatrace-operator \
  --create-namespace --namespace dynatrace --atomic
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the Dynatrace Operator is Running"
buttonText: "Check Operator"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOperatorReady"
expect:
  operator: exit-zero
hint: "Run the helm install above, wait about 30 seconds, then check again. `kubectl get pods -n dynatrace` shows the state."
explanation: "The operator is Running, together with its webhook and CSI driver."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "In AppOnly mode, which two components get the agent into your pods?"
options:
  - "A CSI driver that delivers the code modules, and a mutating webhook that injects them at pod creation"
  - "A OneAgent DaemonSet on every node"
  - "A sidecar container added to every deployment"
  - "A Helm post-install hook that restarts every deployment"
correct: 0
explanation: "AppOnly needs no host agent: the CSI driver provides the binaries and the webhook injects them when a pod is created."
-->

---

## 2. Deploy the DynaKube

The DynaKube tells the operator *what* to monitor. It was **generated for you** when this step opened (the step's `STEP_SETUP` ran `generateDynakube`, from the [framework defaults](02-automation.md#the-dynakube-defaults-and-your-override)). Look at it, then apply it:

```bash
cat .devcontainer/yaml/gen/dynakube.yaml
kubectl apply -f .devcontainer/yaml/gen/dynakube.yaml
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the DynaKube custom resource exists"
buttonText: "Check DynaKube"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkDynakube"
expect:
  operator: exit-zero
hint: "Apply the generated manifest with kubectl apply -f .devcontainer/yaml/gen/dynakube.yaml."
explanation: "The DynaKube exists — the operator is rolling out the ActiveGate and the log module."
-->

Open your cluster in Dynatrace:

[dt-app|dynatrace.kubernetes|Open the Kubernetes app](placeholder)

---

## 3. Restart the application

The TODO app was started by `post-create.sh` **before** the webhook existed, so it is not instrumented yet. Restart it so its new pods pass through the webhook:

```bash
kubectl rollout restart deployment -n todoapp
kubectl rollout status deployment -n todoapp --timeout=180s
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify OneAgent was injected into the todoapp pods"
buttonText: "Check Injection"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOneAgentInjected"
expect:
  operator: exit-zero
hint: "Restart the deployment, wait for the rollout to finish, then check again."
explanation: "The pods carry oneagent.dynatrace.com/injected=true — every request is now traced from inside the process."
-->

---

## 4. Prove it in Grail

Open the TODO app and **add a todo**. Its log line and its trace reach Grail within a minute or two. Explore them yourself:

```dql
fetch logs, from:now()-15m
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
| filter k8s.namespace.name == "todoapp"
| filter contains(content, "Adding a new todo")
| fields timestamp, content
| limit 5
```

The `endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")` line scopes the query to **your** cluster — in a workshop, everyone shares one tenant.

<!-- LAB_QUESTION
type: dql-verification
question: "Verify the log line for your todo reached Grail"
buttonText: "Check logs in Grail"
dql: |
  fetch logs, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | filter contains(content, "Adding a new todo")
  | limit 1
expect:
  operator: not-empty
pollSeconds: 15
timeoutSeconds: 180
hint: "Add a todo in the app first. Logs take 1–2 minutes to reach Grail."
explanation: "Your todo's log line is in Grail — collected by the log module, with no change to the application."
-->

<!-- LAB_QUESTION
type: dql-verification
question: "Verify the trace for your todo reached Grail"
buttonText: "Check traces in Grail"
dql: |
  fetch spans, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | limit 1
expect:
  operator: not-empty
pollSeconds: 15
timeoutSeconds: 180
hint: "Only pods restarted after the DynaKube was applied are traced. Pass the injection check, add another todo, and wait 1–2 minutes."
explanation: "The trace is in Grail — the restart made the request visible from inside the process."
-->

[dt-app|dynatrace.distributedtraces|Open Distributed Traces](placeholder)

<!-- LAB_SOLUTION
reveal: |
  1. Install the operator — `dynatraceDeployOperator` wraps the Helm install.
  2. Apply the DynaKube — `deployApplicationMonitoring` generates and applies the AppOnly DynaKube and waits for it.
  3. Restart the TODO app so it gets injected — `restartTodoApp` (in `my_functions.sh`).
  4. Create a todo so a log line and a trace exist — `generateTodoTraffic` (in `my_functions.sh`).
commands:
  - dynatraceDeployOperator
  - deployApplicationMonitoring
  - restartTodoApp
  - generateTodoTraffic
verify:
  - source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOperatorReady
  - source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkDynakube
  - source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOneAgentInjected
-->

---

## 5. Knowledge check

<!-- LAB_QUESTIONAIRE: template-authoring-fundamentals retake=true -->

!!! success "That is a complete interactive step"
    Content, a check in the container, a check in Grail, a quiz, and a solution that lets the platform replay it — every night, and every time a learner resumes. Copy this page as the starting point of your first real lesson.

<div class="grid cards" markdown>
- [06 — Test, Publish & Ship :octicons-arrow-right-24:](06-test-publish-ship.md)
</div>
