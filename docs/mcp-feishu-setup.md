# 飞书 MCP 配置教程

> 让 Claude Code 直接搜索/读取飞书云文档、知识库、多维表格、发消息。

---

## 用途

配置后 Claude 可以：
- 搜索飞书云文档和知识库
- 读取文档正文内容
- 查询多维表格（Bitable）
- 列出群组、读取聊天消息
- 按邮箱查找飞书用户 ID
- 发送飞书消息

---

## 原理

飞书 MCP 是 **stdio 模式**：Claude Code 在本地 spawn 一个 Node.js 进程（`@larksuiteoapi/lark-mcp`），通过 stdin/stdout 通信。认证使用飞书企业自建应用的 App ID + App Secret。

```
Claude Code ──stdin/stdout──▶ npx @larksuiteoapi/lark-mcp ──HTTPS──▶ 飞书开放平台 API
```

---

## Step 1：创建飞书企业自建应用

1. 打开 [飞书开放平台](https://open.feishu.cn/app)
2. 登录你的企业飞书账号
3. 点击「创建企业自建应用」
4. 填写应用名称（如 "Claude MCP"）和描述
5. 创建后，进入应用详情页，记下：
   - **App ID**（格式：`cli_xxxxxxxxxx`）
   - **App Secret**（格式：一串字母数字）

---

## Step 2：配置应用权限

在飞书开放平台 → 你的应用 → **权限管理**，搜索并开通以下权限：

| 权限标识 | 说明 | 用途 |
|---------|------|------|
| `docx:document:readonly` | 查看、下载云文档 | 读取文档内容 |
| `wiki:wiki:readonly` | 获取知识库信息 | 搜索/读取知识库文档 |
| `im:message:readonly` | 读取消息 | 读取群聊记录 |
| `im:chat:readonly` | 获取群信息 | 列出群组列表 |
| `contact:user.id:readonly` | 通过邮箱获取用户 ID | 查找用户 |
| `bitable:bitable` | 多维表格读写 | 查询/写入表格数据 |

> 按需开通即可，不一定要全部开。最基础的是 `docx:document:readonly` + `wiki:wiki:readonly`。

---

## Step 3：发布应用版本

1. 在应用页面左侧点击「版本管理与发布」
2. 创建一个新版本
3. 提交审核，等企业管理员审批通过
4. 审批通过后权限才会生效

> ⚠️ 如果权限一直不生效，检查是否卡在管理员审批环节。

---

## Step 4：写入 mcp.json

```bash
# 如果文件不存在，先创建
touch ~/.claude/mcp.json
```

编辑 `~/.claude/mcp.json`：

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

将 `<YOUR_APP_ID>` 和 `<YOUR_APP_SECRET>` 替换为 Step 1 中拿到的值。

---

## Step 5：在 settings.json 中启用

编辑 `~/.claude/settings.json`，加入：

```json
{
  "enabledMcpjsonServers": [
    "feishu"
  ]
}
```

> 如果已有其他字段，只需加入 `enabledMcpjsonServers` 数组即可。

---

## Step 6：（可选）添加权限白名单

为了避免每次调用飞书工具都弹确认框，可以在 `~/.claude/settings.local.json` 添加常用工具到白名单：

```json
{
  "permissions": {
    "allow": [
      "mcp__feishu__docx_builtin_search",
      "mcp__feishu__docx_v1_document_rawContent",
      "mcp__feishu__wiki_v1_node_search",
      "mcp__feishu__wiki_v2_space_getNode",
      "mcp__feishu__im_v1_chat_list",
      "mcp__feishu__im_v1_message_list",
      "mcp__feishu__contact_v3_user_batchGetId",
      "mcp__feishu__bitable_v1_appTableRecord_search"
    ]
  }
}
```

---

## Step 7：验证

重启 Claude Code（关掉重新打开），输入：

```
搜索飞书文档 "周报"
```

或：

```
/mcp
```

查看 feishu server 状态是否显示 connected。

---

## 前提条件

- **Node.js ≥ 18**（`npx` 需要）
- **企业飞书账号**（个人版飞书不支持自建应用）
- **管理员审批通过**（否则权限不生效）

检查 Node 版本：
```bash
node --version   # 需要 v18+
```

---

## 常见问题

### Q: 报错 "npx: command not found"

安装 Node.js：
```bash
brew install node
```

### Q: 连上了但搜索不到文档

1. 确认应用权限已审批通过
2. 确认文档不是「仅自己可见」——应用需要有读取权限
3. 对于知识库文档，应用需要被添加为知识库成员，或文档所在空间对应用可见

### Q: 如何让应用能读取特定知识库

管理员需要在知识库设置中把你的应用添加为成员（知识库 → 设置 → 成员管理 → 添加机器人）。

### Q: Claude Code 每次启动很慢

首次使用 `npx -y @larksuiteoapi/lark-mcp` 会下载包，之后会缓存。如果持续慢，可以全局安装：
```bash
npm install -g @larksuiteoapi/lark-mcp
```
然后把 mcp.json 中的 `command` 改为 `lark-mcp`，`args` 改为 `["mcp", "-a", "...", "-s", "..."]`。

---

## 可用工具列表

配置成功后，Claude 会获得以下工具：

| 工具名 | 功能 |
|--------|------|
| `docx_builtin_search` | 搜索云文档（按关键词） |
| `docx_v1_document_rawContent` | 读取文档正文 |
| `wiki_v1_node_search` | 搜索知识库节点 |
| `wiki_v2_space_getNode` | 获取知识库节点详情 |
| `im_v1_chat_list` | 列出群聊 |
| `im_v1_message_list` | 读取消息列表 |
| `im_v1_message_create` | 发送消息 |
| `im_v1_chat_create` | 创建群聊 |
| `contact_v3_user_batchGetId` | 按邮箱查用户 ID |
| `bitable_v1_app_create` | 创建多维表格 |
| `bitable_v1_appTable_list` | 列出表格 |
| `bitable_v1_appTableRecord_search` | 查询表格记录 |
| `bitable_v1_appTableRecord_create` | 新增记录 |
| `bitable_v1_appTableRecord_update` | 更新记录 |
| `drive_v1_permissionMember_create` | 授权文档权限 |
| `docx_builtin_import` | 导入文档 |
