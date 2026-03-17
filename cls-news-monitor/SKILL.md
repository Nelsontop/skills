---
name: cls-news-monitor
description: Use when the user wants to query or summarize finance news from https://www.cls.cn/ using the local cls-cli project. Trigger for requests like 查询财联社新闻、查询今天最新财经新闻、按关键词搜索财联社内容、手动汇总财联社资讯、飞书汇总推送.
---

# CLS News Monitor

Use this skill for finance-news requests that should be fulfilled through the local `cls-cli` project at `/vol3/1000/workspace/cls-cli`.

## What This Skill Does

- Queries keyword-related content from `cls.cn`
- Fetches the latest telegraph-style finance news
- Builds keyword-based digests from the latest telegraph feed
- Generates finance-style morning-brief images from the latest telegraph feed
- Supports Feishu app-bot delivery for uploaded images

## Required Workflow

1. Work in `/vol3/1000/workspace/cls-cli`.
2. Prefer running the local CLI instead of reimplementing scraping logic.
3. For “today/latest/current” requests, include the absolute Beijing date in the answer.
4. When reporting results, summarize the command output instead of dumping raw terminal text.
5. Default to concise plain-text summaries; do not use Markdown tables unless the user explicitly asks for them.
6. If the user asks for image output, always fetch latest telegraph data first, then generate image (never reuse stale image files).
7. Once the user has approved a visual direction, keep later iterations in the same style unless the user asks to change it.
8. For requests like “查询财联社新闻汇总成图片”“晨报形式”“快讯形式”, treat image generation as default behavior even if the user does not repeat “发送图片”.
9. If Feishu app-bot credentials and a target chat are available, send the image proactively after generation.
10. Only ask for missing info when delivery cannot be completed (for example missing `chat_id`).
11. Save generated image files and intermediate HTML files in `resources/` under the current working directory, not `/tmp`.

## Output Format

- For hot-news summaries, prefer plain-text output.
- Use a short numbered list or short bullets for multiple items.
- Each item should include, when useful: `时间`、`标题`、`一句话摘要`、`链接`。
- After the list, you may add 1 short line grouping the main themes if it adds value.
- Only use Markdown tables when the user explicitly asks for table output.

## Image Output

- For requests like “汇总成图片”“晨报形式”“发群海报”, prefer a finance-style poster image.
- Default visual direction:
  - Larger typography
  - Dense, full-bleed layout with minimal empty space
  - Finance-oriented styling such as dark blue backgrounds, gold accents, data-card panels, and stronger hierarchy
- Structure requirement (default): two explicit sections `核心新闻` and `市场信号`.
- Header requirement (default): keep title `财联社快讯`; remove any subtitle line below the title unless user explicitly asks for one.
- Footer requirement (default): do not show “数据来源” or “生成时间” lines unless user explicitly asks to include them.
- The image should summarize a few clear market themes first, then show the supporting headlines.
- If the user asks for a revision such as “字体大一点”“铺满”“更偏金融属性”, treat it as an iteration on the same visual system and preserve the established look and structure.
- After image generation, default to sending it through Feishu app bot when delivery prerequisites are met.
- If `FEISHU_DEFAULT_CHAT_ID` is configured, use it directly without asking the user again.

## Command Map

- Keyword search:
  - `PYTHONPATH=src .venv/bin/python -m cls_cli search <keyword> --limit <n>`
- One-off digest:
  - `PYTHONPATH=src .venv/bin/python -m cls_cli digest --keyword <kw1> --keyword <kw2>`
  - `PYTHONPATH=src .venv/bin/python -m cls_cli digest --keywords-csv "kw1,kw2"`
- Feishu app bot chat lookup:
  - `PYTHONPATH=src .venv/bin/python -m cls_cli feishu-chat-list --name <keyword>`
- Feishu app bot image send:
  - `PYTHONPATH=src .venv/bin/python -m cls_cli feishu-send-image <image_path> --chat-id <chat_id>`
  - `PYTHONPATH=src .venv/bin/python -m cls_cli feishu-send-image <image_path> --chat-name <keyword>`
- Latest flash-image generation (with `核心新闻/市场信号` layout):
  - `PYTHONPATH=src .venv/bin/python scripts/generate_flash_image.py`

Read `references/commands.md` if you need setup steps, environment variables, or GitHub Actions details.

## Environment Checks

If `.venv` or Playwright is missing, bootstrap with:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -e .[dev]
python -m playwright install chromium
```

## Feishu Delivery

- Real Feishu delivery needs `CLS_FEISHU_WEBHOOK_URL`.
- Feishu app-bot image delivery needs `FEISHU_APP_ID` and `FEISHU_APP_SECRET`.
- Set `FEISHU_DEFAULT_CHAT_ID` to avoid repeated “发到哪个群” confirmations.
