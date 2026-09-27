#!/usr/bin/env bash
# oortcodex-cli 一键安装脚本（bash / zsh / Git Bash 入口）
# 用法：
#   ./install-cli.sh                      安装默认版本 0.0.1
#   ./install-cli.sh --version 0.0.2      安装指定版本
#   OORTCODEX_CLI_VERSION=0.0.3 ./install-cli.sh
# 可选参数：--node-version <版本>、--auto-install-node（无 Node 时自动安装）

set -euo pipefail

LOG_PREFIX="[oortcodex]"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SCRIPT="${SCRIPT_DIR}/install-cli.mjs"

# 默认配置，可用环境变量覆盖
CLI_VERSION="${OORTCODEX_CLI_VERSION:-0.0.1}"
NODE_VERSION="${OORTCODEX_NODE_VERSION:-24.14.0}"
AUTO_INSTALL_NODE=0

# 从参数中提取脚本自身需要关心的选项（其余全部透传给核心脚本）
CORE_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --version|-v)
      CLI_VERSION="${2:-}"; CORE_ARGS+=("$1"); [ $# -gt 1 ] && { CORE_ARGS+=("$2"); shift; } || true; shift || true ;;
    --version=*)
      CLI_VERSION="${1#*=}"; CORE_ARGS+=("$1"); shift ;;
    --node-version)
      NODE_VERSION="${2:-}"; CORE_ARGS+=("$1"); [ $# -gt 1 ] && { CORE_ARGS+=("$2"); shift; } || true; shift || true ;;
    --node-version=*)
      NODE_VERSION="${1#*=}"; CORE_ARGS+=("$1"); shift ;;
    --auto-install-node)
      AUTO_INSTALL_NODE=1; shift ;;
    *)
      CORE_ARGS+=("$1"); shift ;;
  esac
done

# 定位 nvm.sh 并加载，用于自动安装/切换指定版本 Node
load_nvm() {
  if [ -n "${NVM_DIR:-}" ] && [ -s "${NVM_DIR}/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "${NVM_DIR}/nvm.sh"
  elif [ -s "${HOME}/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.nvm/nvm.sh"
  fi
}

# Node 缺失时的处理：优先使用 nvm 安装，否则打印指引
install_node() {
  echo "${LOG_PREFIX} 未检测到 Node.js。"
  load_nvm
  if command -v nvm >/dev/null 2>&1 && [ "$AUTO_INSTALL_NODE" -eq 1 ]; then
    echo "${LOG_PREFIX} 使用 nvm 安装 Node.js ${NODE_VERSION} ..."
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION" >/dev/null
    return 0
  fi
  echo "${LOG_PREFIX} 请先安装 Node.js ${NODE_VERSION}："
  echo "  nvm install ${NODE_VERSION} && nvm use ${NODE_VERSION}"
  echo "  或下载：https://nodejs.org/dist/v${NODE_VERSION}/"
  echo "${LOG_PREFIX} 安装后重新执行本脚本，或加 --auto-install-node 由脚本自动安装。本次不会自动修改你的环境"
  return 1
}

# Node 已安装但版本不符时，尝试用 nvm 切换到要求版本
ensure_node_version() {
  local current
  current="$(node --version 2>/dev/null | sed 's/^v//')"
  if [ "$current" = "$NODE_VERSION" ]; then
    return 0
  fi
  load_nvm
  if command -v nvm >/dev/null 2>&1; then
    echo "${LOG_PREFIX} 当前 Node v${current}，尝试切换到 ${NODE_VERSION} ..."
    nvm use "$NODE_VERSION" >/dev/null 2>&1 || nvm install "$NODE_VERSION" >/dev/null 2>&1 || true
  fi
  return 0
}

if ! command -v node >/dev/null 2>&1; then
  install_node || exit 1
else
  ensure_node_version
fi

if [ ! -f "$CORE_SCRIPT" ]; then
  echo "${LOG_PREFIX} 错误：找不到核心脚本 ${CORE_SCRIPT}"
  exit 1
fi

echo "${LOG_PREFIX} 安装包：oortcodex-cli@${CLI_VERSION}，要求 Node ${NODE_VERSION}"
exec node "$CORE_SCRIPT" "${CORE_ARGS[@]}"
