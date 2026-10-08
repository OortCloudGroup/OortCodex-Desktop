# CLI 一键安装说明

项目提供 bash、PowerShell 和 cmd 安装入口。安装器会检查 Node.js 版本，然后通过 npm 全局安装 `oortcodex-cli`。默认安装 npm 上的最新版本。

## 环境要求

- Node.js `24.14.0`。默认要求精确匹配；如需接受更高版本，可使用 `--allow-newer-node`。
- npm。通常随 Node.js 一起安装。
- 可访问配置的 npm registry。

## 在仓库中安装

在仓库根目录运行对应命令：

| 终端 | 命令 |
| --- | --- |
| bash / zsh / Git Bash | `./scripts/install-cli.sh` |
| PowerShell | `./scripts/install-cli.ps1` |
| cmd | `scripts\install-cli.bat` |

Windows 若尚未安装 Node.js，可在 PowerShell 中使用 `-AutoInstallNode`，由 winget 安装要求的版本：

```powershell
.\scripts\install-cli.ps1 -AutoInstallNode
```

macOS/Linux 若使用 nvm，可先运行 `nvm install 24.14.0 && nvm use 24.14.0`，再运行 bash 安装脚本。也可传入 `--auto-install-node` 由脚本尝试通过 nvm 安装。

## 远程一键安装

无需克隆仓库。远程入口会获取安装脚本；CLI 包本身由 npm 按包名安装。

### bash / zsh

```bash
curl -fsSL https://myoumuamua.com/mystatic/aistudio/scripts/install-cli.sh | bash
```

### PowerShell

```powershell
irm https://myoumuamua.com/mystatic/aistudio/scripts/install-cli.ps1 | iex
```

### cmd

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://myoumuamua.com/mystatic/aistudio/scripts/install-cli.ps1 | iex"
```

## 指定版本和常用选项

默认命令等价于：

```sh
npm install -g oortcodex-cli
```

指定版本：

```bash
./scripts/install-cli.sh --version 1.2.3
```

```powershell
.\scripts\install-cli.ps1 -Version 1.2.3
```

| 选项 | 说明 |
| --- | --- |
| `--version <版本>` / `-Version <版本>` | 安装指定的 npm 版本；默认 `latest` |
| `--node-version <版本>` | 覆盖要求的 Node.js 版本 |
| `--allow-newer-node` | 接受高于要求版本的 Node.js |
| `--auto-install-node` / `-AutoInstallNode` | 尝试使用 nvm（bash）或 winget（PowerShell）安装 Node.js |
| `--cache <目录>` / `-Cache <目录>` | 指定 npm 缓存目录 |
| `--dry-run` / `-DryRun` | 只显示将执行的 npm 命令，不安装 |

也可以通过环境变量设置版本和 Node.js 校验模式：

```bash
OORTCODEX_CLI_VERSION=1.2.3 OORTCODEX_NODE_MODE=gte ./scripts/install-cli.sh
```

| 环境变量 | 默认值 | 用途 |
| --- | --- | --- |
| `OORTCODEX_CLI_VERSION` | `latest` | npm 包版本 |
| `OORTCODEX_CLI_PKG` | `oortcodex-cli` | npm 包名 |
| `OORTCODEX_NODE_VERSION` | `24.14.0` | 要求的 Node.js 版本 |
| `OORTCODEX_NODE_MODE` | `exact` | `exact` 精确匹配，`gte` 允许更高版本 |
| `OORTCODEX_NPM_CACHE` | 自动选择 | 指定 npm 缓存目录 |

## 安装后验证

重新打开终端后运行：

```sh
oortcodex --version
```

如果提示找不到命令，请将 npm 全局可执行文件目录加入 `PATH`，然后重新打开终端。可运行 `npm prefix -g` 查看 npm 全局安装前缀。

## 常见问题

### Node.js 版本不匹配

默认要求 Node.js `24.14.0`。安装对应版本后重试；若已安装更高版本且确认兼容，可添加 `--allow-newer-node`。

### npm 全局安装权限错误

Windows 可使用管理员终端重试。macOS/Linux 可配置用户级 npm prefix，避免使用 sudo 安装全局包：

```sh
npm config set prefix "$HOME/.npm-global"
```

再将 `$HOME/.npm-global/bin` 加入 `PATH`，重新打开终端后重试。

### 安装成功但找不到 `oortcodex` 命令

确认 npm 全局可执行目录已加入 `PATH`，然后新开终端。npm 全局目录可通过 `npm prefix -g` 查看。
