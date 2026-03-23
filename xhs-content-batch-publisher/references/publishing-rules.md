# Publishing Rules

## Proven Command Rules

### Xiaohongshu CLI

- Check login with:

```bash
xhs status
```

- Publish with repeated `--images` flags:

```bash
xhs post \
  --title "标题" \
  --body "$(cat /abs/path/to/body.txt)" \
  --images /abs/path/to/01-cover.png \
  --images /abs/path/to/02-detail.png \
  --images /abs/path/to/03-cta.png \
  --yaml
```

- Verify with:

```bash
xhs my-notes --page 0 --yaml
```

### Feishu Sample Review

```bash
FEISHU_APP_ID="$FEISHU_APP_ID" \
FEISHU_APP_SECRET="$FEISHU_APP_SECRET" \
PYTHONPATH=/vol3/1000/workspace/cls-cli/src \
/tmp/cls-cli-venv/bin/python -m cls_cli feishu-send-image \
  /abs/path/to/sample.png \
  --chat-id <chat_id>
```

## Content Rules

- Never show any `模式` wording in user-facing assets.
- Never show internal planning labels such as:
  - `商业计划`
  - `测试`
  - `批次`
- Keep one CTA per post.
- Prefer comment-keyword CTA over direct sales wording.

## Environment Rules

- If Pillow is unavailable in the system Python, create a project-local virtualenv and install it there.
- Add local virtualenv and Python cache directories to `.gitignore` if they live inside the repo.
