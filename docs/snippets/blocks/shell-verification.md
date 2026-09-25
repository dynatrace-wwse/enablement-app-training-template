```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify the Dynatrace Operator is Running"
buttonText: "Check Operator"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkOperatorReady"
expect:
  operator: exit-zero
hint: "Run the install commands above, wait 30 seconds, then check again."
explanation: "The operator is Running — the webhook and CSI driver are ready."
-->
```
