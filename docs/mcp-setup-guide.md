# MCP Server 配置教程

> 本教程基于 Claude Code 的 MCP (Model Context Protocol) 机制，让 Claude 能直接调用飞书和 Jira/Atlassian 的 API。

---

## 什么是 MCP

MCP 是 Claude Code 调用外部服务的标准协议。配置好后，Claude 可以直接：
- 搜索/读取飞书文档
- 发送飞书消息
- 查询 Jira ticket（通过 Atlassian MCP）

配置文件位于 `~/.claude/mcp.json`。

---

## 方式一：飞书 MCP（stdio 模式）

飞书 MCP 基于 `npx` 本地启动一个进程，Claude 通过 stdin/stdout 与其通信。

### Step 1：创建飞书应用

1. 打开 [飞书开放平台](https://open.feishu.cn/app)
2. 点击「创建企业自建应用」
3. 记下 **App ID** 和 **App Secret**

### Step 2：配置应用权限

在飞书开放平台 → 你的应用 → 权限管理，开通以下权限：

| 权限 | 用途 |
|------|------|
| `docx:document:readonly` | 读取云文档内容 |
| `wiki:wiki:readonly` | 搜索/读取知识库 |
| `im:message:readonly` | 读取聊天消息 |
| `im:chat:readonly` | 列出群组 |
| `contact:user.id:readonly` | 按邮箱查用户 ID |
| `bitable:bitable` | 读写多维表格（如需） |

然后在「版本管理与发布」中发布一个版本，等管理员审批通过。

### Step 3：写入 mcp.json

```bash
# 编辑（或创建）文件
vim ~/.claude/mcp.json
```

写入：

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": [
        "-y",
        "@larksuiteoapi/lark-mcp",
        "mcp",
        "-a", "<YOUR_APP_ID>",
        "-s", "<YOUR_APP_SECRET>"
      ]
    }
  }
}
```

将 `<YOUR_APP_ID>` 和 `<YOUR_APP_SECRET>` 替换为你应用的实际值。

### Step 4：在 settings.json 中启用

```bash
vim ~/.claude/settings.json
```

确保 `enabledMcpjsonServers` 包含 `"feishu"`：

```json
{
  "enabledMcpjsonServers": [
    "feishu"
  ]
}
```

### Step 5：验证

重启 Claude Code，输入：

```
搜索飞书文档 "周报"
```

如果能返回文档列表，说明配置成功。

---

## 方式二：Atlassian MCP（HTTP 模式）

Atlassian 提供官方托管的 MCP 服务端，不需要本地启动进程，只需指向一个 URL。

### Step 1：确认 Atlassian 账号

确保你有公司 Atlassian 账号（能登录 `https://your-company.atlassian.net`）。

### Step 2：写入 mcp.json

在 `~/.claude/mcp.json` 的 `mcpServers` 中加入：

```json
{
  "mcpServers": {
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp"
    }
  }
}
```

### Step 3：在 settings.json 中启用

```json
{
  "enabledMcpjsonServers": [
    "feishu",
    "atlassian"
  ]
}
```

### Step 4：首次认证

首次使用时 Claude Code 会弹出 OAuth 授权页面，用你的 Atlassian 账号登录并授权即可。

> **注意：** Atlassian HTTP MCP 的 OAuth 有时不稳定。如果遇到认证问题，本项目的 Jira Bug Dashboard 技能使用的是**直接 REST API + API Token** 方式作为备选（更可靠）。

---

## 完整 mcp.json 示例

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": [
        "-y",
        "@larksuiteoapi/lark-mcp",
        "mcp",
        "-a", "<YOUR_FEISHU_APP_ID>",
        "-s", "<YOUR_FEISHU_APP_SECRET>"
      ]
    },
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp"
    }
  }
}
```

---

## 完整 settings.json 关键字段

```json
{
  "enabledMcpjsonServers": [
    "feishu",
    "atlassian"
  ],
  "permissions": {
    "allow": [
      "mcp__feishu__docx_builtin_search",
      "mcp__feishu__wiki_v2_space_getNode",
      "mcp__feishu__docx_v1_document_rawContent",
      "mcp__feishu__wiki_v1_node_search",
      "mcp__feishu__im_v1_chat_list",
      "mcp__feishu__contact_v3_user_batchGetId",
      "mcp__feishu__im_v1_message_list"
    ]
  }
}
```

> `permissions.allow` 列表的作用：让 Claude 调用这些 MCP 工具时不需要每次弹窗确认。不加也能用，只是每次都要手动点允许。

---

## 两种 MCP 模式对比

| | stdio 模式（飞书） | HTTP 模式（Atlassian） |
|---|---|---|
| 启动方式 | Claude Code 本地 spawn 进程 | 连接远程 URL |
| 配置字段 | `command` + `args` | `type: "http"` + `url` |
| 认证 | App ID/Secret 写在 args 里 | OAuth 浏览器授权 |
| 优点 | 稳定、不依赖外部服务可用性 | 零部署、官方维护 |
| 缺点 | 需要本地 Node.js 环境 | OAuth 偶尔失效 |

---

## 常见问题

### Q: npx 命令报错 "not found"

确保已安装 Node.js (≥18)：
```bash
node --version   # 应显示 v18+ 或 v20+
npm --version
```

### Q: 飞书 MCP 连接后没有可用工具

应用权限未生效。去飞书开放平台检查：
1. 权限是否已申请
2. 版本是否已发布并审批通过

### Q: Atlassian MCP OAuth 一直跳转失败

这是已知问题。**备选方案**：直接用 REST API + API Token（本项目 Jira Bug Dashboard 就是这么做的）。

生成 Token：https://id.atlassian.com/manage-profile/security/api-tokens

然后在 `.zshrc` 中：
```bash
export JIRA_API_TOKEN="ATATT3xFf..."
```

### Q: 如何查看 MCP 是否正常加载

在 Claude Code 中输入 `/mcp`，会显示当前已连接的 MCP server 列表及其状态。

### Q: 可以同时配多个 MCP server 吗

可以。`mcpServers` 里每个 key 就是一个 server，互不冲突。

---

## 文件位置速查

| 文件 | 路径 | 作用 |
|------|------|------|
| MCP 服务定义 | `~/.claude/mcp.json` | 定义有哪些 MCP server |
| 全局设置 | `~/.claude/settings.json` | 启用哪些 server、权限白名单 |
| 本地设置 | `~/.claude/settings.local.json` | 个人权限覆盖（不提交 git） |
