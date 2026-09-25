```markdown
<!-- LAB_QUESTION
type: dql-verification
question: "Verify at least one todoapp span reached Grail"
buttonText: "Count spans"
dql: |
  fetch spans, from:now()-15m
  | filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
  | filter k8s.namespace.name == "todoapp"
  | summarize count = count()
expect:
  operator: gte
  field: count
  value: 1
hint: "Only pods restarted after the DynaKube was applied produce traces."
explanation: "Traces are flowing from inside the application process."
-->
```
