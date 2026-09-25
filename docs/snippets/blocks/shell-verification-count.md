```markdown
<!-- LAB_QUESTION
type: shell-verification
question: "Verify at least 3 kube-system pods are Running"
buttonText: "Check kube-system"
command: "kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c Running"
expect:
  operator: gt
  value: 2
hint: "k3d starts these by itself. Wait a minute and try again."
explanation: "The control plane is healthy."
-->
```
