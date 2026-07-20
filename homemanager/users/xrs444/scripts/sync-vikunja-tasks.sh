#!/usr/bin/env bash
# Generate a read-only mirror of the Vikunja "HomeProd" project into the
# Obsidian vault (Tasks/HomeProd.md), grouped by Kanban bucket, formatted as
# obsidian-tasks-plugin checkbox lines with category labels and a backlink.
#
# One-way, Vikunja -> vault. This file is regenerated on every run and is
# NOT meant to be hand-edited -- manage tasks in Vikunja (web/mobile, vja
# CLI, or the API), not in Obsidian. See the plan doc for why: the only
# two-way Obsidian<->Vikunja plugin uses an "Obsidian always wins" conflict
# model and doesn't respect buckets or non-default projects, which breaks
# multi-client management (user + Claude + Hermes-t).
set -euo pipefail

VIKUNJA_URL="${VIKUNJA_URL:-https://vikunja.xrs444.net}"
TOKEN_FILE="$HOME/.config/vja/token.json"
OUT_DIR="$HOME/Documents/obsidian/xrs444/Tasks"
OUT_FILE="$OUT_DIR/HomeProd.md"
PROJECT_TITLE="HomeProd"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "sync-vikunja-tasks: no token at $TOKEN_FILE (run 'vja' once to log in)" >&2
  exit 1
fi

TOKEN="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['token'])" "$TOKEN_FILE")"

mkdir -p "$OUT_DIR"

python3 - "$VIKUNJA_URL" "$TOKEN" "$OUT_FILE" "$PROJECT_TITLE" <<'PYEOF'
import json
import sys
import urllib.request
from datetime import datetime, timezone

base_url, token, out_file, project_title = sys.argv[1:5]
headers = {"Authorization": f"Bearer {token}"}


def api_get(path):
    req = urllib.request.Request(base_url + path, headers=headers)
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)


projects = api_get("/api/v1/projects")
project = next((p for p in projects if p["title"] == project_title), None)
if project is None:
    print(f"sync-vikunja-tasks: no project titled {project_title!r} found", file=sys.stderr)
    sys.exit(1)
project_id = project["id"]

views = api_get(f"/api/v1/projects/{project_id}/views")
kanban_view = next((v for v in views if v.get("view_kind") == "kanban"), views[0])

# The flat `bucket_id` field on a plain /tasks list is always 0 on this
# Vikunja version -- bucket membership is tracked per-view, not on the task
# itself. The view-scoped endpoint below returns buckets each carrying
# their own nested `tasks` array, which is the only reliable source for
# "which bucket is this task in" (confirmed 2026-07-20: vja edit
# --bucket-id and a flat PATCH both silently no-op the deprecated field;
# only POST .../buckets/{bucket}/tasks actually moves a task).
bucket_groups = api_get(f"/api/v1/projects/{project_id}/views/{kanban_view['id']}/tasks")

by_bucket = {g["title"]: g.get("tasks") or [] for g in bucket_groups}
bucket_order = [g["title"] for g in bucket_groups]
task_count = sum(len(v) for v in by_bucket.values())

lines = [
    "---",
    "generated: true",
    f"generated_at: {datetime.now(timezone.utc).isoformat()}",
    "---",
    "",
    f"# {project_title} tasks",
    "",
    "> **Generated / read-only — manage tasks in Vikunja** (web, mobile, or `vja`), not here.",
    "> This file is overwritten every sync run; edits made here will be lost.",
    "",
]

for bucket_title in bucket_order:
    bucket_tasks = by_bucket.get(bucket_title, [])
    if not bucket_tasks:
        continue
    lines.append(f"## {bucket_title}")
    lines.append("")
    for t in sorted(bucket_tasks, key=lambda x: x.get("position", 0)):
        box = "x" if t.get("done") else " "
        labels = t.get("labels") or []
        tags = " ".join(f"#{lbl['title'].replace(' ', '-')}" for lbl in labels)
        due = ""
        if t.get("due_date") and not t.get("due_date", "").startswith("0001"):
            due = f" 📅 {t['due_date'][:10]}"
        link = f"[↗]({base_url}/tasks/{t['id']})"
        title = t["title"]
        lines.append(f"- [{box}] {title}{due} {tags} {link}".rstrip())
    lines.append("")

with open(out_file, "w") as f:
    f.write("\n".join(lines))

print(f"sync-vikunja-tasks: wrote {task_count} tasks to {out_file}")
PYEOF
