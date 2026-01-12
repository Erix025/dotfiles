#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BOOTSTRAP_ROOT/lib"
MODULE_DIR="$BOOTSTRAP_ROOT/modules"

source "$BOOTSTRAP_ROOT/config.sh"

source "$LIB_DIR/core.sh"
for lib in "$LIB_DIR"/*.sh; do
    [[ "$lib" == "$LIB_DIR/core.sh" ]] && continue
    # shellcheck disable=SC1090
    source "$lib"
done

for module in "$MODULE_DIR"/*.sh; do
    # shellcheck disable=SC1090
    source "$module"
done

declare -A MODULE_STATUS=()

usage() {
    cat <<'EOF'
用法: run.sh [选项]

可用模式:
  --basic     prereq + dotfiles + shell
  --dev       prereq + secrets + dotfiles + shell + ssh
  --server    prereq + secrets + ssh + shell
  --full      prereq + secrets + dotfiles + shell + ssh

其它参数:
  --modules m1,m2,...   手动指定模块顺序
  --include-optional    在模板执行完成后执行 optional 模块
  -h, --help            显示本帮助

模块名称: prereq, secrets, dotfiles, shell, ssh, optional
EOF
    exit "${1:-0}"
}

run_module() {
    local module="$1"
    local func="module_${module}"

    if [[ "${MODULE_STATUS[$module]:-}" == "done" ]]; then
        log "跳过模块 $module (已执行)"
        return 0
    fi

    if ! declare -F "$func" >/dev/null 2>&1; then
        warn "模块 $module 未定义"
        return 1
    fi

    log "开始执行模块: $module"
    "$func"
    MODULE_STATUS[$module]="done"
}

template_modules() {
    local mode="$1"
    case "$mode" in
        basic) echo "prereq dotfiles shell" ;;
        dev) echo "prereq secrets dotfiles shell ssh" ;;
        server) echo "prereq secrets ssh shell" ;;
        full) echo "prereq secrets dotfiles shell ssh" ;;
        *) die "未知模式: $mode" ;;
    esac
}

MODE="basic"
RUN_OPTIONAL=false
CUSTOM_SEQUENCE=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --basic|--dev|--server|--full)
            MODE="${1#--}"
            shift
            ;;
        --modules)
            [[ $# -ge 2 ]] || die "--modules 需要参数"
            IFS=',' read -r -a CUSTOM_SEQUENCE <<<"$2"
            shift 2
            ;;
        --include-optional)
            RUN_OPTIONAL=true
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        *)
            die "未知参数: $1"
            ;;
    esac
done

if [[ ${#CUSTOM_SEQUENCE[@]} -gt 0 ]]; then
    MODULE_SEQUENCE=("${CUSTOM_SEQUENCE[@]}")
else
    IFS=' ' read -r -a MODULE_SEQUENCE <<<"$(template_modules "$MODE")"
fi

for module in "${MODULE_SEQUENCE[@]}"; do
    run_module "$module"
done

if [[ "$RUN_OPTIONAL" == true ]]; then
    run_module "optional"
fi
