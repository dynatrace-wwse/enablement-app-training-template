```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify your cluster's logs reached Grail"
buttonText: "Check logs in Grail"
dql: |
  fetch logs, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | limit 1
expect:
  operator: not-empty
hint: "Logs take 1–2 minutes to reach Grail after the DynaKube is applied. Wait, then check again."
explanation: "Your cluster's logs are in Grail — captured by the log module, with no code change."
-->
```
