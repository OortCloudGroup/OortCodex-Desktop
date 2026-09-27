<h1 align="center">OortCodex Desktop</h1>

<p align="center"><strong>A coding agent workbench for everyone</strong></p>
<p align="center"><em>The power to turn ideas into reality belongs to everyone.</em></p>

<p align="center">
  English | <a href="README.zh-CN.md">简体中文</a>
</p>

![OortCodex Desktop](assets/aiagent.jpg)

## 📖 Overview

OortCodex Desktop is a coding agent workbench built for everyone. It hands the entire path from "describing what you want" to "having something that actually runs" — reading code, researching, editing files, running commands, executing tests, debugging — to an agent that works alongside you.

You do not have to become a programmer first. If you can explain the idea clearly, the agent helps you build it.

> **The power to turn ideas into reality belongs to everyone.**

## ✨ Why "for everyone"

- **Natural language is the interface.** Describe your goal in plain words; the agent plans the steps, does the work, and reports back.
- **One brain, three interfaces.** The desktop app, the browser workbench, and the terminal share the same Agent runtime, the same workspace, and the same account — switch anytime without losing context.
- **From an idea to a real deliverable.** It doesn't just produce code snippets — it reads docs, calls external tools, runs verification, and hands you something usable.
- **Professionals are not shortchanged.** Multiple workspaces, parallel sessions, a plugin marketplace, MCP, hooks, and remote development are all there.

## 🧩 Core Capabilities

### 🤖 The coding agent

- Understands the whole project, breaks work into steps, and plans multi-step tasks instead of answering a single question.
- Reads and writes files, runs commands, executes tests, locates and fixes problems.
- Sessions can be resumed, forked, and run in parallel, so long tasks keep their context.

### 🖥 One brain, three interfaces

| Interface      | Form                                            | Best for                                                        |
| -------------- | ----------------------------------------------- | --------------------------------------------------------------- |
| Desktop app    | Electron client, ready out of the box           | Most users; those who want a full GUI and local file access     |
| Browser workbench | Web client hosted by a local backend          | Working from any device, right in the browser                   |
| Terminal UI    | The `oortcodex` command line (TUI)              | Developers who live in the shell, plus automation and scripting |

All three share the same Agent runtime, the same workspace, and the same account — start anywhere and just keep going.

### 🔌 Plugins and extensibility

A plugin is the unit of extension in OortCodex, and one plugin can ship skills, custom commands, MCP servers, and hooks at once:

- **Official marketplace**: built-in plugins plus SHA-256 verified CDN plugins, in one catalog with one-click install and update.
- **Personal sources**: git / GitHub / URL / local directory / inline plugins — bring your own tooling.
- **Ready to use**: Browser Use, Document Skills, Skill Creator, and OortCodex Guide are enabled by default.
- **Enable on demand**: iOS Simulator, Android Emulator, legacy session migration, and more stay off until you need them.

### 🧠 MCP and hooks

- **MCP**: supports `stdio`, `http`, and `sse` servers; tools are exposed to the model as `mcp__<server>__<tool>`.
- **Hooks**: inject your own rules at key moments — session start, prompt submission, before and after tool use, permission requests, and turn completion. Hooks can add context or block a dangerous action outright.

### 🌐 Remote and collaboration

- **Remote workspaces**: connect to projects over SSH / WSL and work on remote code from the local interface.
- **Mobile remote control**: your phone connects to the workbench already running on your desktop and reuses the same session runtime — pick up where you left off.

### 💳 Models and accounts

- Sign in with a single OortCloud account, shared between the desktop app and the command line.
- Browse and switch models; usage, subscription, and credits are all in one place.

### 🛡 Security and control

- Tool calls require authorization, and dangerous actions can be blocked by rules.
- Tiered logging: high-frequency diagnostics are never written to disk in production.
- Credentials and real user data never appear in logs, examples, or commits.

## 🚀 Quick Start

### Download

Get the installer for your platform from [Releases](https://gitcode.com/OortCloudGroup/OortCodex-Desktop/releases):

- **Windows**: `.exe` installer
- **macOS**: `.dmg` disk image
- **Linux**: platform package

### Auto-update

The client reads [latest.json](latest.json) at the repository root to obtain the latest version, download URL, and SHA-256 checksum, then handles version detection and updates automatically.

### First run

1. Launch OortCodex Desktop.
2. Sign in with your OortCloud account (shared with the command line).
3. Open or create a workspace: a local directory, or a remote project over SSH / WSL.
4. Describe what you want in natural language and let the agent get to work.

## ⌨️ Command line

The command-line distribution starts with one `oortcodex` command: no arguments opens the terminal UI, and `--web` starts the browser workbench.

```bash
oortcodex                  # Start the terminal UI
oortcodex --web            # Start the browser workbench
oortcodex login oortcloud  # Sign in to OortCloud
```

## 🛠 Tech stack

Electron · React 19 · TypeScript · Node.js 24 · pnpm monorepo, across Windows / macOS / Linux.
Plugins, MCP, hooks, multi-workspace sessions, and remote connections are all built on one shared protocol.

## 🤝 Contributing

All forms of contribution are welcome:

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: add some feature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🐛 Bug Reports & Feedback

If you run into an issue or have an improvement in mind, please open an issue on GitHub / GitCode.

### Quick script to update latest.json

Run the following in PowerShell:

```powershell
# Update latest.json with the given version; default EXE path: G:\lanjian\nginx\html_88_56\OortCodex-Desktop.exe
.\scripts\update-latest.ps1 -Version "1.0.1"

# Use a custom executable path
.\scripts\update-latest.ps1 -Version "1.0.2" -ExePath "G:\lanjian\nginx\html_88_56\OortCodex-Desktop.exe"
```

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

Thanks to every developer who has contributed to OortCodex Desktop.

### Tagline

**OortCodex Desktop — the power to turn ideas into reality belongs to everyone.**
