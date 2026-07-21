# Jira Bug Dashboard — Claude Code Skill

> 用 Claude Code 自动拉取 Jira ticket，生成可交互的 HTML 看板。

---

## 中文教程

### 效果

每次运行生成一个本地 HTML 文件：
- 6 个可点击图表（状态、优先级、严重度、趋势、age、负责人）
- KPI 卡片 + 每日变化对比（↑↓）
- 按优先级分类的 ticket 详情卡片
- 所有 ticket 可直接点击跳转 Jira

### 原理

没有什么复杂的架构。就是 Claude Code 用 `curl` 调 Jira REST API 拉 JSON，然后生成 HTML。

```
你提供: API Token + JQL 筛选条件
     ↓
Claude Code: curl Jira API → 拿到 JSON → 分类/triage → 生成 HTML
     ↓
输出: 一个本地 HTML 文件，浏览器打开即可
```

### 你只需要提供两样东西

#### 1. Jira API Token

生成方式：
1. 打开 https://id.atlassian.com/manage-profile/security/api-tokens
2. 点 "Create API token"
3. 复制 token

拿到后存到环境变量：
```bash
echo 'export JIRA_API_TOKEN="你的token"' >> ~/.zshrc
source ~/.zshrc
```

#### 2. 你要分析的 Jira URL（JQL 筛选条件）

去 Jira 网页 → Issues → Advanced Search → 写好 JQL → 确认搜出来的是你要的 ticket。

常见 JQL 示例：
```
# 按 label（每个 PM 通常有自己的 label）
labels in ("sds_i2max_<Feature>_<yourname>") AND status not in (Closed, Done, Resolved)

# 按 component
project = APRICOT AND component = "<YourComponent>" AND status not in (Closed, Done, Resolved)

# 按 assignee
project = APRICOT AND assignee = currentUser() AND status not in (Closed, Done, Resolved)
```

### 安装

```bash
# 1. 克隆仓库
git clone https://github.com/Latte-analyzer/jira-bug-dashboard.git

# 2. 复制 skill 到 Claude Code
cp -r jira-bug-dashboard/skill ~/.claude/skills/jira-bug-dashboard
```

### 使用

打开 Claude Code，把你的 token 和 JQL 告诉它：

```
我的 Jira API token 是 ATATT3xFf...，
帮我拉这个 JQL 的 ticket 生成 bug dashboard：
labels in ("sds_i2max_Audio_xxx") AND status not in (Closed, Done, Resolved)
```

或者如果你已经把 token 存到环境变量了，直接说：

```
jira bug dashboard
```

Claude 会读取环境变量里的 token，用 skill 里配置的默认 JQL 去拉数据。

### 后续每次运行

第一次跑通后，Claude 会记住你的 token 和 JQL。以后直接输入 `jira bug dashboard` 就行。

---

## English Version

### What It Does

A Claude Code skill that fetches Jira tickets via `curl` + REST API and generates a self-contained interactive HTML dashboard.

### What You Need to Provide

1. **Jira API Token** — generate at https://id.atlassian.com/manage-profile/security/api-tokens
2. **Your JQL filter** — the Jira search query that returns the tickets you care about

### Installation

```bash
git clone https://github.com/Latte-analyzer/jira-bug-dashboard.git
cp -r jira-bug-dashboard/skill ~/.claude/skills/jira-bug-dashboard
```

### Usage

Tell Claude your token and JQL:

```
My Jira API token is ATATT3xFf..., generate a bug dashboard for:
labels in ("my_label") AND status not in (Closed, Done, Resolved)
```

Or store the token in `~/.zshrc` as `JIRA_API_TOKEN` and just run:

```
jira bug dashboard
```

---

## 补充说明

### MCP 是什么？跟这个有关系吗？

MCP 是 Claude Code 连接外部服务的协议。本项目**不需要 MCP**——它直接用 curl 调 Jira API。

如果你另外想让 Claude 能搜索飞书文档或交互式查 Jira，可以选配 MCP：
- [飞书 MCP 配置](docs/mcp-feishu-setup.md) — 接入飞书文档/消息/表格
- [Atlassian MCP 配置](docs/mcp-atlassian-setup.md) — 接入 Jira/Confluence 交互查询

### Skill 里的 triage 逻辑

Claude 拉到 ticket 后会自动分类：
- 👤 需要你操作（assigned to you / @你 未回复）
- 🔥 近 3 天新建
- 🚨 Blocker
- ⏰ 超 3 天没人动
- 📋 正常跟进
- 🔄 流转中

这些规则写在 `skill/skill.md` 里，可以按你的需求改。

---

## File Structure

```
jira-bug-dashboard/
├── README.md                    ← 本文件
├── skill/
│   └── skill.md                 ← Claude Code skill（triage 逻辑 + 输出格式）
├── docs/
│   ├── mcp-feishu-setup.md      ← 飞书 MCP 配置（可选）
│   ├── mcp-atlassian-setup.md   ← Atlassian MCP 配置（可选）
│   ├── setup-guide.md           ← 详细指南
│   └── faq.md                   ← 常见问题
└── examples/
    ├── config-by-label.yaml
    ├── config-by-component.yaml
    └── config-by-assignee.yaml
```

---

## License

MIT
