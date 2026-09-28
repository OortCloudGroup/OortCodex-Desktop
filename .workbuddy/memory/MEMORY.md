# 项目长期约定（OortCodex-Desktop）

## 脚本编码与跨平台

- 需要**远程管道执行**（`irm <url> | iex`）的 `.ps1`：必须 **纯 ASCII 且不带 BOM**，
  中文提示交给 Node 核心脚本输出。两个方向都会炸，实测：
  - 带 BOM：`irm` 拿到的是 3 个可见字符（`ï»¿`）→ `param()` 不再是首条语句
    → 「赋值表达式无效」（即使按 UTF-8 正确解码为 U+FEFF，同样报错）。
  - 无 BOM 但含中文：`powershell -File` 按 GBK 读取，多字节序列吞掉换行 → 注释吃掉后续代码
    → 「表达式或语句中包含意外的标记 }」。
- 仅在本地以文件方式运行的 `.ps1`（如 `update-latest.ps1`）才适用「中文 + UTF-8 with BOM」。
- **更稳的做法：远程管道执行的 `.ps1` 干脆不要 `param()` 块**，改为手工解析 `$args`。
  因为 BOM 的 3 个可见字符会让 `param()` 失去首条语句位置从而**整个脚本解析失败**；
  去掉 `param()` 后它们只是一条未知命令，报一行错后继续执行 —— 上传时即使误带 BOM 也能装成功。
- PowerShell 退出码两个坑：① 函数内设 `$ErrorActionPreference='Stop'` 时，原生命令写 stderr 会抛终止错误，
  导致拿不到 `$LASTEXITCODE`；② `& node ...` 的 stdout 会混入函数返回值使退出码变成数组（`exit` 得 0），
  需写成 `& node ... | Out-Host`；不要 `2>&1`（会把 stderr 变成 ErrorRecord，控制台多出 CategoryInfo 噪音）。
- `irm | iex` 场景**不能无条件 `exit`**（会关掉用户终端），用 `if ($PSCommandPath) { exit $code }` 守卫。
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
- **npm 全局安装 EACCES（macOS/Linux 常见）**：曾以 sudo 跑过 npm → `~/.npm/_cacache` 留下 root 属主文件。
  判定要同时看「可写」与「属主」（`statSync().uid !== process.getuid()`），只查 `accessSync(W_OK)` 会漏判。
  脚本已实现自动改用 `~/.npm-oortcodex-cache`（免 sudo），并支持 `--cache` / `OORTCODEX_NPM_CACHE`。
- **sh 脚本要兼容 zsh**：zsh 无 `BASH_SOURCE`，`set -u` 下会报「未绑定的变量」，需 `${BASH_SOURCE:-}` 判空后回退 `$0`；
  且不要写 `[ -n ... ] && x=1` 这种短路赋值（`set -e` 下可能提前退出），改用 if 语句。
- **改完脚本必须确认静态站已同步**：用户手动上传，经常滞后。排查「远程一键报错」第一步就是
  比对远程与本地文件的字节数（`curl -o` + `wc -c` + `cmp`），远程旧版会让人误判为脚本 bug。
- **凡是打印「安装某版本 X」的指引，版本号必须从变量取，不能写死默认值**——
  曾把 `printNodeGuide` 里的 winget/nvm 命令写死成 24.14.0，与提示语里的要求版本自相矛盾。
- **sh 的 Node 版本切换要考虑匹配模式**：gte（`--allow-newer-node`）下当前版本更高时
  绝不能 `nvm use/install` 到旧版本，否则把高版本降成低版本；比较版本直接借 `node -e` 做，
  避免 bash/zsh 的 `read -ra` / 数组语法差异。
- 沙箱限制：cmd.exe 在 Bash 与 PowerShell 工具中都被禁用（`.bat` 无法直接跑），
  验证方式是执行 bat 内部的等价命令；`iex` / `& $scriptblock` / `.Invoke()` 也会被拦截。
