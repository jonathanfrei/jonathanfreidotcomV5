#!/usr/bin/env python3
"""Copy the demo book tree into _books/ with title/H1 cleanup."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

import yaml

SRC = Path(r"C:\Users\jfrei\Downloads\dispelling-beauty-lies")
DEST = Path(r"C:\Users\jfrei\Downloads\X_jonathanfreidotcomV5\_books\dispelling-beauty-lies")

TITLE_PREFIX = re.compile(
    r"^(?:[IVXLCDM]+\.|[a-z]\.|\d+\.)\s+",
    re.IGNORECASE,
)
LINK_LABEL_PREFIX = re.compile(
    r"\[(?:[IVXLCDM]+\.|[a-z]\.|\d+\.)\s+([^\]]+)\]",
    re.IGNORECASE,
)
FIRST_H1 = re.compile(r"\A\s*#\s+.+\n+")


def split_fm(text: str) -> tuple[dict, str]:
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    data = yaml.safe_load(parts[1]) or {}
    return data, parts[2].lstrip("\n")


def dump_fm(data: dict) -> str:
    dumped = yaml.safe_dump(
        data,
        sort_keys=False,
        allow_unicode=True,
        default_flow_style=False,
        width=1000,
    )
    return f"---\n{dumped}---\n\n"


def clean_title(title: str) -> str:
    cleaned = TITLE_PREFIX.sub("", title or "").strip()
    return cleaned or title


def transform(path: Path, rel: Path) -> str:
    data, body = split_fm(path.read_text(encoding="utf-8"))
    title = str(data.get("title") or "")
    data["title"] = clean_title(title)
    data.pop("level", None)
    data.pop("order", None)
    data.pop("parent", None)

    if rel.as_posix() == "001-dispelling-beauty-lies.md":
        data["index"] = False
        data["listed"] = False
        data.setdefault(
            "description",
            "The truth about feminine beauty — a converted demo book, not indexed.",
        )

    body = FIRST_H1.sub("", body, count=1)
    body = LINK_LABEL_PREFIX.sub(r"[\1]", body)
    body = body.strip() + "\n"
    return dump_fm(data) + body


def main() -> None:
    if not SRC.is_dir():
        raise SystemExit(f"Missing source tree: {SRC}")
    if DEST.exists():
        shutil.rmtree(DEST)
    count = 0
    for src in SRC.rglob("*.md"):
        rel = src.relative_to(SRC)
        dest = DEST / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(transform(src, rel), encoding="utf-8")
        count += 1
    print(f"Imported {count} pages to {DEST}")


if __name__ == "__main__":
    main()
