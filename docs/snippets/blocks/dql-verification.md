```markdown
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
hint: "Add a todo first. Logs take 1–2 minutes to reach Grail."
explanation: "Your todo's log line is in Grail — captured by the log module, with no code change."
-->
```
