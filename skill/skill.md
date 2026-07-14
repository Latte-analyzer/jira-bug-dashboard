---
name: jira-bug-dashboard
description: Fetch Jira tickets via REST API, triage by PM priority, and generate an interactive HTML dashboard with clickable charts and detailed ticket analysis.
triggers:
  - 'jira bug dashboard'
  - 'generate bug dashboard'
  - 'bug report'
  - 'bug triage'
  - 'ticket dashboard'
---

# Jira Bug Dashboard

Generate an interactive HTML dashboard for your Jira project bugs. Fetches tickets via Jira REST API, triages by PM priority, and outputs a self-contained HTML file with Chart.js visualizations.

## Configuration

Before first use, create `config.yaml` in this skill's directory (see `config.example.yaml` in the repo). The config defines:
- Your name and @mention variants (for "needs your action" detection)
- Jira connection (base URL + API token)
- JQL filter (which tickets to fetch)
- Triage rules (thresholds, statuses)
- Custom field IDs (severity, etc.)
- Output path

If no config.yaml exists, prompt the user to set up their configuration.

---

## Step 1 — Load Configuration

Read `config.yaml` from this skill's directory. Extract:
- `user.name`, `user.email`, `user.name_variants` → for @mention and assignee detection
- `jira.base_url`, `jira.api_token_env` (or `jira.api_token`) → for API auth
- `filter.jql` → the query
- `triage.*` → thresholds and status groupings
- `fields.*` → custom field IDs
- `output.*` → where to save

If `api_token_env` is set, read the token from that environment variable.

---

## Step 2 — Fetch Tickets

Use Jira REST API (POST method, newer endpoint):

```bash
curl -s -u "{user.email}:{api_token}" \
  -X POST "{jira.base_url}/rest/api/3/search/jql" \
  -H "Content-Type: application/json" \
  -d '{"jql":"{filter.jql}","maxResults":100,"fields":["summary","status","priority","assignee","reporter","labels","created","updated","fixVersions","comment","description","{fields.severity_field}","{fields.a_level_field}"]}'
```

Handle pagination if `total > maxResults` (increment `startAt`).

---

## Step 3 — Triage Logic

### Priority order (what the PM sees first):

**1. 👤 需要你操作 (across ALL statuses, extracted FIRST)**
- Assignee matches any of `user.name_variants`
- Latest comment @mentions any of `user.name_variants` (case-insensitive) AND commenter is NOT the user themselves = unreplied

**2. Focus statuses (重点关注): {triage.focus_statuses}**

Within focus, categorize:
- 🔥 **近N天新建**: `age_days <= triage.new_ticket_days`, grouped by priority (Blocker > Highest > High > Medium)
- 🚨 **Blocker**: priority = Blocker
- ⏰ **需催进度**: `days_since_last_comment >= triage.stale_days` (or days_since_updated if no comments)
- 📋 **正常跟进**: everything else in focus

**3. Non-focus statuses (流转中): {triage.non_focus_statuses}**

Grouped by status with next-action hint from `non_focus_actions` config. Expandable to see individual tickets.

---

## Step 4 — Dashboard HTML Structure

### Layout (top to bottom):
1. **Header**: title + JQL filter + date
2. **KPI row** (6 clickable cards): Total Open | 🎯 重点关注 | ⚠️ 需处理 | 🔥 近N天新建 | 流转中 | Blocker
3. **Charts grid** (3x2, all clickable with drill-down modal):
   - Status distribution (doughnut)
   - Priority distribution (doughnut)
   - Severity distribution (doughnut)
   - Created by week (bar)
   - Ticket age (bar)
   - Top 10 Assignees (horizontal bar)
4. **🔥 近N天新建** — detailed cards grouped by priority
5. **👤 需要你操作** — detailed cards
6. **🚨 Blocker** — detailed cards (if any)
7. **⏰ 需催进度** — detailed cards
8. **📋 正常跟进** — detailed cards
9. **🔄 流转中** — collapsible groups by status

### Ticket card content (detailed):
- Key (clickable link to Jira)
- Badges: triage reasons + status + priority + severity
- Summary (title)
- Description excerpt (📋 first 180 chars)
- Latest comment (💬 commenter + time + days ago + text)
- Meta: assignee, created date, age, last activity date
- PM Action suggestion (green bar)

---

## Step 5 — Chart.js Configuration

Critical settings to avoid visual issues:

```javascript
// Canvas wrapper (prevents click offset):
// <div class="chart-wrap" style="position:relative;width:100%;height:160px">
//   <canvas id="chartId"></canvas>
// </div>

{
  responsive: true,
  maintainAspectRatio: false,
  layout: { padding: { top: 2, bottom: 2, left: 0, right: 4 } },
  barPercentage: 0.85,
  categoryPercentage: 0.9,
  onClick: (e, el) => { if(el.length) drill(chartId, labels[el[0].index]) }
}
```

Chart colors:
```javascript
const statusColors = {'To Do':'#94a3b8','Open':'#fbbf24','In Progress':'#3b82f6','To Verify':'#10b981','MR-Review':'#8b5cf6','Verifying':'#6ee7b7','Fixed':'#22c55e','Rejected':'#ef4444','In Verification':'#14b8a6','PO Review':'#f472b6','Cancelled':'#64748b'};
const priorityColors = {'Blocker':'#ef4444','Highest':'#fbbf24','High':'#a3e635','Medium':'#94a3b8','Low':'#64748b'};
```

---

## Step 6 — Interaction Features

1. **KPI cards**: click → modal with filtered tickets
2. **Charts**: click any segment/bar → modal with matching tickets
3. **All ticket references**: `<a href="{jira.base_url}/browse/{KEY}" target="_blank">`
4. **Non-focus groups**: click header to expand/collapse
5. **Modal**: ESC or overlay click to close

---

## Step 7 — Daily Comparison (KPI Deltas)

Each KPI card shows delta vs. yesterday:
- `↑ +N` (red) = more bugs (bad)
- `↓ -N` (green) = fewer bugs (good)
- `— 0` (gray) = no change

Save summary JSON alongside HTML:
```json
{"date":"2026-07-13","total":32,"focus":13,"alert":5,"new_3d":4,"non_focus":19,"blocker":0}
```

Load previous day's summary for comparison. If no previous exists, omit deltas.

---

## Step 8 — Output

```bash
mkdir -p {output.directory}
# Save HTML: {output.directory}/{date}-{filename}.html
# Save summary: {output.directory}/{date}-summary.json
# Open in browser if output.open_in_browser is true
```

---

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| Old API returns error | Use POST `/rest/api/3/search/jql` with JSON body |
| Chart.js click offset in flex | Wrap canvas in `position:relative` div with explicit height |
| Chart.js hides bar labels | Set `autoSkip: false, maxRotation: 0` |
| Horizontal bar labels invisible | Use bright text color `#e2e8f0` |
| @mention missed in non-focus | Scan ALL tickets first before status split |
