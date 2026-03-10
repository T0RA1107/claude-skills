#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# 1. Load .env file
if [ -f "$ENV_FILE" ]; then
    # Export variables so they are available within the script
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "⚠️ Warning: .env file not found ($ENV_FILE)"
fi

# 2. Validate required variables (from environment or .env)
if [ -z "$SLACK_TOKEN" ]; then
    echo "❌ Error: SLACK_TOKEN is not set."
    exit 1
fi

if [ -z "$DEFAULT_USER_ID" ]; then
    echo "❌ Error: DEFAULT_USER_ID is not set."
    exit 1
fi

# 3. Parse arguments
MESSAGE=$1
TARGET_ID=${2:-$DEFAULT_USER_ID}

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"message\" [target_id]"
    exit 1
fi

# 4. Call Slack API
RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $SLACK_TOKEN" \
     -H "Content-type: application/json; charset=utf-8" \
     --data "$(printf '{"channel":"%s","text":"%s"}' "$TARGET_ID" "$MESSAGE")" \
     https://slack.com/api/chat.postMessage)

# 5. Check result
if [[ $RESPONSE == *"\"ok\":true"* ]]; then
    echo "✅ Notification sent successfully"
else
    echo "❌ Notification failed: $RESPONSE"
    exit 1
fi
