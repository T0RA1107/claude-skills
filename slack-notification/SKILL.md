---
name: slack-notification
description: Automates status updates to the user via Slack for time-consuming research tasks (RL training, data processing), milestones, or errors.
---

# Slack Notification Management Skill

## Purpose
Automate status updates to Slack when performing long-running deep learning or reinforcement learning tasks. This enables an asynchronous workflow, allowing the user to monitor experiment progress (e.g., from Gymnax or WebDataset processing) while away from the terminal.

## Technical Implementation
- **Script Path**: `scripts/slack-notify.sh`
- **Execution**: Claude must call this script with a single string argument containing the formatted message.
- **Dependency**: Ensure the script has execution permissions (`chmod +x`).

## Execution Protocol
When sending a notification, Claude MUST:
1. **Summarize Logs**: Never post raw terminal output. Analyze logs/metrics and provide a high-level executive summary.
2. **Mobile-First Formatting**: Use Slack's markdown (bold for headers) and emojis for readability.
3. **Security**: NEVER include API keys, passwords, or sensitive project paths in the message.

## Trigger Criteria
Claude should proactively suggest or initiate a notification in these scenarios:
- **Long Tasks**: Any execution estimated or observed to exceed 5 minutes.
- **Research Milestones**: Completion of model training, successful data indexing (WebDataset), or PR creation.
- **Errors/Crashes**: Immediate notification upon script failure or unexpected exit codes.
- **User Input Needed**: When a long process stops and waits for a decision.

## Notification Template
- **Header**: `[Emoji] [STATUS]: [Task Name]`
- **Context**:
  - *Project*: `[Project Name]`
  - *Duration*: `[HH:mm:ss]`
- **Summary**: 1-2 sentences on the outcome.
- **Metrics/Highlights**: Key numbers (e.g., Loss, Reward, Files Processed).
- **Next Action**: Proactive recommendation for the next step.

## Reference Examples
When formatting messages, Claude MUST refer to the specific templates located in `examples/`.

Choose the most appropriate template from the folder based on the current situation (Success, Error, or Milestone).
