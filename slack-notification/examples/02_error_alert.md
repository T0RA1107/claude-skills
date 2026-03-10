# Example: Runtime Error/Failure
Use this format when a process crashes or encounters an unrecoverable error.

```bash
scripts/slack-notify.sh "❌ *ERROR: Script Execution Failed*
*Project*: [Project Name]
*Duration*: [HH:mm:ss]
*Summary*: The process terminated unexpectedly due to a runtime exception during the execution phase.
*Metrics/Highlights*:
• Exit Code: 1
• Error Type: \`RuntimeError\`
• Traceback: See \`logs/error.log\`
*Next Action*: Please check the resource availability or logs to debug the issue."
```
