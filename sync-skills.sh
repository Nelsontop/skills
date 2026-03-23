#!/bin/bash
# 定时同步技能脚本 - 从 codex 目录同步技能并更新 README

set -Eeuo pipefail

SOURCE_DIR="${SOURCE_DIR:-/home/jingqi/.codex/skills}"
TARGET_DIR="${TARGET_DIR:-/vol3/1000/workspace/skills}"
README_FILE="${README_FILE:-$TARGET_DIR/README.md}"
LOG_FILE="${LOG_FILE:-$TARGET_DIR/sync.log}"
LOCK_FILE="${LOCK_FILE:-$TARGET_DIR/.sync-skills.lock}"
DRY_RUN=0
NO_GIT=0

# 定义分类映射
CATEGORY_ORDER=("开发流程" "调试与测试" "文档与内容" "研究与信息" "文件处理" "开发工具")
declare -A CATEGORIES
CATEGORIES["开发流程"]="brainstorming|writing-plans|executing-plans|test-driven-development|using-git-worktrees|git-workflow|subagent-driven-development|dispatching-parallel-agents|finishing-a-development-branch|using-superpowers"
CATEGORIES["调试与测试"]="systematic-debugging|debugger|receiving-code-review|requesting-code-review|gh-fix-ci"
CATEGORIES["文档与内容"]="technical-writer|content-creator|slide|summarize|docs-writer|docs-review"
CATEGORIES["研究与信息"]="deep-research|browse|cls-news-monitor"
CATEGORIES["文件处理"]="docx|pdf|xlsx"
CATEGORIES["开发工具"]="flowchart-generator-skill|self-improving-agent"

usage() {
    cat <<'USAGE'
用法: ./sync-skills.sh [选项]

选项:
  --dry-run    只打印动作，不修改文件
  --no-git     跳过 git add/commit/push
  -h, --help   显示帮助
USAGE
}

log() {
    local message="$1"
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

run_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log "[dry-run] $*"
    else
        "$@"
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "缺少依赖命令: $cmd"
        exit 1
    fi
}

acquire_lock() {
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        log "已有同步任务在运行，退出"
        exit 1
    fi
}

validate_paths() {
    [ -d "$SOURCE_DIR" ] || { log "源目录不存在: $SOURCE_DIR"; exit 1; }
    [ -d "$TARGET_DIR" ] || { log "目标目录不存在: $TARGET_DIR"; exit 1; }
    [ -f "$README_FILE" ] || { log "README 不存在: $README_FILE"; exit 1; }
}

get_source_skills() {
    local -n ref=$1
    while IFS= read -r -d '' dir; do
        local name
        name=$(basename "$dir")
        if [[ ! "$name" =~ ^\. ]] && [[ "$name" != "superpowers" ]]; then
            ref+=("$name")
        fi
    done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
}

delete_removed_skills() {
    local -n source_ref=$1
    declare -A source_set=()
    local skill
    for skill in "${source_ref[@]}"; do
        source_set["$skill"]=1
    done

    shopt -s nullglob
    local target_dir
    for target_dir in "$TARGET_DIR"/*/; do
        [ -d "$target_dir" ] || continue
        local dir_name
        dir_name=$(basename "$target_dir")
        if [[ "$dir_name" =~ ^\. ]] || [[ "$dir_name" == "superpowers" ]]; then
            continue
        fi
        if [ -z "${source_set[$dir_name]:-}" ] && [ -f "$target_dir/SKILL.md" ]; then
            log "删除技能: $dir_name"
            run_cmd rm -rf "$target_dir"
        fi
    done
    shopt -u nullglob
}

sync_skills() {
    local -n source_ref=$1
    local skill
    for skill in "${source_ref[@]}"; do
        log "处理技能: $skill"
        if [ "$DRY_RUN" -eq 1 ]; then
            log "[dry-run] rsync -a --delete '$SOURCE_DIR/$skill/' '$TARGET_DIR/$skill/'"
            continue
        fi
        mkdir -p "$TARGET_DIR/$skill"
        rsync -a --delete "$SOURCE_DIR/$skill/" "$TARGET_DIR/$skill/"
    done
}

get_category() {
    local skill="$1"
    local category
    for category in "${CATEGORY_ORDER[@]}"; do
        if [[ "|${CATEGORIES[$category]}|" == *"|$skill|"* ]]; then
            echo "$category"
            return
        fi
    done
    echo "其他"
}

parse_skill_metadata() {
    local skill_dir="$1"
    local skill_file="$skill_dir/SKILL.md"

    if [ ! -f "$skill_file" ]; then
        echo "name: $(basename "$skill_dir")|description: 未知|triggers:"
        return
    fi

    local name
    name=$(basename "$skill_dir")
    local description=""
    local triggers=""

    if grep -q '^description:' "$skill_file"; then
        description=$(sed -n '/^description:/p' "$skill_file" | sed 's/description: *//' | sed 's/"//g')
    fi

    if [ -z "$description" ] && grep -q '## Overview' "$skill_file"; then
        description=$(sed -n '/## Overview/,/^##/p' "$skill_file" | sed '1d;$d' | head -1 | tr -d '\n' | xargs)
    fi

    if [[ "$description" =~ Use\ when ]]; then
        triggers=$(echo "$description" | sed 's/.*Use when //' | sed 's/ when .*//')
    fi

    echo "name: $name|description: $description|triggers: $triggers"
}

generate_readme() {
    log "生成 README.md..."

    if [ "$DRY_RUN" -eq 1 ]; then
        return
    fi

    cat > "$README_FILE" << 'README_HEAD'
# skills

自用技能合集

## 目录导航

- [开发流程](#开发流程) - 规划、编码、版本控制相关工作流
- [调试与测试](#调试与测试) - Bug定位、代码审查、测试
- [文档与内容](#文档与内容) - 技术文档、内容创作、演示
- [研究与信息](#研究与信息) - 深度研究、新闻资讯
- [文件处理](#文件处理) - Office文档、PDF处理
- [开发工具](#开发工具) - 辅助工具、自动化

---

README_HEAD

    declare -A SKILL_DESCRIPTIONS=()
    declare -A SKILL_TRIGGERS=()
    declare -A TRIGGERS_ZH=()
    declare -A DESCRIPTIONS_ZH=()

    TRIGGERS_ZH["brainstorming"]="需求澄清、方案构思、设计讨论"
    TRIGGERS_ZH["writing-plans"]="多步骤任务、实施计划拆解"
    TRIGGERS_ZH["executing-plans"]="按既定计划落地执行"
    TRIGGERS_ZH["test-driven-development"]="先写测试、再实现功能"
    TRIGGERS_ZH["using-git-worktrees"]="需要隔离分支并行开发"
    TRIGGERS_ZH["git-workflow"]="提交、分支、PR 流程"
    TRIGGERS_ZH["using-superpowers"]="会话开始、技能选择"
    TRIGGERS_ZH["systematic-debugging"]="故障排查、异常定位"
    TRIGGERS_ZH["receiving-code-review"]="处理代码评审意见"
    TRIGGERS_ZH["gh-fix-ci"]="修复 GitHub Actions 失败"
    TRIGGERS_ZH["technical-writer"]="技术文档、使用指南、API 文档"
    TRIGGERS_ZH["content-creator"]="博客、社媒、营销文案"
    TRIGGERS_ZH["summarize"]="总结 URL、视频、文稿"
    TRIGGERS_ZH["deep-research"]="深度调研、多来源分析"
    TRIGGERS_ZH["browse"]="网页 QA、交互验证、截图取证"
    TRIGGERS_ZH["docx"]="Word 文档创建与编辑"
    TRIGGERS_ZH["pdf"]="PDF 读取、合并、拆分、OCR"
    TRIGGERS_ZH["xlsx"]="表格清洗、编辑、生成"
    TRIGGERS_ZH["flowchart-generator-skill"]="自然语言生成流程图"
    TRIGGERS_ZH["self-improving-agent"]="失败复盘、能力改进"

    DESCRIPTIONS_ZH["brainstorming"]="在实现前先梳理目标、约束和方案取舍。"
    DESCRIPTIONS_ZH["writing-plans"]="把需求拆成可执行的阶段性计划与里程碑。"
    DESCRIPTIONS_ZH["executing-plans"]="依据现有计划逐步执行并在检查点汇报。"
    DESCRIPTIONS_ZH["test-driven-development"]="采用测试先行方式实现功能并降低回归风险。"
    DESCRIPTIONS_ZH["using-git-worktrees"]="创建独立工作树，避免与当前改动互相干扰。"
    DESCRIPTIONS_ZH["git-workflow"]="规范化分支、提交与 PR 协作流程。"
    DESCRIPTIONS_ZH["using-superpowers"]="帮助识别并调用最合适的技能工作流。"
    DESCRIPTIONS_ZH["systematic-debugging"]="按系统化步骤定位根因并验证修复效果。"
    DESCRIPTIONS_ZH["receiving-code-review"]="评估评审建议并严谨地落地改动。"
    DESCRIPTIONS_ZH["gh-fix-ci"]="分析 CI 日志并修复 PR 检查失败。"
    DESCRIPTIONS_ZH["technical-writer"]="产出清晰的技术说明、教程和参考文档。"
    DESCRIPTIONS_ZH["content-creator"]="面向目标受众生成更有传播力的内容。"
    DESCRIPTIONS_ZH["summarize"]="从链接或本地文件提取重点并输出摘要。"
    DESCRIPTIONS_ZH["deep-research"]="整合多方信息并给出带引用的研究结论。"
    DESCRIPTIONS_ZH["browse"]="通过无头浏览器完成页面测试与状态校验。"
    DESCRIPTIONS_ZH["docx"]="创建、修改与重排 .docx 文档内容。"
    DESCRIPTIONS_ZH["pdf"]="处理 PDF 文本、页面结构和文档转换任务。"
    DESCRIPTIONS_ZH["xlsx"]="处理 .xlsx/.csv 数据并生成结构化表格文件。"
    DESCRIPTIONS_ZH["flowchart-generator-skill"]="把自然语言描述转换为结构化 SVG 流程图。"
    DESCRIPTIONS_ZH["self-improving-agent"]="记录失败经验并持续优化执行策略。"

    local skill_dir skill_name metadata
    shopt -s nullglob
    for skill_dir in "$TARGET_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        if [[ "$skill_name" =~ ^\. ]] || [[ "$skill_name" == "superpowers" ]] || [ ! -f "$skill_dir/SKILL.md" ]; then
            continue
        fi

        metadata=$(parse_skill_metadata "$skill_dir")
        SKILL_DESCRIPTIONS[$skill_name]=$(echo "$metadata" | cut -d'|' -f2 | sed 's/description: //')
        SKILL_TRIGGERS[$skill_name]=$(echo "$metadata" | cut -d'|' -f3 | sed 's/triggers: //')
    done
    shopt -u nullglob

    local category
    for category in "${CATEGORY_ORDER[@]}"; do
        {
            echo "## $category"
            echo
            echo "| 技能名 | 触发关键字 | 使用场景 | 功能描述 |"
            echo "|---|---|---|---|"
        } >> "$README_FILE"

        IFS='|' read -ra skills <<< "${CATEGORIES[$category]}"
        local skill
        for skill in "${skills[@]}"; do
            if [ -f "$TARGET_DIR/$skill/SKILL.md" ]; then
                local skill_link triggers description
                skill_link="[$skill](#$skill)"
                triggers="${TRIGGERS_ZH[$skill]:-${SKILL_TRIGGERS[$skill]:-提到该技能名或相关任务场景}}"
                description="${DESCRIPTIONS_ZH[$skill]:-${SKILL_DESCRIPTIONS[$skill]:-暂无描述}}"
                description=$(echo "$description" | sed 's/|/,/g' | head -c 100)
                echo "| $skill_link | $triggers | - | $description |" >> "$README_FILE"
            fi
        done
        echo >> "$README_FILE"
    done
}

commit_changes() {
    if [ "$NO_GIT" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
        log "跳过 Git 提交"
        return
    fi

    log "提交更改到 Git..."
    if git -C "$TARGET_DIR" diff --quiet && git -C "$TARGET_DIR" diff --cached --quiet; then
        log "没有变更需要提交"
        return
    fi

    git -C "$TARGET_DIR" add -A -- . ':(exclude)CLAUDE.md' ':(exclude).sync*'
    if git -C "$TARGET_DIR" diff --cached --quiet; then
        log "没有可提交变更（已排除 CLAUDE.md 和 .sync*）"
        return
    fi
    git -C "$TARGET_DIR" commit -m "Auto sync skills from codex - $(date '+%Y-%m-%d %H:%M:%S')"
    log "推送到远程..."
    git -C "$TARGET_DIR" push origin main
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                ;;
            --no-git)
                NO_GIT=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "未知参数: $1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"

    require_cmd find
    require_cmd rsync
    require_cmd flock
    require_cmd git

    validate_paths
    acquire_lock

    log "开始同步技能..."

    local source_skills=()
    get_source_skills source_skills
    delete_removed_skills source_skills
    sync_skills source_skills
    generate_readme
    commit_changes

    log "同步完成！"
}

main "$@"
