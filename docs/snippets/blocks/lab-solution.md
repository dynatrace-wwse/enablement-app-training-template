```markdown
<!-- LAB_SOLUTION
reveal: |
  The TODO app started before the Dynatrace webhook existed, so it was never
  injected. Restart it: `kubectl rollout restart deployment -n todoapp`.
commands:
  - restartTodoApp
verify:
  - LAB_WAIT=1 checkOneAgentInjected
-->
```
