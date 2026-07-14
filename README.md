# Jira Bug Dashboard — Claude Code Skill

> Turn your Jira tickets into a self-contained, interactive HTML dashboard via Claude Code.

![Dashboard Preview](docs/preview.png)

## What It Does

This Claude Code skill fetches your Jira tickets via REST API, triages them by PM priority, and generates a **single-file HTML dashboard** (no server needed) with:

- 📊 6 clickable Chart.js visualizations (status, priority, severity, age, assignees, trends)
- 🎯 KPI cards with daily delta comparison (↑ +3 red / ↓ -2 green)
- 🔥 Smart triage: new tickets, blockers, stale tickets, tickets needing your action
- 💬 Latest comment excerpts and @mention detection
- 🔗 All ticket keys are clickable links to Jira

## Quick Start

### Prerequisites

1. **Claude Code** installed ([docs](https://docs.anthropic.com/en/docs/claude-code))
2. **Jira API Token** ([create here](https://id.atlassian.com/manage-profile/security/api-tokens))
3. A Jira project with tickets you want to track

### Installation (3 steps)

```bash
# 1. Clone this repo
git clone https://github.com/YourOrg/jira-bug-dashboard.git

# 2. Copy the skill into your Claude Code skills directory
cp -r jira-bug-dashboard/skill ~/.claude/skills/jira-bug-dashboard

# 3. Create your config file
cp jira-bug-dashboard/config.example.yaml ~/.claude/skills/jira-bug-dashboard/config.yaml
# Edit config.yaml with your personal info (see Configuration below)
```

### First Run

Open Claude Code and type:

```
jira bug dashboard
```

Or any of the trigger phrases: `generate bug dashboard`, `bug report`, `bug triage`

---

## Configuration

Edit `config.yaml` to personalize the dashboard for your role:

```yaml
# === YOUR PERSONAL INFO ===
user:
  name: "Zhang Wei"                    # Your display name
  email: "wei.zhang@company.com"       # Jira account email
  name_variants:                        # How colleagues might @mention you
    - "Zhang Wei"
    - "wei.zhang"
    - "张伟"

# === JIRA CONNECTION ===
jira:
  base_url: "https://your-company.atlassian.net"
  api_token_env: "JIRA_API_TOKEN"      # env var name (recommended)
  # api_token: "YOUR_TOKEN"            # or hardcode (not recommended)

# === TICKET FILTER ===
filter:
  # JQL query to select YOUR tickets
  jql: |
    labels in ("sds_i2max_Navigation_zhangwei", "sds_i2max_zhangwei")
    AND status not in (Closed, Done, Resolved)
  # Alternative: use a saved filter
  # jql: "filter = 12345"

# === TRIAGE RULES ===
triage:
  new_ticket_days: 3                   # "Recent" = created within N days
  stale_days: 3                        # "Needs push" = no activity for N days
  focus_statuses:                      # Statuses that need active management
    - "Open"
    - "To Do"
    - "In Progress"
  non_focus_statuses:                  # Statuses in pipeline (less urgent)
    - "To Verify"
    - "Verifying"
    - "MR-Review"
    - "PO Review"
    - "Fixed"
    - "Rejected"
    - "Cancelled"
    - "In Verification"

# === CUSTOM FIELDS (check your Jira instance) ===
fields:
  severity_field: "customfield_10037"  # VoCA / Severity field ID
  a_level_field: "customfield_11451"   # A-level field ID (optional)

# === OUTPUT ===
output:
  directory: "~/loop-outputs/jira-triage"
  filename_pattern: "{date}-{project}-BUG.html"
  open_in_browser: true
```

### Finding Your Configuration Values

| Config | How to Find |
|--------|-------------|
| `jql` labels | Look at your tickets in Jira → check the Labels field |
| `severity_field` | Jira Admin → Custom Fields → find "Severity" or "VoCA" → note the ID |
| `focus_statuses` | Check your project's workflow → which statuses mean "needs your attention" |
| `name_variants` | How do colleagues spell your name in comments? Check a few tickets |

---

## How It Works

### Architecture

```
┌─────────────────┐       ┌──────────────────┐       ┌─────────────────┐
│  Claude Code    │──API──▶│  Jira REST API   │       │  HTML Output    │
│  (skill.md)     │◀─JSON──│  /rest/api/3/    │       │  (single file)  │
│                 │        └──────────────────┘       │                 │
│  1. Fetch       │                                    │  • Chart.js     │
│  2. Triage      │───────────────────────────────────▶│  • Dark theme   │
│  3. Generate    │                                    │  • Interactive   │
└─────────────────┘                                    └─────────────────┘
```

### Triage Priority (top → bottom)

| Priority | Rule | Why |
|----------|------|-----|
| 👤 Needs your action | Assigned to you OR @mentioned (unreplied) | You are the blocker |
| 🔥 New (≤3 days) | Recently created, grouped by priority | Respond fast |
| 🚨 Blocker | Priority = Blocker | Critical path |
| ⏰ Needs push | No activity for ≥3 days | Prevent tickets from rotting |
| 📋 Normal follow-up | Everything else in focus statuses | Regular tracking |
| 🔄 In pipeline | Non-focus statuses | Just awareness |

### Dashboard Layout

```
┌─────────────────────────────────────────────────┐
│  Header: Title + Filter + Date                   │
├─────────────────────────────────────────────────┤
│  KPI: Total | Focus | Alert | New | Pipeline | B │  ← clickable
├────────────┬────────────┬────────────────────────┤
│  Status    │  Priority  │  Severity/VoCA         │  ← charts (3x2)
│  (donut)   │  (donut)   │  (donut)              │
├────────────┼────────────┼────────────────────────┤
│  By Week   │  Age Dist  │  Top Assignees         │
│  (bar)     │  (bar)     │  (h-bar)              │
├────────────┴────────────┴────────────────────────┤
│  🔥 New Tickets (detailed cards)                  │
│  👤 Needs Your Action (detailed cards)            │
│  🚨 Blockers (detailed cards)                     │
│  ⏰ Needs Push (detailed cards)                   │
│  📋 Normal (detailed cards)                       │
│  🔄 Pipeline (collapsible groups)                 │
└─────────────────────────────────────────────────┘
```

---

## Customization Guide

### Change the JQL filter

The `filter.jql` field accepts any valid JQL. Common patterns:

```yaml
# By label (most common for PM tracking)
jql: 'labels = "my_team_label" AND status not in (Closed, Done)'

# By component
jql: 'project = MYPROJ AND component = "Voice" AND status not in (Closed)'

# By assignee
jql: 'project = MYPROJ AND assignee = currentUser() AND status not in (Closed)'

# By saved filter
jql: 'filter = 54321'
```

### Add custom triage rules

Edit the `## Step 2 — Triage Logic` section in `skill.md`. The triage is just a set of if/else rules applied to each ticket's fields.

### Change the visual theme

The dashboard uses a dark theme by default. Key CSS variables are in the generated HTML — ask Claude to swap to light theme or your brand colors.

### Change the output format

By default, output is a single `.html` file. You can ask Claude to also output:
- Markdown summary (for Slack/Teams posting)
- JSON data (for downstream automation)
- CSV export (for Excel analysis)

---

## Team Deployment

### Option A: Each person configures their own

Each team member:
1. Installs Claude Code
2. Copies the skill folder
3. Edits `config.yaml` with their own labels/name/token

### Option B: Shared skill, personal config

Put the skill in a shared location, and each person only provides their `config.yaml`:

```bash
# Team lead sets up shared skill
cp -r skill /path/to/shared/skills/jira-bug-dashboard

# Each member creates personal config
cat > ~/.claude/jira-dashboard-config.yaml << 'EOF'
user:
  name: "Li Ming"
  ...
EOF
```

### Option C: CI/CD automation

Use the skill as a template for a cron job that generates dashboards for the whole team. See `examples/ci-template.sh`.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "401 Unauthorized" | Check API token — regenerate at id.atlassian.com |
| "No tickets found" | Verify your JQL in Jira's search first |
| Charts misaligned on click | Ensure `position:relative` wrapper on canvas |
| X-axis labels hidden | Set `autoSkip: false` in Chart.js config |
| @mention detection misses you | Add more `name_variants` in config |
| "Old API endpoint" error | Skill uses POST `/rest/api/3/search/jql` (not the deprecated GET endpoint) |

---

## File Structure

```
jira-bug-dashboard/
├── README.md              ← You are here
├── config.example.yaml    ← Template config (copy & edit)
├── skill/
│   └── skill.md           ← The Claude Code skill definition
├── docs/
│   ├── preview.png        ← Dashboard screenshot
│   ├── setup-guide.md     ← Detailed setup walkthrough
│   └── faq.md             ← Extended FAQ
└── examples/
    ├── config-by-label.yaml
    ├── config-by-component.yaml
    ├── config-by-assignee.yaml
    └── ci-template.sh
```

---

## License

MIT — use it, modify it, share it.

---

## Credits

Built with [Claude Code](https://claude.ai/claude-code) skills system.  
Charts powered by [Chart.js](https://www.chartjs.org/).
