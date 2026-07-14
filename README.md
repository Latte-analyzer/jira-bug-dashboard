# Jira Bug Dashboard — Claude Code Skill

> 通过 Claude Code 自动拉取 Jira ticket，生成可交互的 HTML 看板。

---

## 中文教程

### 效果

每天运行一次，自动生成一个本地 HTML 文件：
- 6 个可点击图表（状态、优先级、严重度、趋势、age、负责人）
- KPI 卡片 + 每日变化对比（↑↓）
- 按优先级分类的 ticket 详情卡片
- 所有 ticket 可直接点击跳转 Jira

### 你需要做的只有两件事

#### 1. 配置 MCP（让 Claude 能连接外部服务）

详见独立教程：
- [飞书 MCP 配置](docs/mcp-feishu-setup.md) — 接入飞书文档/消息/表格
- [Atlassian MCP 配置](docs/mcp-atlassian-setup.md) — 接入 Jira/Confluence

> Jira Bug Dashboard 本身不依赖 MCP，它直接用 REST API + Token。MCP 是可选的，用于日常交互查询。

#### 2. 确定你的 JQL（决定拉哪些 ticket）

去 Jira 网页 → Issues → Advanced Search，写好你的 JQL，确认能搜到你要的 ticket。

常见写法：

```
# 按 label（最常用，每个 PM 有自己的 label）
labels in ("sds_i2max_Navigation_<yourname>", "sds_i2max_<yourname>") AND status not in (Closed, Done, Resolved)

# 按 component
project = APRICOT AND component = "<YourComponent>" AND status not in (Closed, Done, Resolved)

# 按 assignee
project = APRICOT AND assignee = currentUser() AND status not in (Closed, Done, Resolved)
```

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/Latte-analyzer/jira-bug-dashboard.git
cd jira-bug-dashboard

# 2. 复制 skill 到 Claude Code 目录
cp -r skill ~/.claude/skills/jira-bug-dashboard

# 3. 生成 Jira API Token
#    打开 https://id.atlassian.com/manage-profile/security/api-tokens
#    创建 token，然后加到环境变量：
echo 'export JIRA_API_TOKEN="你的token"' >> ~/.zshrc
source ~/.zshrc

# 4. 复制并编辑配置文件
cp config.example.yaml ~/.claude/skills/jira-bug-dashboard/config.yaml
```

编辑 `config.yaml`，只需改这几项：

```yaml
user:
  name: "<你的名字>"
  email: "<你的邮箱>@mercedes-benz.com"

jira:
  base_url: "https://mercedes-benz.atlassian.net"
  api_token_env: "JIRA_API_TOKEN"

filter:
  jql: |
    <粘贴你在 Step 2 确认好的 JQL>
```

### 运行

打开 Claude Code，输入：

```
jira bug dashboard
```

HTML 会自动生成并在浏览器打开。

### 每天定时运行

用 cron 或手动每天早上跑一次：

```bash
# 编辑 crontab
crontab -e

# 每个工作日早上 9:00 运行
0 9 * * 1-5 /usr/local/bin/claude --print "jira bug dashboard"
```

---

## English Version

### What It Does

A Claude Code skill that fetches Jira tickets via REST API and generates a self-contained interactive HTML dashboard with Chart.js visualizations, KPI cards, and smart triage.

### Setup (2 things to configure)

#### 1. MCP Servers (optional)

- [Feishu/Lark MCP](docs/mcp-feishu-setup.md) — access Feishu docs/messages
- [Atlassian MCP](docs/mcp-atlassian-setup.md) — interactive Jira/Confluence queries

> The dashboard itself uses direct REST API + Token, not MCP. MCP is optional for ad-hoc queries.

#### 2. Your JQL filter

Go to Jira → Advanced Search → write a JQL that returns the tickets you want to track.

### Installation

```bash
git clone https://github.com/Latte-analyzer/jira-bug-dashboard.git
cd jira-bug-dashboard
cp -r skill ~/.claude/skills/jira-bug-dashboard
cp config.example.yaml ~/.claude/skills/jira-bug-dashboard/config.yaml
```

Generate a Jira API Token at https://id.atlassian.com/manage-profile/security/api-tokens, then:

```bash
echo 'export JIRA_API_TOKEN="your-token"' >> ~/.zshrc && source ~/.zshrc
```

Edit `config.yaml` — set your `email`, `jql`, and `base_url`.

### Run

```
jira bug dashboard
```

### Daily Schedule

```bash
# crontab: weekdays at 9am
0 9 * * 1-5 /usr/local/bin/claude --print "jira bug dashboard"
```

---

## File Structure

```
jira-bug-dashboard/
├── README.md                    ← 本文件
├── config.example.yaml          ← 配置模板
├── skill/
│   └── skill.md                 ← Claude Code skill 定义
├── docs/
│   ├── mcp-feishu-setup.md      ← 飞书 MCP 配置
│   ├── mcp-atlassian-setup.md   ← Atlassian MCP 配置
│   ├── setup-guide.md           ← 详细安装指南
│   └── faq.md                   ← 常见问题
└── examples/
    ├── config-by-label.yaml     ← 按 label 筛选示例
    ├── config-by-component.yaml ← 按 component 筛选示例
    ├── config-by-assignee.yaml  ← 按 assignee 筛选示例
    └── ci-template.sh           ← CI/CD 定时脚本
```

---

## License

MIT
