# image-gen-fuck

`image-gen-fuck` 是一个 Codex skill 辅助包，用来解决一个很具体的问题：当 Codex 桌面端可以正常聊天，但当前会话没有暴露内置 `image_gen` 图像生成工具时，让 Codex 在需要绘图时改走 `$imagegen` skill 自带的 `image_gen.py` CLI，并且只在这次 CLI 调用里临时使用单独的绘图 API key 和 base URL。

默认 base URL：

```text
https://code.codingplay.top/v1
```

## 它解决什么

- 正常聊天继续使用 Codex 桌面端原本的模型 API。
- 只有需要生成或编辑图片，并且内置 `image_gen` 工具不可用时，才走 CLI fallback。
- CLI 调用时临时设置 `OPENAI_API_KEY` 和 `OPENAI_BASE_URL`。
- 命令结束后清理临时环境变量，不污染 Codex 桌面端的全局对话配置。
- 可通过 Codex++ 注入的右下角“绘图设置”按钮配置绘图 API key 和 base URL。

## 目录结构

```text
image-gen-fuck/
├─ README.md
├─ scripts/
│  └─ install.ps1
├─ codex-plus-plus/
│  └─ user_scripts/
│     └─ imagegen-cli-settings.js
└─ skills/
   └─ image-gen-fuck/
      ├─ SKILL.md
      └─ scripts/
         └─ configure_imagegen_cli.ps1
```

## 依赖

- Windows PowerShell
- Codex 桌面端
- Codex 自带或已安装的 `$imagegen` skill
- 可选：Codex++，用于在 Codex 桌面端 UI 里显示“绘图设置”按钮

这里的 CLI 不是 Codex CLI，而是 `$imagegen` skill 自带的 Python 脚本：

```text
%USERPROFILE%\.codex\skills\.system\imagegen\scripts\image_gen.py
```

## 安装

在本仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\install.ps1"
```

安装脚本会复制 skill 到：

```text
%USERPROFILE%\.codex\skills\image-gen-fuck
```

也会复制 Codex++ 用户脚本到：

```text
%APPDATA%\Codex++\user_scripts\imagegen-cli-settings.js
```

并尝试在 `%APPDATA%\Codex++\user_scripts.json` 里启用：

```json
{
  "user:imagegen-cli-settings.js": true
}
```

如果不想安装 Codex++ 用户脚本，只安装 skill：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\install.ps1" -SkipCodexPlus
```

## 配置绘图 API

安装后可以用两种方式配置。

### 方式一：Codex++ UI

重启 Codex++ 启动的 Codex 桌面端，右下角会出现“绘图设置”按钮。

面板里可以设置：

- 是否启用 CLI 绘图 API 设置
- 接口地址，也就是 base URL
- API Key 环境变量名，默认 `OPENAI_API_KEY`
- 绘图 API key

保存后会写入：

```text
%APPDATA%\Codex++\settings.json
```

相关字段：

```json
{
  "cliWrapperEnabled": true,
  "cliWrapperBaseUrl": "https://code.codingplay.top/v1",
  "cliWrapperApiKey": "<drawing api key>",
  "cliWrapperApiKeyEnv": "OPENAI_API_KEY"
}
```

### 方式二：PowerShell

运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\image-gen-fuck\scripts\configure_imagegen_cli.ps1"
```

脚本会提示输入绘图 API key，然后写入 Codex++ settings 和备用 key 文件：

```text
%USERPROFILE%\.codex\secrets\imagegen-openai-key.txt
```

查看当前配置状态，但不打印 key：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\image-gen-fuck\scripts\configure_imagegen_cli.ps1" -Show
```

禁用 CLI 绘图设置：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\image-gen-fuck\scripts\configure_imagegen_cli.ps1" -Disable
```

## Codex 使用流程

在 Codex 中，正常用法是同时提到两个 skill：

```text
使用 $imagegen 和 $image-gen-fuck 生成一张图片：……
```

Codex 的决策流程：

1. 先读取 `$imagegen`，使用它的提示词整理、透明背景、输出保存等规则。
2. 如果内置 `image_gen` 工具可用，优先用内置工具。
3. 如果内置 `image_gen` 工具不可用，并且用户同意 CLI fallback，则读取 `$image-gen-fuck`。
4. `$image-gen-fuck` 从 Codex++ settings 或备用 key 文件读取绘图配置。
5. 只在当前 PowerShell 进程里临时设置：

   ```powershell
   $env:OPENAI_API_KEY = "<drawing key>"
   $env:OPENAI_BASE_URL = "https://code.codingplay.top/v1"
   ```

6. 调用：

   ```text
   %USERPROFILE%\.codex\skills\.system\imagegen\scripts\image_gen.py
   ```

7. `finally` 中清理 `OPENAI_API_KEY` 和 `OPENAI_BASE_URL`。

## 安全说明

- 不要把 `%APPDATA%\Codex++\settings.json` 提交到 GitHub。
- 不要把 `%USERPROFILE%\.codex\secrets\imagegen-openai-key.txt` 提交到 GitHub。
- 本仓库只包含安装脚本、用户脚本和 skill，不包含真实 API key。
- 该方案不会修改 Codex 桌面端安装文件。
- 该方案不会修改 `$imagegen` 自带的 `image_gen.py`。

## 失败处理

如果 `https://code.codingplay.top/v1` 返回 `404`、`405`、HTML 页面或 nginx 错误，说明接口可能不是 OpenAI-compatible image API 地址。此时需要换成兼容这些路径的 base URL：

```text
/v1/images/generations
/v1/images/edits
```

如果鉴权失败，检查 Codex++ 面板里的 key，或者检查备用 key 文件是否存在。
