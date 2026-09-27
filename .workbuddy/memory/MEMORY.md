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
- 脚本托管主源：`https://myoumuamua.com/mystatic/aistudio/scripts/`（用户手动上传四个脚本文件：
  `install-cli.sh` / `.ps1` / `.bat` / `.mjs`，其中 `.mjs` 是自举必需）；GitCode raw 仅作备份源。
- 入口：`scripts/install-cli.bat`（cmd）→ `scripts/install-cli.ps1`（PowerShell）/
  `scripts/install-cli.sh`（bash），共用核心 `scripts/install-cli.mjs`。
- 远程自举：`install-cli.sh` / `.ps1` 在本地找不到 `install-cli.mjs` 时（如 `curl | bash`、`irm | iex`），
  会按 `OORTCODEX_SCRIPTS_BASE_URL` → 自有静态站 → GitCode raw → GitHub raw → jsDelivr 的顺序下载核心脚本，
  并校验内容是否 HTML（跳过伪装成 200 的登录页）。
- **GitCode raw 正确格式**：`https://raw.gitcode.com/<组织>/<仓库>/raw/<分支>/<路径>`
  —— 域名后**还有一层 `/raw/`**，写成 `raw.gitcode.com/<仓库>/main/...` 会拿到 HTML 页面。
- 该接口**强制要求浏览器 UA**：实测 `curl/8.x` 默认 UA → `403 暂不支持预览`，
  换成 `Mozilla/5.0 ...` 立刻 200。因此 curl 必须带 `-A "Mozilla/5.0"`、
  `Invoke-WebRequest` 必须带 `-UserAgent 'Mozilla/5.0'`（PS 5.1 的 IWR 支持该参数）。
- 同时存在**偶发限流**（同一 UA 也可能 403，隔几秒重试即成功），脚本每个源重试 2 次，
  并校验下载内容排除 HTML / 「暂不支持预览」的伪装响应。
- 不可用：`gitcode.com/<repo>/raw/<branch>/...`（返回 HTML 登录页）、`/-/raw/`、`archive/main.zip`、
  jsDelivr（GitHub 侧无此仓库，404）；GitHub raw 本机网络不通（000）。
- `scripts/update-latest.ps1` 是独立的 latest.json 更新脚本，与安装脚本无依赖关系。
