```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify at least 10 log lines from your cluster reached Grail"
buttonText: "Count logs"
dql: |
  fetch logs, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | summarize count = count()
expect:
  operator: gte
  field: count
  value: 10
hint: "Logs take 1–2 minutes to reach Grail after the DynaKube is applied."
explanation: "Logs are flowing from every pod in your cluster."
-->
```
