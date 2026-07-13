---
name: notion-experiment-log
description: Use this skill whenever the user wants to record, log, update, or look up an experiment result in the Notion 実験ログ database (part of the "Semantic Gesture Enhancement via Video Generation" project). Triggers include phrases like "実験結果を記録して", "この学習をNotionに残して", "log this run", "実験ログに追加", "先週のデータ生成の実験を教えて", or when the user pastes a training/generation command, an output path, or a checkpoint directory and asks to save it. Also use when the user asks which experiments were run on a given server, with a given tag (データ生成 / ジェスチャー生成学習 / 評価 / 前処理 / デバッグ), or in a given date range. Do NOT use for general Notion note-taking unrelated to experiments.
---

# Logging Experiments to the Notion 実験ログ Database

Record each experiment run — what was executed and what came out of it — as a single row in the 実験ログ database via the Notion MCP.

## Target Database

| Item | Value |
|---|---|
| Data source ID | `collection://678b4c5c-df25-4d28-9be3-d2e4e189f016` |
| Database URL | https://app.notion.com/p/d5636376f3df4663bfe675dae11c5281 |
| Parent page | 実験結果 (`39cdf360-737c-81e3-9533-cc81030d1223`) |
| Project | Semantic Gesture Enhancement via Video Generation |

## Schema

Property names and select/tag values are the literal keys in Notion — keep them in Japanese exactly as written below.

| Property | Type | Description |
|---|---|---|
| 実験内容 | title | **Required.** One line describing what was tested. Example: `DiT 300ep / BEAT2 + 合成データ 20%` |
| 実験結果のパス | text | **Absolute path** to the output directory or checkpoint |
| サーバー名 | select | Machine the run happened on — resolve it from `hostname`, per the "Resolving サーバー名" section below. Adding a new option is fine if the name doesn't exist yet |
| 実験日時 | date | When the experiment ran. Set `is_datetime = 1` to include the time of day |
| 実験タグ | multi_select | `データ生成` / `ジェスチャー生成学習` / `評価` / `前処理` / `デバッグ` |
| ステータス | select | `実行中` / `完了` / `失敗` / `中断` |
| 結果サマリ | text | Quantitative results and impressions. Example: `FGD 12.4 (baseline 15.1), diversity ↓` |
| 実験ID | auto | Auto-numbered (`EXP-n`). **Never write to it** |

## Recording Procedure

1. Extract each field from what the user said, the command they pasted, or the logs.
2. Resolve サーバー名 automatically (see below) when the run happened on this machine.
3. Ask back **only** about whichever of **実験内容 / 実験結果のパス / サーバー名 / 実験日時 / 実験タグ** is still missing. If everything is there, just write the row without asking.
   - If no date/time was given, the current time is acceptable — mention that you did so.
   - If the status is unclear, assume `完了`.
4. Create one page with `Notion:notion-create-pages`.
5. Return the resulting URL to the user.

## Resolving サーバー名

The machines in this lab are registered in `~/.ssh/config` under `Host` aliases that *are* the machine names (`dao`, `hinton`, `lecun`, …). The local `hostname` matches the corresponding alias up to letter case (e.g. `Dao` → `dao`), so resolve the name by lowercasing `hostname` and looking it up in the config:

```bash
h=$(hostname | tr 'A-Z' 'a-z')
sed -n 's/^[[:space:]]*[Hh][Oo][Ss][Tt][[:space:]]\+//p' ~/.ssh/config | tr ' \t' '\n\n' | grep -ixF "$h"
```

(Deliberately written without awk positional fields — a `$1` in this file gets eaten by the skill's argument interpolation, silently corrupting the command.)

- If it prints an alias, use that as サーバー名.
- If it prints nothing, the machine is not in the ssh config. Fall back to the raw `hostname`, and tell the user which value you used so they can correct it.

**Do not try to match by IP address.** Claude Code often runs inside a Docker container, where `hostname -I` returns a bridge address (`172.17.0.x`) rather than the host's LAN address, and the global IP is the shared campus egress IP — neither one identifies the machine.

Only auto-fill サーバー名 this way when the experiment actually ran **on this machine**. If the user is logging a run from a different server (e.g. pasting a log fetched from elsewhere), ask which server it was instead of assuming the local one.

### Calling create-pages

```json
{
  "parent": {"data_source_id": "678b4c5c-df25-4d28-9be3-d2e4e189f016"},
  "pages": [{
    "properties": {
      "実験内容": "DiT 300ep / BEAT2 + 合成データ 20%",
      "実験結果のパス": "/home/user/exp/gesture_dit/2026-07-13_run03",
      "サーバー名": "gpu-server-01",
      "date:実験日時:start": "2026-07-13T14:30:00+09:00",
      "date:実験日時:is_datetime": 1,
      "実験タグ": "[\"ジェスチャー生成学習\"]",
      "ステータス": "完了",
      "結果サマリ": "FGD 12.4 (baseline 15.1)"
    },
    "content": "## 設定\n\n```bash\npython train.py --config configs/dit.yaml --epochs 300\n```\n\n## 結果\n\n| metric | value | baseline |\n|---|---|---|\n| FGD | 12.4 | 15.1 |\n\n## メモ\n\n- 所感をここに\n"
  }]
}
```

**Formatting notes:**
- 実験タグ (multi_select) must be passed as a **JSON array encoded in a string**: `"[\"データ生成\", \"評価\"]"`
- Dates must be **expanded** into `date:実験日時:start` / `date:実験日時:is_datetime`. Writing to a key literally named `実験日時` does not work
- 実験ID is auto_increment. Passing it causes an error
- Put the details (full command, hyperparameter table, metrics table, impressions) in the **page body (`content`)**, not in properties

### Adding a new サーバー名 option

サーバー名 is a `select`, and Notion **rejects the whole page creation with a 400** if the value isn't already one of its options. A machine that has never been logged before must be added to the schema *first*:

```
Notion:notion-update-data-source
  data_source_id: 678b4c5c-df25-4d28-9be3-d2e4e189f016
  statements: ALTER COLUMN "サーバー名" SET SELECT('local', 'dao', 'hinton':blue)
```

- `ALTER COLUMN ... SET` **replaces the entire option list** — re-list every existing option or they are dropped. Check the current list first (the update tool echoes the full schema back).
- Do **not** attach a color to an option that already exists (`'local':gray`) — it errors with "Cannot update color of select with name". Colors are only for options being added.
- This is a schema change to a shared database, so **confirm with the user before running it**.

## Searching and Updating

- **Search**: send SQL to `Notion:notion-query-data-sources`.
  ```sql
  SELECT * FROM "collection://678b4c5c-df25-4d28-9be3-d2e4e189f016"
  WHERE "実験タグ" LIKE '%ジェスチャー生成学習%'
  ORDER BY "date:実験日時:start" DESC LIMIT 10
  ```
- **Update** (e.g. 実行中 → 完了): locate the page with `Notion:notion-search` or the query above, then call `Notion:notion-update-page`.

## Principles

- Do not paper over gaps with blank fields. If a path or server name is unknown, **ask instead of guessing**.
- When asked to log several experiments at once, pass them together in the `pages` array (up to 100 per call).
- If a write would overwrite an existing experiment, confirm with the user whether to create a new row or update the existing one.
