#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
SOURCE_DIR="$WORK_DIR/source"
TARGET_DIR="$WORK_DIR/target"
README_FILE="$TARGET_DIR/README.md"
LOG_FILE="$TARGET_DIR/sync.log"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$SOURCE_DIR/alpha" "$SOURCE_DIR/beta" "$TARGET_DIR/beta" "$TARGET_DIR/ghost"

cat > "$SOURCE_DIR/alpha/SKILL.md" <<'SK1'
---
description: Use when alpha workflows
---
SK1

cat > "$SOURCE_DIR/beta/SKILL.md" <<'SK2'
---
description: Use when beta workflows
---
SK2

cat > "$TARGET_DIR/ghost/SKILL.md" <<'GHOST'
---
description: stale skill
---
GHOST

echo "old" > "$TARGET_DIR/beta/old.txt"
echo "x" > "$TARGET_DIR/ghost/x.txt"
cat > "$README_FILE" <<'R0'
# placeholder
R0

SOURCE_DIR="$SOURCE_DIR" \
TARGET_DIR="$TARGET_DIR" \
README_FILE="$README_FILE" \
LOG_FILE="$LOG_FILE" \
bash "$ROOT_DIR/sync-skills.sh" --no-git

# 删除无效目录
if [ -d "$TARGET_DIR/ghost" ]; then
    echo "FAIL: ghost dir should be removed"
    exit 1
fi

# 新技能复制成功
if [ ! -f "$TARGET_DIR/alpha/SKILL.md" ]; then
    echo "FAIL: alpha skill not synced"
    exit 1
fi

# 旧文件应被 rsync --delete 删除
if [ -f "$TARGET_DIR/beta/old.txt" ]; then
    echo "FAIL: stale file old.txt should be deleted"
    exit 1
fi

# README 内容检查
if ! grep -q "# skills" "$README_FILE"; then
    echo "FAIL: README not generated"
    exit 1
fi
if ! grep -q "## 开发流程" "$README_FILE"; then
    echo "FAIL: README missing category"
    exit 1
fi

# 不应生成 README 备份文件
if ls "$TARGET_DIR"/README.md.bak.* >/dev/null 2>&1; then
    echo "FAIL: README backup file should not be created"
    exit 1
fi

echo "PASS"

COMMIT_WORK_DIR="$(mktemp -d)"
COMMIT_SOURCE_DIR="$COMMIT_WORK_DIR/source"
COMMIT_TARGET_DIR="$COMMIT_WORK_DIR/target"
COMMIT_REMOTE_DIR="$COMMIT_WORK_DIR/remote.git"
COMMIT_README_FILE="$COMMIT_TARGET_DIR/README.md"
COMMIT_LOG_FILE="$COMMIT_TARGET_DIR/sync.log"

cleanup_commit() {
    rm -rf "$COMMIT_WORK_DIR"
}
trap cleanup_commit EXIT

mkdir -p "$COMMIT_SOURCE_DIR/alpha" "$COMMIT_TARGET_DIR"

cat > "$COMMIT_SOURCE_DIR/alpha/SKILL.md" <<'SK3'
---
description: Use when alpha workflows
---
SK3

cat > "$COMMIT_README_FILE" <<'R1'
# placeholder
R1

SOURCE_DIR="$COMMIT_SOURCE_DIR" \
TARGET_DIR="$COMMIT_TARGET_DIR" \
README_FILE="$COMMIT_README_FILE" \
LOG_FILE="$COMMIT_LOG_FILE" \
bash "$ROOT_DIR/sync-skills.sh" --no-git >/dev/null

git init --bare "$COMMIT_REMOTE_DIR" >/dev/null
git -C "$COMMIT_TARGET_DIR" init -b main >/dev/null
git -C "$COMMIT_TARGET_DIR" config user.name "Test User"
git -C "$COMMIT_TARGET_DIR" config user.email "test@example.com"
git -C "$COMMIT_TARGET_DIR" remote add origin "$COMMIT_REMOTE_DIR"
git -C "$COMMIT_TARGET_DIR" add README.md alpha/SKILL.md
git -C "$COMMIT_TARGET_DIR" commit -m "Initial commit" >/dev/null
git -C "$COMMIT_TARGET_DIR" push -u origin main >/dev/null

echo "staged-only-change" > "$COMMIT_TARGET_DIR/note.txt"
git -C "$COMMIT_TARGET_DIR" add note.txt
BEFORE_COMMIT_COUNT=$(git -C "$COMMIT_TARGET_DIR" rev-list --count HEAD)

SOURCE_DIR="$COMMIT_SOURCE_DIR" \
TARGET_DIR="$COMMIT_TARGET_DIR" \
README_FILE="$COMMIT_README_FILE" \
LOG_FILE="$COMMIT_LOG_FILE" \
bash "$ROOT_DIR/sync-skills.sh"

AFTER_COMMIT_COUNT=$(git -C "$COMMIT_TARGET_DIR" rev-list --count HEAD)
if [ "$AFTER_COMMIT_COUNT" -le "$BEFORE_COMMIT_COUNT" ]; then
    echo "FAIL: staged-only changes should be committed"
    exit 1
fi

if ! git -C "$COMMIT_TARGET_DIR" diff --cached --quiet; then
    echo "FAIL: staged-only changes should not remain in index after sync commit"
    exit 1
fi

echo "PASS: staged-only changes are committed"
