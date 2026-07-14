# Setup Guide — Jira Bug Dashboard

## Step 1: Install Claude Code

If you haven't already:

```bash
# macOS / Linux
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

Or download the desktop app from [claude.ai/claude-code](https://claude.ai/claude-code).

## Step 2: Get a Jira API Token

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a label like "Claude Dashboard"
4. Copy the token immediately (you won't see it again)

Store it as an environment variable (recommended):

```bash
# Add to your ~/.zshrc or ~/.bashrc
export JIRA_API_TOKEN="ATATT3xFf..."
```

Then reload: `source ~/.zshrc`

## Step 3: Find Your JQL Filter

The JQL filter determines which tickets appear on your dashboard. To find the right one:

### Option A: By Label (most common)

1. Open Jira → go to your project
2. Click any ticket assigned to you → check the "Labels" field
3. Note labels that identify your area (e.g., `sds_i2max_Navigation_zhangwei`)

```yaml
filter:
  jql: |
    labels in ("sds_i2max_Navigation_zhangwei")
    AND status not in (Closed, Done, Resolved)
```

### Option B: By Component

```yaml
filter:
  jql: |
    project = MYPROJ AND component = "Voice"
    AND status not in (Closed, Done, Resolved)
```

### Option C: By Assignee

```yaml
filter:
  jql: |
    project = MYPROJ AND assignee = currentUser()
    AND status not in (Closed, Done, Resolved)
```

### Validate your JQL

Go to Jira → Issues → Advanced Search → paste your JQL → verify results.

## Step 4: Find Custom Field IDs

Your Jira instance may have custom fields for severity/priority levels. To find the field ID:

1. Open any ticket in your browser
2. Open browser DevTools (F12) → Network tab
3. Reload the page
4. Find the API call to `/rest/api/3/issue/XXX`
5. Search the response JSON for your severity field value
6. Note the field name (e.g., `customfield_10037`)

Or ask your Jira admin.

## Step 5: Install the Skill

```bash
# Create the skills directory if it doesn't exist
mkdir -p ~/.claude/skills/jira-bug-dashboard

# Copy the skill file
cp skill/skill.md ~/.claude/skills/jira-bug-dashboard/skill.md

# Copy and edit the config
cp config.example.yaml ~/.claude/skills/jira-bug-dashboard/config.yaml
```

Now edit `~/.claude/skills/jira-bug-dashboard/config.yaml` with your values.

## Step 6: Test It

Open Claude Code in your terminal:

```bash
claude
```

Then type:

```
jira bug dashboard
```

Claude will:
1. Read your config
2. Fetch tickets from Jira
3. Triage and categorize them
4. Generate an HTML dashboard
5. Open it in your browser

## Step 7: Daily Use

Run it each morning to see your bug status. The dashboard saves a daily summary JSON, so tomorrow's run will show deltas (↑/↓) compared to today.

Typical workflow:
```
# Morning routine
claude "jira bug dashboard"

# After a triage meeting, with specific JQL override
claude "jira bug dashboard for labels = sds_audio_issues"
```

---

## Troubleshooting

### "command not found: claude"

Make sure Claude Code is installed and in your PATH:
```bash
which claude
# Should show: /usr/local/bin/claude or similar
```

### "401 Unauthorized"

Your API token is invalid or expired:
1. Check `echo $JIRA_API_TOKEN` shows a value
2. Test manually: `curl -s -u "you@company.com:$JIRA_API_TOKEN" "https://your.atlassian.net/rest/api/3/myself"`
3. If that fails, regenerate the token

### "No tickets found"

Your JQL might be wrong:
1. Copy the JQL from your config
2. Paste it into Jira's advanced search
3. If Jira shows results but the skill doesn't, check for encoding issues in quotes

### Charts look broken

Make sure you're opening the HTML in a modern browser (Chrome/Edge/Firefox). The file uses Chart.js from CDN, so you need internet access.
