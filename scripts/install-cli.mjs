#!/usr/bin/env node
/**
 * oortcodex-cli 一键安装脚本（Node 核心层，跨平台共用）
 *
 * 职责：校验 Node 版本 → 拼装 tgz 下载地址 → 执行 npm install -g → 校验安装结果
 * 入口：install-cli.sh（bash/zsh）、install-cli.ps1（PowerShell）、install-cli.bat（cmd）
 *
 * 可用变量控制：
 *   OORTCODEX_CLI_VERSION      安装包版本，默认 0.0.1
 *   OORTCODEX_CLI_BASE_URL     下载地址前缀，默认 https://myoumuamua.com/mystatic/aistudio/
 *   OORTCODEX_CLI_PKG          包名，默认 oortcodex-cli
 *   OORTCODEX_NODE_VERSION     Node 要求版本，默认 24.14.0
 *   OORTCODEX_NODE_MODE        版本匹配模式：exact（精确等于）/ gte（大于等于），默认 exact
 */

import { spawnSync } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';
import { accessSync, constants, mkdirSync, rmdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/** 默认配置：环境变量优先，未设置时取此默认值 */
const DEFAULTS = {
  version: '0.0.1',
  baseUrl: 'https://myoumuamua.com/mystatic/aistudio/',
  pkgName: 'oortcodex-cli',
  nodeVersion: '24.14.0',
  nodeMode: 'exact',
  cacheDir: '',
};

const LOG_PREFIX = '[oortcodex]';

/** 打印日志 */
function log(message) {
  console.log(`${LOG_PREFIX} ${message}`);
}

/** 打印错误日志 */
function logError(message) {
  console.error(`${LOG_PREFIX} 错误：${message}`);
}

/** 读取环境变量默认值 */
function readEnvDefaults() {
  const envMap = {
    version: 'OORTCODEX_CLI_VERSION',
    baseUrl: 'OORTCODEX_CLI_BASE_URL',
    pkgName: 'OORTCODEX_CLI_PKG',
    nodeVersion: 'OORTCODEX_NODE_VERSION',
    nodeMode: 'OORTCODEX_NODE_MODE',
    cacheDir: 'OORTCODEX_NPM_CACHE',
  };
  const options = { ...DEFAULTS };
  for (const [key, envName] of Object.entries(envMap)) {
    const value = process.env[envName];
    if (value && value.trim() !== '') {
      options[key] = value.trim();
    }
  }
  return options;
}

/** 打印帮助信息 */
function printHelp() {
  console.log(`${LOG_PREFIX} 用法：install-cli [选项]
  --version <值>        安装包版本，默认 ${DEFAULTS.version}（环境变量 OORTCODEX_CLI_VERSION）
  --base-url <地址>     下载地址前缀，默认 ${DEFAULTS.baseUrl}
  --pkg <包名>          包名，默认 ${DEFAULTS.pkgName}
  --node-version <版本> Node 要求版本，默认 ${DEFAULTS.nodeVersion}
  --node-mode <模式>    exact 精确匹配 / gte 大于等于，默认 ${DEFAULTS.nodeMode}
  --cache <目录>        指定 npm 缓存目录（默认缓存不可写时会自动改用 ~/.npm-oortcodex-cache）
  --allow-newer-node    等价于 --node-mode gte
  --skip-url-check      跳过下载地址可访问性探测
  --dry-run             只打印待执行命令，不真实安装
  -h, --help            显示本帮助`);
}

/** 解析命令行参数 */
function parseArgs(argv) {
  const options = readEnvDefaults();
  const flagMap = {
    '--version': 'version',
    '--base-url': 'baseUrl',
    '--pkg': 'pkgName',
    '--node-version': 'nodeVersion',
    '--node-mode': 'nodeMode',
    '--cache': 'cacheDir',
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '-h' || arg === '--help') {
      options.help = true;
      continue;
    }
    if (arg === '--dry-run') {
      options.dryRun = true;
      continue;
    }
    if (arg === '--allow-newer-node') {
      options.nodeMode = 'gte';
      continue;
    }
    if (arg === '--skip-url-check') {
      options.skipUrlCheck = true;
      continue;
    }

    let key = arg;
    let value = null;
    const eqIndex = arg.indexOf('=');
    if (arg.startsWith('--') && eqIndex > 0) {
      key = arg.slice(0, eqIndex);
      value = arg.slice(eqIndex + 1);
    }

    const optionName = flagMap[key];
    if (!optionName) {
      logError(`无法识别的参数：${arg}（使用 --help 查看用法）`);
      process.exit(1);
    }
    if (value === null) {
      value = argv[index + 1];
      index += 1;
    }
    if (value === undefined || value === '') {
      logError(`参数 ${key} 缺少取值`);
      process.exit(1);
    }
    options[optionName] = value;
  }

  if (options.nodeMode !== 'exact' && options.nodeMode !== 'gte') {
    logError(`--node-mode 只支持 exact 或 gte，当前为 ${options.nodeMode}`);
    process.exit(1);
  }
  return options;
}

/** 比较版本号：a > b 返回 1，a < b 返回 -1，相等返回 0 */
function compareVersion(versionA, versionB) {
  const partsA = versionA.split('.').map((item) => Number.parseInt(item, 10) || 0);
  const partsB = versionB.split('.').map((item) => Number.parseInt(item, 10) || 0);
  const length = Math.max(partsA.length, partsB.length);
  for (let index = 0; index < length; index += 1) {
    const diff = (partsA[index] ?? 0) - (partsB[index] ?? 0);
    if (diff !== 0) {
      return diff > 0 ? 1 : -1;
    }
  }
  return 0;
}

/** 输出各平台安装指定版本 Node 的指引（版本号必须取自 requiredVersion，不能写死） */
function printNodeGuide(requiredVersion) {
  const platform = process.platform;
  console.log(`${LOG_PREFIX} 请先安装 Node.js ${requiredVersion}：`);
  if (platform === 'win32') {
    console.log(`  winget install OpenJS.NodeJS --version ${requiredVersion} --exact`);
    console.log(`  nvm-windows: nvm install ${requiredVersion} && nvm use ${requiredVersion}`);
    console.log(`  或手动下载：https://nodejs.org/dist/v${requiredVersion}/node-v${requiredVersion}-x64.msi`);
  } else if (platform === 'darwin') {
    console.log(`  nvm install ${requiredVersion} && nvm use ${requiredVersion}`);
    console.log(`  或手动下载：https://nodejs.org/dist/v${requiredVersion}/node-v${requiredVersion}.pkg`);
  } else {
    console.log(`  nvm install ${requiredVersion} && nvm use ${requiredVersion}`);
    console.log(`  或手动下载：https://nodejs.org/dist/v${requiredVersion}/`);
  }
  console.log(`${LOG_PREFIX} 安装完成后重新执行本脚本即可。`);
}

/** 校验当前 Node 版本是否满足要求 */
function checkNodeVersion(requiredVersion, mode) {
  const currentVersion = process.versions.node;
  const diff = compareVersion(currentVersion, requiredVersion);
  const lower = diff < 0;
  const higher = diff > 0;
  const passed = mode === 'gte' ? diff >= 0 : diff === 0;

  if (passed) {
    log(`Node 版本校验通过：v${currentVersion}（要求 ${mode === 'gte' ? '>=' : '='} ${requiredVersion}）`);
    return true;
  }

  logError(`Node 版本不匹配：当前 v${currentVersion}，要求 ${requiredVersion}`);
  if (lower) {
    console.log('  当前版本过低。');
  } else if (higher) {
    console.log('  当前版本高于要求版本，如需放宽限制请加 --allow-newer-node 或设置 OORTCODEX_NODE_MODE=gte。');
  }
  printNodeGuide(requiredVersion);
  return false;
}

/** 在当前 Node 安装目录中查找 npm-cli.js，作为 npm 命令不可用时的回退方案 */
function findNpmCli() {
  const nodeDir = path.dirname(process.execPath);
  const candidates = [
    path.join(nodeDir, 'node_modules', 'npm', 'bin', 'npm-cli.js'),
    path.join(nodeDir, '..', 'lib', 'node_modules', 'npm', 'bin', 'npm-cli.js'),
  ];
  return candidates.find((item) => {
    try {
      return require('node:fs').statSync(item).isFile();
    } catch {
      return false;
    }
  }) || null;
}

/** 探测可用的 npm 执行方式，返回 { command, baseArgs, label } */
function resolveNpm() {
  const npmCommand = process.platform === 'win32' ? 'npm.cmd' : 'npm';
  const npmCli = findNpmCli();
  const attempts = [
    { command: npmCommand, baseArgs: [], label: npmCommand, shell: false },
    // Windows 上 .cmd 需要借助 shell 才能启动
    { command: npmCommand, baseArgs: [], label: `${npmCommand}（shell）`, shell: true },
    // 兜底：直接用当前 Node 执行 npm-cli.js，与 npm 本体等价且不依赖 PATH
    { command: process.execPath, baseArgs: [npmCli], label: 'node + npm-cli.js', shell: false },
  ].filter((item) => item.baseArgs.every((arg) => typeof arg === 'string'));

  for (const attempt of attempts) {
    const probe = spawnSync(attempt.command, [...attempt.baseArgs, '--version'], {
      encoding: 'utf8',
      shell: attempt.shell,
    });
    if (!probe.error && probe.status === 0) {
      log(`npm 版本：${probe.stdout.trim()}（执行方式：${attempt.label}）`);
      return attempt;
    }
  }

  logError(`未检测到可用的 npm（期望命令：${npmCommand}）`);
  if (npmCli) {
    log(`已发现 npm 本体：${npmCli}，但无法启动子进程，请检查终端权限或安全策略后重试。`);
  } else {
    log('请确认 Node.js 已正确安装并加入 PATH。');
  }
  return null;
}

/** 目录是否存在且为目录 */
function dirExists(dir) {
  try {
    return statSync(dir).isDirectory();
  } catch {
    return false;
  }
}

/** 判断目录是否可写：权限位 + 实际创建探测目录（父目录可写不代表能写进去） */
function isDirWritable(dir) {
  if (!dir || !dirExists(dir)) {
    return false;
  }
  try {
    accessSync(dir, constants.W_OK);
    const probe = path.join(dir, `.oortcodex-probe-${process.pid}`);
    mkdirSync(probe);
    rmdirSync(probe);
    return true;
  } catch {
    return false;
  }
}

/** 判断目录属主是否为当前用户（root 属主会在普通用户下触发 EACCES；Windows 无 uid 概念） */
function isOwnedByUser(dir) {
  if (typeof process.getuid !== 'function' || process.getuid() === 0) {
    return true;
  }
  try {
    return statSync(dir).uid === process.getuid();
  } catch {
    return true;
  }
}

/** npm 缓存是否可用：缓存根目录及其 _cacache、_cacache/index-v5 都要既可写又属于当前用户 */
function isCacheUsable(cacheDir) {
  const targets = [
    cacheDir,
    path.join(cacheDir, '_cacache'),
    path.join(cacheDir, '_cacache', 'index-v5'),
  ].filter((item) => dirExists(item));
  return targets.every((item) => isDirWritable(item) && isOwnedByUser(item));
}

/** 读取 npm 的某个配置项（如 cache、prefix） */
function readNpmConfig(npm, key) {
  const result = spawnSync(npm.command, [...npm.baseArgs, 'config', 'get', key], {
    encoding: 'utf8',
    shell: Boolean(npm.shell),
  });
  return result.status === 0 ? result.stdout.trim() : '';
}

/**
 * 确定 npm 缓存目录。
 * 常见问题：曾用 sudo 执行过 npm，缓存目录（~/.npm/_cacache）里留下 root 属主的文件，
 * 之后普通用户执行 npm 就会 EACCES。此时自动改用独立缓存目录，无需 sudo 即可继续。
 */
function resolveCacheDir(npm, customCache) {
  if (customCache) {
    return { cacheDir: customCache, fallback: false };
  }
  const defaultCache = readNpmConfig(npm, 'cache');
  if (!defaultCache) {
    return { cacheDir: '', fallback: false };
  }
  if (isCacheUsable(defaultCache)) {
    return { cacheDir: '', fallback: false };
  }
  const fallbackDir = path.join(os.homedir(), '.npm-oortcodex-cache');
  return { cacheDir: fallbackDir, fallback: true, origin: defaultCache };
}

/** 拼装 tgz 下载地址 */
function buildTarballUrl(baseUrl, pkgName, version) {
  const normalizedBase = baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`;
  return `${normalizedBase}${pkgName}-${version}.tgz`;
}

/** 探测下载地址是否可访问 */
async function checkUrlReachable(url) {
  try {
    const response = await fetch(url, { method: 'HEAD', redirect: 'follow' });
    return response.ok;
  } catch {
    return false;
  }
}

/** 校验安装结果：尝试执行全局命令 */
function verifyInstall(pkgName) {
  const candidates = process.platform === 'win32'
    ? [`${pkgName}.cmd`, 'oortcodex.cmd']
    : [pkgName, 'oortcodex'];

  for (const command of candidates) {
    const result = spawnSync(command, ['--version'], {
      encoding: 'utf8',
      shell: process.platform === 'win32',
    });
    if (!result.error && result.status === 0) {
      log(`安装校验成功：${command} ${result.stdout.trim()}`);
      return true;
    }
  }

  const prefix = spawnSync(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['prefix', '-g'], {
    encoding: 'utf8',
    shell: process.platform === 'win32',
  });
  const globalPath = prefix.status === 0 ? prefix.stdout.trim() : '(未知)';
  log(`包已安装，但命令未出现在当前 PATH 中。npm 全局目录：${globalPath}`);
  log('请新开一个终端，或将该目录加入 PATH 后再试。');
  return false;
}

/** 输出权限问题的修复指引（区分 Windows 与 macOS/Linux） */
function logPermissionFix(prefixDir, cacheOrigin) {
  if (process.platform === 'win32') {
    log('  请以管理员身份打开终端后重试（EACCES / EPERM）。');
    return;
  }
  if (cacheOrigin) {
    log(`  sudo chown -R "$(id -u):$(id -g)" "${cacheOrigin}"`);
  }
  if (prefixDir) {
    log(`  sudo chown -R "$(id -u):$(id -g)" "${prefixDir}"`);
  }
  log('  或改用用户级全局目录：npm config set prefix ~/.npm-global（并把 ~/.npm-global/bin 加入 PATH）');
}

/** 主流程 */
async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return 0;
  }

  // 版本号格式校验，避免非法输入拼进下载地址与命令
  const versionPattern = /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/;
  if (!versionPattern.test(options.version)) {
    logError(`安装包版本号格式不合法：${options.version}（示例：0.0.1）`);
    return 1;
  }
  if (!/^\d+(?:\.\d+){0,2}$/.test(options.nodeVersion)) {
    logError(`Node 版本号格式不合法：${options.nodeVersion}（示例：24.14.0）`);
    return 1;
  }

  log(`目标包：${options.pkgName}，版本：${options.version}`);

  if (!checkNodeVersion(options.nodeVersion, options.nodeMode)) {
    return 1;
  }

  const npm = resolveNpm();
  if (!npm) {
    return 1;
  }

  // 缓存目录：默认缓存不可写（常见于曾用 sudo 跑过 npm）时自动改用独立缓存
  const cache = resolveCacheDir(npm, options.cacheDir);
  if (cache.fallback) {
    log(`默认 npm 缓存不可写：${cache.origin}`);
    log(`自动改用独立缓存目录：${cache.cacheDir}（也可用 --cache 指定）`);
  }

  // 全局目录不可写时提前给出修复指引，避免装到一半才报 EACCES
  const globalPrefix = readNpmConfig(npm, 'prefix');
  const globalModules = globalPrefix ? path.join(globalPrefix, 'lib', 'node_modules') : '';
  const prefixWritable = isDirWritable(globalModules) || isDirWritable(globalPrefix);

  const tarballUrl = buildTarballUrl(options.baseUrl, options.pkgName, options.version);
  const npmArgs = [...npm.baseArgs, 'install', '-g', tarballUrl, '--no-fund', '--no-audit'];
  if (cache.cacheDir) {
    npmArgs.push('--cache', cache.cacheDir);
  }
  const displayCommand = `${npm.command} ${npmArgs.join(' ')}`;

  if (options.dryRun) {
    log(`[dry-run] 将执行：${displayCommand}`);
    return 0;
  }

  if (!options.skipUrlCheck) {
    log(`探测下载地址：${tarballUrl}`);
    const reachable = await checkUrlReachable(tarballUrl);
    if (!reachable) {
      logError(`下载地址不可访问或资源不存在：${tarballUrl}`);
      log('请确认版本号与网络后重试，或加 --skip-url-check 跳过探测。');
      return 1;
    }
    log('下载地址可访问。');
  }

  if (!prefixWritable && globalPrefix) {
    log(`警告：npm 全局目录不可写：${globalPrefix}`);
    logPermissionFix(globalPrefix, cache.origin || cache.cacheDir);
  }

  log(`开始安装：${displayCommand}`);
  const installResult = spawnSync(npm.command, npmArgs, { stdio: 'inherit', shell: Boolean(npm.shell) });
  if (installResult.error) {
    logError(`执行 npm 失败：${installResult.error.message}`);
    return 1;
  }
  if (installResult.status !== 0) {
    logError(`npm install 失败，退出码 ${installResult.status}`);
    log('若报 EACCES / EPERM（权限问题），可这样修复后重试：');
    logPermissionFix(globalPrefix, cache.origin || cache.cacheDir);
    log('若为网络或版本问题，请确认下载地址可访问后重试，或加 --skip-url-check 跳过探测。');
    return 1;
  }

  log(`${options.pkgName}@${options.version} 安装完成。`);
  verifyInstall(options.pkgName);
  return 0;
}

main().then((code) => {
  process.exit(code);
}).catch((error) => {
  logError(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
