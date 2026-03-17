# Commands

## Repo

- Path: `/vol3/1000/workspace/cls-cli`

## Common Commands

```bash
PYTHONPATH=src .venv/bin/python -m cls_cli search OpenAI --limit 5
PYTHONPATH=src .venv/bin/python -m cls_cli digest --keywords-csv "OpenAI,英伟达"
PYTHONPATH=src .venv/bin/python -m cls_cli feishu-chat-list --name cls
PYTHONPATH=src .venv/bin/python -m cls_cli feishu-send-image /tmp/cls_morning_brief.png --chat-id oc_xxx
```

## State File

Use a temporary state file when you want a clean one-off digest:

```bash
tmp=$(mktemp)
PYTHONPATH=src .venv/bin/python -m cls_cli digest --keywords-csv "中信建投,宇环数控" --state-file "$tmp"
```

## Environment Variables

- `CLS_FEISHU_WEBHOOK_URL`: Feishu bot webhook for push delivery
- `CLS_KEYWORDS`: Comma-separated keywords for digest
- `FEISHU_APP_ID`: Feishu app-bot app id
- `FEISHU_APP_SECRET`: Feishu app-bot app secret
- `FEISHU_DEFAULT_CHAT_ID`: Default target chat id for image delivery (recommended)
