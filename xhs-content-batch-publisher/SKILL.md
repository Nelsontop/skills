---
name: xhs-content-batch-publisher
description: "Use when the user wants to run a Xiaohongshu content batch end-to-end: create memo-style card assets, send sample images to Feishu for review, publish image notes with the `xhs` CLI, and log note ids or signal fields. Trigger on requests about 小红书批量发布, 备忘录风格出图, 飞书送审后发小红书, 笔记矩阵发布, or 回填 note id / 互动信号."
---

# XHS Content Batch Publisher

## Overview

Run a repeatable Xiaohongshu publishing loop:

1. turn content cards into memo-style images
2. send sample covers to Feishu
3. publish notes through `xhs`
4. verify with `xhs my-notes`
5. write back note ids and signal placeholders

Use this for real publishing work, not for architecture planning.

## When To Use

Use this skill when the user asks to:

- batch publish Xiaohongshu notes
- convert a content matrix into actual assets and live posts
- generate memo-style card images for Xiaohongshu
- send sample covers to Feishu before publishing
- publish via `xhs post`
- verify published notes and backfill note ids or signal logs

Do not use this skill for:

- product planning only
- generic image design work unrelated to Xiaohongshu
- deleting or cleaning up live notes without explicit approval

## Preconditions

Before doing work, verify:

- `xhs status` shows authenticated
- `FEISHU_APP_ID` and `FEISHU_APP_SECRET` are present if Feishu review is required
- the workspace has note titles, body text, and either an asset spec or enough source content to create one

If Pillow is missing from system Python, create a local virtualenv inside the project and install Pillow there. Do not modify the system Python environment.

## Workflow

### 1. Gather Inputs

Locate or create:

- a matrix doc with publish order
- note body files, usually `tmp-*.txt`
- an asset spec JSON for the batch
- a place to store generated images, usually `assets/<slug>/`

If user-facing outputs are involved, enforce this rule:

- never include any `模式` wording in visible assets, copy, or labels

### 2. Generate Assets

If the repo already has a local render script, reuse it.

If not, use [scripts/render_memo_cards.py](scripts/render_memo_cards.py) from this skill as the starting point.

Expected output:

- 3 card images per note
- sample cover image suitable for Feishu review
- asset directories grouped by note slug

### 3. Send Feishu Samples

Use the verified `cls_cli feishu-send-image` flow.

Command pattern:

```bash
FEISHU_APP_ID="$FEISHU_APP_ID" \
FEISHU_APP_SECRET="$FEISHU_APP_SECRET" \
PYTHONPATH=/vol3/1000/workspace/cls-cli/src \
/tmp/cls-cli-venv/bin/python -m cls_cli feishu-send-image \
  /abs/path/to/sample.png \
  --chat-id <chat_id>
```

Send at least one cover per note before formal publishing.

### 4. Publish With `xhs`

Use repeated `--images` flags.

Do not pass comma-separated image paths. The CLI treats that as a single file path.

Correct pattern:

```bash
xhs post \
  --title "标题" \
  --body "$(cat /abs/path/to/body.txt)" \
  --images /abs/path/to/01-cover.png \
  --images /abs/path/to/02-detail.png \
  --images /abs/path/to/03-cta.png \
  --yaml
```

If you need topics, rely on hashtags in the body or pass repeated `--topic` flags.

### 5. Verify Publishing

After publishing, run:

```bash
xhs my-notes --page 0 --yaml
```

Confirm:

- the new titles appear
- each note has a real `id`
- image count matches expectation

### 6. Write Back Status

Update the project’s local docs if they exist:

- matrix doc: mark asset status and publish status
- signal log: add note ids and initial counts
- project state: move the slice from preparation to live batch

## Guardrails

- Do not delete live Xiaohongshu notes without explicit confirmation.
- Do not publish with internal language like `模式一`, `模式二`, `测试批次`, or `商业计划`.
- Do not assume `--images` accepts comma-separated paths.
- Do not claim a note is live until `xhs my-notes` shows it.
- Do not leave generated virtualenvs or caches unignored if they are inside the repo.

## Resources

- For command and copy constraints, read [references/publishing-rules.md](references/publishing-rules.md).
- For asset generation, reuse or adapt [scripts/render_memo_cards.py](scripts/render_memo_cards.py).
