# FAQ — Jira Bug Dashboard

## General

### Q: Do I need to pay for Claude Code?

Yes, Claude Code requires an Anthropic account with API access or a Max subscription. Check [pricing](https://www.anthropic.com/pricing).

### Q: Does this store my Jira data anywhere?

No. Everything runs locally on your machine. The dashboard HTML is saved to your local disk. No data is sent anywhere except to the Jira API (to fetch) and to Anthropic (as part of Claude's conversation context during generation).

### Q: Can multiple team members use the same dashboard?

Each person generates their own dashboard with their own config. If you want a shared dashboard, consider the CI/CD approach in `examples/ci-template.sh`.

---

## Configuration

### Q: How do I track tickets from multiple labels?

Use `in` operator in JQL:

```yaml
filter:
  jql: |
    labels in ("label_1", "label_2", "label_3")
    AND status not in (Closed, Done, Resolved)
```

### Q: Can I exclude certain ticket types?

Yes, add to your JQL:

```yaml
filter:
  jql: |
    labels = "my_label"
    AND status not in (Closed, Done, Resolved)
    AND issuetype != "Epic"
```

### Q: My Jira doesn't have a severity/VoCA field. What do I do?

Set `fields.severity_field` to `null` in your config. The severity chart will be skipped.

```yaml
fields:
  severity_field: null
```

### Q: Can I change the triage thresholds?

Yes. In `config.yaml`:

```yaml
triage:
  new_ticket_days: 7     # Default is 3. Increase if you want a wider "new" window
  stale_days: 5          # Default is 3. Increase if your team moves slower
```

---

## Triage Logic

### Q: What counts as "needs your action"?

Two scenarios:
1. The ticket is assigned directly to you
2. Someone @mentioned you in a comment and you haven't replied yet

The skill checks `user.name_variants` in your config for matching.

### Q: How does it detect @mentions?

It searches the latest comment for any string in your `name_variants` list (case-insensitive). It also checks that the commenter is NOT you (otherwise you'd get your own replies flagged).

### Q: Can I customize which statuses are "focus" vs "non-focus"?

Yes. Edit `triage.focus_statuses` and `triage.non_focus_statuses` in config. The distinction is: focus = needs your active management, non-focus = it's in someone else's court.

---

## Output

### Q: Can I change the output location?

```yaml
output:
  directory: "~/my-dashboards"
  filename_pattern: "{date}-mybug.html"
```

### Q: Can I get Markdown output instead of HTML?

Ask Claude: "jira bug dashboard, output as markdown". The skill will adapt.

### Q: How do daily deltas work?

Each run saves a `{date}-summary.json` alongside the HTML. The next day's run reads yesterday's JSON to compute differences. First run has no deltas.

---

## Troubleshooting

### Q: The skill doesn't trigger when I type "jira bug dashboard"

Check that the skill file exists at `~/.claude/skills/jira-bug-dashboard/skill.md`. If you put it elsewhere, Claude Code won't find it.

### Q: Fetch returns 0 tickets but Jira shows results

Common causes:
- JQL has smart quotes (`""`) instead of straight quotes (`""`) — fix in your editor
- API token expired — regenerate at id.atlassian.com
- `maxResults` pagination — the skill handles this, but check if Claude shows pagination warnings

### Q: Dashboard HTML is blank

Open the browser's Developer Console (F12) and check for errors. Most common: Chart.js CDN blocked by corporate firewall. Solution: ask Claude to embed Chart.js inline instead of CDN.
