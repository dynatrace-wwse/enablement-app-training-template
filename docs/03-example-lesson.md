# 03 — Example Lesson

A complete minimal lesson that stitches all block types together. This page is the pattern to copy when building your first real lesson. Every block is live and runnable.

**Scenario:** "Verify the TODO Application is Instrumented with Dynatrace" — a realistic lesson that walks a learner through deploying OneAgent, restarting the app, and confirming observability is active.

---

<!-- STEP_SETUP
commands:
  - dynatraceEvalReadSaveCredentials && generateDynakube
-->

# Example: Verify Application Observability

In this example lesson, you will deploy the Dynatrace Operator, instrument the TODO application, and confirm that Dynatrace is collecting data from your cluster.

!!! tip "Before you start"
    Click **Start Environment** in the status bar above to provision your live environment. The checks below will not be active until the environment is ready.

---

## 1. Deploy the Dynatrace Operator (Helm)

Open the **Terminal** tab and run these three commands:

```bash
kubectl create namespace dynatrace

helm repo add dynatrace \
  https://raw.githubusercontent.com/Dynatrace/dynatrace-operator/main/config/helm/repos/stable
helm repo update

helm install dynatrace-operator dynatrace/dynatrace-operator \
  -n dynatrace
```

Wait a few seconds, then click **Check Operator** below.

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the Dynatrace Operator is Running in the dynatrace namespace"
buttonText: "Check Operator"
command: "kubectl get pods -n dynatrace --no-headers 2>/dev/null | grep -c Running"
expect:
  operator: gt
  value: 0
hint: "Run the three Helm commands above in order. Wait 30 seconds after `helm install` returns, then try again."
explanation: "Operator is Running — ready to deploy the DynaKube."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "The Dynatrace Operator uses AppOnly mode. Instead of a DaemonSet on every node, what two components does it use to inject the agent into pods?"
options:
  - "A CSI driver (delivers code modules) + a mutating webhook (injects at pod creation time)"
  - "A DaemonSet per namespace + an admission controller that labels pods"
  - "A Prometheus sidecar + a ServiceMonitor that configures scrape targets"
  - "A Helm chart post-install hook + a rolling restart of all deployments"
correct: 0
explanation: "AppOnly mode uses a CSI driver to deliver agent binaries via a shared volume, and a mutating webhook to inject them into pods at admission time. No node-level DaemonSet is required."
-->

---

## 2. Apply the DynaKube

The `STEP_SETUP` at the top of this page already ran `dynatraceEvalReadSaveCredentials && generateDynakube`, which created `.devcontainer/yaml/gen/dynakube.yaml` from your tenant credentials. Apply it now:

```bash
kubectl apply -f /workspaces/enablement-app-training-template/.devcontainer/yaml/gen/dynakube.yaml
```

Then monitor progress:

```bash
kubectl get pods -n dynatrace --watch
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the DynaKube custom resource was created"
buttonText: "Check DynaKube"
command: "kubectl get dynakube -n dynatrace --no-headers 2>/dev/null | grep -c ''"
expect:
  operator: gt
  value: 0
hint: "Apply the generated manifest file. If the file does not exist, check that the STEP_SETUP ran without errors."
explanation: "DynaKube CR is present — the operator is provisioning monitoring components."
-->

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the ActiveGate pod is Running in the dynatrace namespace"
buttonText: "Check ActiveGate"
command: "kubectl get pods -n dynatrace --no-headers 2>/dev/null | grep -i activegate | grep -c Running"
expect:
  operator: gt
  value: 0
hint: "The ActiveGate pod may take 1–2 minutes to start. Run `kubectl get pods -n dynatrace --watch` and wait."
explanation: "ActiveGate is Running — your cluster is connected to the Dynatrace tenant."
-->

Open the Kubernetes app to see your cluster topology:

[dt-app|dynatrace.kubernetes|Open Kubernetes App](placeholder)

---

## 3. Restart the Application

The TODO application was running before the Dynatrace webhook was deployed. Restart it so the webhook can inject OneAgent:

```bash
kubectl rollout restart deployment -n todoapp
kubectl rollout status deployment -n todoapp --timeout=120s
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify OneAgent was injected into the todoapp pods"
buttonText: "Check Injection"
command: "kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations.oneagent\\.dynatrace\\.com/injected}' 2>/dev/null | tr ' ' '\\n' | grep -c true"
expect:
  operator: gt
  value: 0
hint: "Run `kubectl rollout restart deployment -n todoapp` in the Terminal tab, wait for the rollout to complete, then try again."
explanation: "OneAgent injected — the todoapp pods have the `oneagent.dynatrace.com/injected: true` annotation."
-->

---

## 4. Call a Custom Helper Function

This template includes an example custom function. In your own training, you would add functions to `.devcontainer/util/my_functions.sh` for scenario setup, fault injection, or environment manipulation.

Open the **Terminal** tab and run:

```bash
customFunction
```

Expected output: a section header and a math result (1 + 1 = 2).

<!-- LAB_QUESTION
type: shell-verification
question: "Verify customFunction runs without errors"
buttonText: "Run customFunction"
command: "source .devcontainer/util/source_framework.sh && customFunction 2>&1 | grep -c '1 + 1'"
expect:
  operator: gt
  value: 0
hint: "Make sure .devcontainer/util/my_functions.sh exists and defines `customFunction`."
explanation: "customFunction ran successfully — custom helpers are working."
-->

---

## 5. Verify Observability in Dynatrace (DQL)

Generate some log data by interacting with the TODO application in the **Apps** tab. Add a new TODO item, then wait 1–2 minutes for Dynatrace to ingest the logs.

Open **Notebooks** in Dynatrace and run this query to explore your logs:

```dql
fetch logs
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
| filter k8s.namespace.name == "todoapp"
| filter contains(content, "Adding a new todo: ")
| filter timestamp > now() - 10m
| limit 5
```

The `k8s.cluster.name` filter scopes the query to **your** session's cluster (`{{DT_SESSION_ID}}` resolves to your personal session id) — required whenever several learners share one tenant.

Then validate with the button below:

<!-- LAB_QUESTION
type: dql-verification
question: "Verify Dynatrace is collecting logs from the todoapp namespace"
buttonText: "Check DT Logs"
dql: |
  fetch logs
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | filter contains(content, "Adding a new todo: ")
  | filter timestamp > now() - 10m
  | limit 1
expect:
  operator: not-empty
hint: "Open the TODO app in the Apps tab, create a new item, then wait 2 minutes before clicking this button."
explanation: "Dynatrace is collecting logs from todoapp — full observability is active."
-->

Explore your services:

[dt-app|dynatrace.services|Open Services App](placeholder)

---

## 6. Knowledge Assessment

Answer these questions to complete the example lesson:

<!-- boundScenarioId: template-authoring-fundamentals retake=false -->

!!! success "Example lesson complete!"
    You have seen every interactive block type working end-to-end. Use `03-example-lesson.md` as your starting pattern when building real lessons.

<div class="grid cards" markdown>
- [04 — Publishing & Validation :octicons-arrow-right-24:](04-publishing-validation.md)
</div>
