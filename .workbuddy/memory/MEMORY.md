# 项目长期约定（OortCodex-Desktop）

## 脚本编码与跨平台

- Windows 的 `.ps1` 脚本若含中文，必须保存为 **UTF-8 with BOM**：Windows PowerShell 5.1 对无 BOM 的
  UTF-8 会按 GBK 解析，导致中文乱码甚至语法报错（`&&`、`}` 解析失败）。
- `.bat/.cmd` 文件保持 **ASCII（英文）**，中文输出交给 `.ps1` 或 Node 脚本，避免 cmd 代码页乱码；
  若必须显示中文，文件内先执行 `chcp 65001`。
- 从 Node 调用 npm 时：Windows 上 `npm.cmd` 需要 `shell: true`，否则 EINVAL；
  更稳的兜底是直接执行 `process.execPath + <node目录>/node_modules/npm/bin/npm-cli.js`。
- 沙箱/受限终端中 `spawnSync` 可能一律 EBUSY（连 `node --version` 都起不来），
  此时无法端到端验证真实安装，只能验证到 subprocess 之前的逻辑。

## 一键安装脚本

- CLI 安装包地址规则：`{OORTCODEX_CLI_BASE_URL}oortcodex-cli-{版本}.tgz`，
  默认前缀 `https://myoumuamua.com/mystatic/aistudio/`，默认版本 `0.0.1`，要求 Node `24.14.0`。
- 入口：`scripts/install-cli.bat`（cmd）→ `scripts/install-cli.ps1`（PowerShell）/
  `scripts/install-cli.sh`（bash），共用核心 `scripts/install-cli.mjs`。
- `scripts/update-latest.ps1` 是独立的 latest.json 更新脚本，与安装脚本无依赖关系。
