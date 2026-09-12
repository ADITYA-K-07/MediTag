"""Small SQLite registry for the MVP; no clinical data is returned without a role check."""

from __future__ import annotations

import json
import sqlite3
from pathlib import Path


class TagStore:
    def __init__(self, database_path: Path):
        database_path.parent.mkdir(parents=True, exist_ok=True)
        self.connection = sqlite3.connect(database_path, check_same_thread=False)
        self.connection.row_factory = sqlite3.Row
        self.connection.execute(
            """
            CREATE TABLE IF NOT EXISTS tags (
                tag_id INTEGER PRIMARY KEY,
                tier2_json TEXT NOT NULL
            )
            """
        )
        self.connection.commit()

    def issue(self, tag_id: int, tier2_record: dict[str, object]) -> None:
        self.connection.execute(
            "INSERT INTO tags(tag_id, tier2_json) VALUES (?, ?) ON CONFLICT(tag_id) DO UPDATE SET tier2_json=excluded.tier2_json",
            (tag_id, json.dumps(tier2_record)),
        )
        self.connection.commit()

    def get_tier2(self, tag_id: int) -> dict[str, object] | None:
        row = self.connection.execute("SELECT tier2_json FROM tags WHERE tag_id = ?", (tag_id,)).fetchone()
        return json.loads(row["tier2_json"]) if row else None
