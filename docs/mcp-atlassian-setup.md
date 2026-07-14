# Atlassian MCP 配置教程

> 让 Claude Code 直接访问公司 Jira（查 ticket、看 board）和 Confluence（搜文档、读页面）。

---

## 用途

配置后 Claude 可以：
- 搜索和查看 Jira ticket
- 查看 Sprint/Board 信息
- 搜索和读取 Confluence 文档
- 查看项目配置和工作流

---

## 原理

Atlassian MCP 是 **HTTP 模式**：Atlassian 官方托管了一个 MCP 服务端，Claude Code 直接通过 HTTPS 连接。首次使用时通过 OAuth 在浏览器中授权。

```
Claude Code ──HTTPS──▶ mcp.atlassian.com ──内部──▶ Jira / Confluence API
```

不需要本地安装任何东西，也不需要自己创建应用。

---

## Step 1：确认前提

- 你有公司的 Atlassian 账号（能登录 `https://your-company.atlassian.net`）
- 你的浏览器已登录该账号（OAuth 授权时会用到）

---

## Step 2：写入 mcp.json

编辑 `~/.claude/mcp.json`：

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

> 如果已有飞书等其他 MCP server，加在 `mcpServers` 对象里即可，多个 server 并列。

完整示例（飞书 + Atlassian 并存）：

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "...", "-s", "..."]
    },
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp"
    }
  }
}
```

---

## Step 3：在 settings.json 中启用

编辑 `~/.claude/settings.json`，确保 `enabledMcpjsonServers` 包含 `"atlassian"`：

```json
{
  "enabledMcpjsonServers": [
    "atlassian"
  ]
}
```

---

## Step 4：首次 OAuth 授权

1. 重启 Claude Code
2. 输入任意触发 Atlassian MCP 的指令，比如 `查看 Jira APRICOT-12345`
3. Claude Code 会弹出一个 URL，在浏览器中打开
4. 用你的 Atlassian 账号登录并点击「Allow」
5. 授权完成后回到 Claude Code，工具即可使用

---

## Step 5：验证

```
/mcp
```

应该能看到 `atlassian` 状态为 connected。

---

## ⚠️ 已知问题：OAuth 不稳定

Atlassian HTTP MCP 的 OAuth 认证**偶尔会失效**（token 过期、授权跳转失败）。这是目前的已知限制。

### 备选方案：直接用 REST API + API Token

如果 OAuth 不好用，可以绕过 MCP，直接用 Jira REST API：

1. 生成 API Token：https://id.atlassian.com/manage-profile/security/api-tokens
2. 存到环境变量：
   ```bash
   # ~/.zshrc
   export JIRA_API_TOKEN="ATATT3xFf..."
   ```
3. 用 curl 直接调用：
   ```bash
   curl -s -u "your.email@company.com:$JIRA_API_TOKEN" \
     "https://your-company.atlassian.net/rest/api/3/issue/PROJ-123"
   ```

> 本项目的 Jira Bug Dashboard skill 就是用这种方式——更可靠，不依赖 MCP OAuth。

---

## 两种方式对比

| | Atlassian MCP (OAuth) | REST API + Token |
|---|---|---|
| 配置复杂度 | 低（3 行 JSON） | 中（需要生成 token、配环境变量） |
| 稳定性 | 偶尔 OAuth 失效 | 非常稳定 |
| 能力范围 | Jira + Confluence | 取决于你调什么 API |
| 适用场景 | 偶尔查查 ticket/文档 | 每天跑 dashboard、批量操作 |

**建议：** 两种都配。MCP 方便日常交互查询，REST API 保底做自动化。

---

## 常见问题

### Q: OAuth 授权后还是报错

尝试：
1. 清除浏览器 Atlassian 相关 cookie
2. 重新在浏览器登录 `your-company.atlassian.net`
3. 重启 Claude Code 重新授权

### Q: 只能看到部分项目

OAuth 的权限范围取决于你的 Atlassian 账号权限。你在 Jira 网页上能看到的项目，MCP 也能看到。

### Q: 可以写入（创建 ticket、发评论）吗

取决于 MCP 提供的工具和你的账号权限。目前 Atlassian MCP 以读取为主。如需写入操作，推荐用 REST API。

### Q: 公司有 SSO/SAML，能用吗

可以。OAuth 授权时会走公司的 SSO 流程，正常登录即可。

---

## 文件位置速查

| 文件 | 路径 | 作用 |
|------|------|------|
| MCP 服务定义 | `~/.claude/mcp.json` | 定义 server 连接方式 |
| 全局设置 | `~/.claude/settings.json` | 启用 server 列表 |
| Jira API Token | `~/.zshrc` 中的环境变量 | REST API 备选认证 |
