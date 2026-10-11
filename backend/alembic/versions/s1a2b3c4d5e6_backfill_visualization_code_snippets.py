"""backfill_visualization_code_snippets

Revision ID: s1a2b3c4d5e6
Revises: r1a2b3c4d5e6
Create Date: 2026-10-11 02:25:00.000000

"""
from typing import Sequence, Union
import json
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 's1a2b3c4d5e6'
down_revision: Union[str, None] = 'r1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    lessons = conn.execute(sa.text("SELECT id, content_json FROM lessons WHERE content_type = 'VISUALIZATION'")).fetchall()
    
    for row in lessons:
        lesson_id, raw_content = row[0], row[1]
        if not raw_content:
            continue
        
        content = raw_content if isinstance(raw_content, dict) else json.loads(raw_content)
        changed = False

        if "code_snippets" not in content or not isinstance(content.get("code_snippets"), dict):
            single_code = content.get("code_snippet") or ""
            content["code_snippets"] = {"python": single_code} if single_code else {}
            changed = True

        if "default_language" not in content:
            content["default_language"] = "python"
            changed = True

        if "line_maps" not in content or not isinstance(content.get("line_maps"), dict):
            single_line_map = content.get("line_map") or {}
            content["line_maps"] = {"python": single_line_map} if single_line_map else {}
            changed = True

        if changed:
            conn.execute(
                sa.text("UPDATE lessons SET content_json = :content WHERE id = :id"),
                {"content": json.dumps(content), "id": lesson_id}
            )


def downgrade() -> None:
    pass
