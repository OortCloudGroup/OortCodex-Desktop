<h1 align="center">OortCodex Desktop</h1>

<p align="center"><strong>面向所有人的编程智能体工作台</strong></p>
<p align="center"><em>把想法变成现实的能力，属于每一个人。</em></p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

![OortCodex Desktop](assets/aiagent_zh.jpg)

## 📖 项目概述

OortCodex Desktop 是一款面向所有人的编程智能体工作台。它把「说清需求」到「拿到能跑的东西」之间的全部环节——读代码、查资料、改文件、执行命令、跑测试、排错——交给一个可以持续协作的智能体。

你不需要先成为程序员。只要能把想法讲清楚，剩下的活由智能体陪你一起完成。

> **把想法变成现实的能力，属于每一个人。**

## ✨ 为什么叫「面向所有人」

- **自然语言即接口**：用中文或英文描述目标，智能体自己规划步骤、动手执行、回报结果。
- **三端同一个大脑**：桌面应用、浏览器工作台、终端界面共享同一套 Agent 运行时与账号体系，随时切换、上下文不断。
- **从想法一直到产物**：不只是生成代码片段，还会查阅文档、调用外部工具、运行验证，直接交付可用的东西。
- **专业用户也不将就**：多工作区、并行会话、插件市场、MCP、Hooks、远程开发，一样不少。

## 🧩 核心能力

### 🤖 编程智能体

- 理解整个工程，自主拆解并规划多步任务，而不是只回答一个问题。
- 读写文件、执行命令、运行测试、定位并修复问题。
- 会话可继续、可分支、可并行，长任务不丢上下文。

### 🖥 三端一体

| 入口         | 形态                                   | 适合谁                                             |
| ------------ | -------------------------------------- | -------------------------------------------------- |
| 桌面应用     | Electron 客户端，开箱即用              | 大多数用户；需要完整图形界面与本地文件能力         |
| 浏览器工作台 | Web 客户端，由本地后端托管             | 想在任何设备上打开浏览器就干活                     |
| 终端界面     | `oortcodex` 命令行（TUI）              | 习惯命令行的开发者，以及自动化、脚本化场景         |

三个入口共用同一套 Agent 运行时、同一份工作区和同一账号，无论从哪儿开始，接着往下做就行。

### 🔌 插件与扩展生态

插件是 OortCodex 的扩展单元，一个插件可以同时提供技能、自定义命令、MCP 服务与 Hooks：

- **官方市场**：内置插件 + 经校验的官方 CDN 插件，统一目录、一键安装更新。
- **个人来源**：git / GitHub / URL / 本地目录 / inline 插件，自己的工具自己接。
- **开箱即用**：Browser Use、Document Skills、Skill Creator、OortCodex Guide 默认启用。
- **按需启用**：iOS 模拟器、Android 模拟器、旧会话迁移等按需打开，不占资源。

### 🧠 MCP 与 Hooks

- **MCP**：支持 `stdio` / `http` / `sse` 三类服务，工具以 `mcp__<server>__<tool>` 形式接入模型。
- **Hooks**：在会话开始、提示提交、工具调用前后、权限审批、回合结束等关键节点注入你自己的规则——既可以补充上下文，也可以直接拦截危险操作。

### 🌐 远程与协同

- **远程工作区**：通过 SSH / WSL 连接远端项目，在本地界面里操作远程代码。
- **手机远控**：手机连接桌面已有的工作台，复用同一会话运行时，随时随地接着干。

### 💳 模型与账号

- 使用 OortCloud 账号统一登录，桌面端与命令行共享凭证。
- 模型可查看、可切换，用量、订阅与 Credits 一目了然。

### 🛡 安全与可控

- 工具执行前需授权，危险操作可被规则拦截。
- 日志分级：高频诊断信息在生产环境不落盘。
- 凭证与真实用户数据不写入日志、示例或提交。

## 🚀 快速开始

### 下载安装

前往 [Releases](https://gitcode.com/OortCloudGroup/OortCodex-Desktop/releases) 下载对应平台的安装包：

- **Windows**：`.exe` 安装程序
- **macOS**：`.dmg` 磁盘映像
- **Linux**：对应发行包

### 自动更新

客户端读取仓库根目录的 [latest.json](latest.json) 获取最新版本号、下载地址与 SHA-256 校验值，完成版本检测与自动更新。

### 首次使用

1. 启动 OortCodex Desktop。
2. 使用 OortCloud 账号登录（桌面端与命令行共享同一份凭证）。
3. 打开或新建一个工作区：本地目录，或通过 SSH / WSL 连接远程项目。
4. 用自然语言描述你要做的事，智能体开始工作。

## ⌨️ 命令行

命令行发行包统一使用 `oortcodex` 启动：不带参数进入终端交互界面，`--web` 启动浏览器工作台。

```bash
oortcodex                  # 进入终端交互界面
oortcodex --web            # 启动浏览器工作台
oortcodex login oortcloud  # 登录 OortCloud 账号
```

## 📦 一键安装命令行（CLI）

仓库提供了一套跨平台安装脚本，覆盖 bash、PowerShell、cmd 三类终端：安装前先校验 Node.js 版本（要求 **24.14.0**），
校验通过后执行 `npm install -g` 安装 `oortcodex-cli` 安装包，**默认版本 0.0.1，可用变量或参数指定**。

| 终端                | 一键安装命令                  |
| ------------------- | ----------------------------- |
| bash / zsh / Git Bash | `./scripts/install-cli.sh`  |
| PowerShell          | `.\scripts\install-cli.ps1`   |
| cmd                 | `scripts\install-cli.bat`     |

指定版本安装：

```bash
# bash / zsh / Git Bash
./scripts/install-cli.sh --version 0.0.2
OORTCODEX_CLI_VERSION=0.0.2 ./scripts/install-cli.sh   # 环境变量方式
```

```powershell
# PowerShell
.\scripts\install-cli.ps1 -Version 0.0.2
.\scripts\install-cli.ps1 -Version 0.0.2 -AutoInstallNode   # 未装 Node 时自动用 winget 安装
```

可用变量（命令行同名参数可覆盖）：

| 变量                      | 说明                                    | 默认值                                          |
| ------------------------- | --------------------------------------- | ----------------------------------------------- |
| `OORTCODEX_CLI_VERSION`   | 安装包版本号                            | `0.0.1`                                         |
| `OORTCODEX_CLI_BASE_URL`  | 安装包下载地址前缀                      | `https://myoumuamua.com/mystatic/aistudio/`     |
| `OORTCODEX_CLI_PKG`       | 包名                                    | `oortcodex-cli`                                 |
| `OORTCODEX_NODE_VERSION`  | 要求的 Node.js 版本                     | `24.14.0`                                       |
| `OORTCODEX_NODE_MODE`     | 版本匹配模式：`exact` 精确 / `gte` 不低于 | `exact`                                       |

其他常用参数：`--dry-run`（只打印命令不安装）、`--allow-newer-node`（允许 Node 高于要求版本）、
`--skip-url-check`（跳过下载地址探测）。

脚本构成：`scripts/install-cli.mjs` 实现核心逻辑（版本校验、地址拼装、安装、结果校验），
`install-cli.sh` / `install-cli.ps1` / `install-cli.bat` 是各终端的入口。

## 🛠 技术栈

Electron · React 19 · TypeScript · Node.js 24 · pnpm monorepo，跨 Windows / macOS / Linux。
插件、MCP、Hooks、多工作台会话与远程链路都在同一套协议下实现。

## 🤝 参与贡献

欢迎各种形式的贡献：

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/AmazingFeature`）
3. 提交修改（`git commit -m 'feat: 新增某某功能'`）
4. 推送到远程分支（`git push origin feature/AmazingFeature`）
5. 创建 Pull Request

## 🐛 问题报告与反馈

遇到问题或有改进建议，请通过 GitHub / GitCode Issues 提交。

### 快速脚本更新 latest.json

在 PowerShell 中执行以下命令：

```powershell
# 使用指定版本更新 latest.json；默认 EXE 路径：G:\lanjian\nginx\html_88_56\OortCodex-Desktop.exe
.\scripts\update-latest.ps1 -Version "1.0.1"

# 使用自定义可执行文件路径
.\scripts\update-latest.ps1 -Version "1.0.2" -ExePath "G:\lanjian\nginx\html_88_56\OortCodex-Desktop.exe"
```

## 📄 许可证

本项目采用 MIT 许可证，完整内容请参阅 [LICENSE](LICENSE) 文件。

## 🙏 致谢

感谢所有为 OortCodex Desktop 做出贡献的开发者。

### 标语

**OortCodex Desktop —— 把想法变成现实的能力，属于每一个人。**
