#!/bin/bash
# ============================================================
# CI/CD Template: Generate Jira Bug Dashboard on schedule
# ============================================================
# Usage: Run via cron or CI pipeline (GitHub Actions, Jenkins, etc.)
#
# Prerequisites:
#   - Claude Code CLI installed
#   - JIRA_API_TOKEN set in environment
#   - config.yaml in expected path
#
# Example cron (daily at 9:00 AM):
#   0 9 * * 1-5 /path/to/ci-template.sh
# ============================================================

set -e

# Configuration
SKILL_DIR="$HOME/.claude/skills/jira-bug-dashboard"
OUTPUT_DIR="$HOME/loop-outputs/jira-triage"
DATE=$(date +%Y-%m-%d)

# Verify prerequisites
if ! command -v claude &> /dev/null; then
    echo "ERROR: Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

if [ -z "$JIRA_API_TOKEN" ]; then
    echo "ERROR: JIRA_API_TOKEN environment variable not set"
    exit 1
fi

if [ ! -f "$SKILL_DIR/config.yaml" ]; then
    echo "ERROR: Config not found at $SKILL_DIR/config.yaml"
    exit 1
fi

# Generate dashboard
echo "[$DATE] Generating Jira Bug Dashboard..."
claude --print "jira bug dashboard"

# Verify output
if [ -f "$OUTPUT_DIR/$DATE-"*".html" ]; then
    echo "[$DATE] Dashboard generated successfully:"
    ls -la "$OUTPUT_DIR/$DATE-"*
else
    echo "[$DATE] WARNING: No output HTML found"
    exit 1
fi

echo "[$DATE] Done."
