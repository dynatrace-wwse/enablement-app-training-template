```markdown title="docs/1-deploy-operator.md"
# 1. Deploy the Dynatrace Operator

<!-- STEP_SETUP
commands:
  - dynatraceEvalReadSaveCredentials
-->

Why this step matters, in two or three sentences.            ← TELL

Run in the terminal:                                           ← DO

    helm install dynatrace-operator ...

## Validation

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the Dynatrace Operator is Running"
buttonText: "Check Operator"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOperatorReady"
expect:
  operator: exit-zero
hint: "Run the install commands above, wait 30 seconds, then check again."
explanation: "The operator is Running."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "Which two components inject the agent in AppOnly mode?"
options:
  - "A CSI driver and a mutating webhook"
  - "A DaemonSet per namespace"
correct: 0
explanation: "The CSI driver delivers the code modules; the webhook injects them at pod creation."
-->

<!-- LAB_SOLUTION
reveal: |
  Run the Helm install above. The framework wraps it in `dynatraceDeployOperator`.
commands:
  - dynatraceDeployOperator
verify:
  - source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOperatorReady
-->
```
