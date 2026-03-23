#!/usr/bin/env python3

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


WIDTH = 1080
HEIGHT = 1440
CARD_X0 = 68
CARD_Y0 = 120
CARD_X1 = WIDTH - 68
CARD_Y1 = HEIGHT - 120
CARD_RADIUS = 40
FONT_PATH = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"


def load_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size=size)


def text_width(font: ImageFont.FreeTypeFont, text: str) -> int:
    bbox = font.getbbox(text)
    return int(bbox[2] - bbox[0])


def wrap_text(text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    lines: list[str] = []
    current = ""
    for ch in text:
        if ch == "\n":
            if current:
                lines.append(current)
                current = ""
            else:
                lines.append("")
            continue
        candidate = current + ch
        if current and text_width(font, candidate) > max_width:
            lines.append(current)
            current = ch
        else:
            current = candidate
    if current:
        lines.append(current)

    merged: list[str] = []
    punctuation = set("，。！？；：、,.!?;:")
    for line in lines:
        if merged and line and all(ch in punctuation for ch in line):
            merged[-1] += line
        elif merged and line and line[0] in punctuation:
            merged[-1] += line[0]
            rest = line[1:]
            if rest:
                merged.append(rest)
        else:
            merged.append(line)
    return merged


def draw_wrapped(draw, text, font, fill, x, y, max_width, line_gap) -> int:
    lines = wrap_text(text, font, max_width)
    line_height = int(font.size * 1.25)
    for i, line in enumerate(lines):
        draw.text((x, y + i * (line_height + line_gap)), line, font=font, fill=fill)
    return y + len(lines) * (line_height + line_gap)


def render_card(card: dict, output_path: Path) -> None:
    bg = Image.new("RGB", (WIDTH, HEIGHT), "#F7F0E8")
    draw = ImageDraw.Draw(bg)

    draw.ellipse((-160, -60, 340, 420), fill="#F5C6A9")
    draw.ellipse((WIDTH - 260, HEIGHT - 280, WIDTH + 180, HEIGHT + 120), fill="#F8D8C2")

    draw.rounded_rectangle(
        (CARD_X0, CARD_Y0, CARD_X1, CARD_Y1),
        radius=CARD_RADIUS,
        fill="#FFF8F2",
    )

    label_font = load_font(42)
    title_font = load_font(72)
    bullet_font = load_font(48)
    footer_font = load_font(38)

    label_text = card["label"]
    label_w = text_width(label_font, label_text) + 48
    draw.rounded_rectangle(
        (CARD_X0 + 48, CARD_Y0 + 36, CARD_X0 + 48 + label_w, CARD_Y0 + 96),
        radius=24,
        fill="#F3E7DC",
    )
    draw.text((CARD_X0 + 72, CARD_Y0 + 42), label_text, font=label_font, fill="#6D5A50")

    content_x = CARD_X0 + 58
    content_y = CARD_Y0 + 160
    content_w = CARD_X1 - CARD_X0 - 116

    title_lines = wrap_text(card["title"], title_font, content_w)
    title_line_height = int(title_font.size * 1.18)
    for i, line in enumerate(title_lines):
        draw.text((content_x, content_y + i * title_line_height), line, font=title_font, fill="#5E4842")

    y = content_y + len(title_lines) * title_line_height + 40
    for bullet in card["bullets"]:
        draw.ellipse((content_x, y + 16, content_x + 20, y + 36), fill="#F2B28D")
        bullet_end = draw_wrapped(draw, bullet, bullet_font, "#5E4842", content_x + 38, y, content_w - 38, 6)
        y = bullet_end + 20

    footer_y = CARD_Y1 - 150
    draw.line((content_x, footer_y, CARD_X1 - 58, footer_y), fill="#8B756F", width=2)
    draw_wrapped(draw, card["footer"], footer_font, "#8B756F", content_x, footer_y + 28, content_w, 4)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    bg.save(output_path)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: render_memo_cards.py <spec.json>", file=sys.stderr)
        return 1

    spec_path = Path(sys.argv[1]).resolve()
    with spec_path.open("r", encoding="utf-8") as fh:
        spec = json.load(fh)

    for post in spec["posts"]:
        out_dir = Path(post["output_dir"])
        for card in post["cards"]:
            render_card(card, out_dir / card["filename"])
            print(f"rendered {out_dir / card['filename']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
