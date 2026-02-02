# Obsidian Claude Workflow

ObsidianとAlfredを統合し、Daily note、タスク管理、作業時間トラッキングを効率化するワークフローです。

## 機能

| コマンド | 説明 |
|---------|------|
| `memo [text]` | Daily noteにクイックメモを追加 |
| `task [text]` | 新しいタスクを作成（翌日予定） |
| `start [text]` | 作業トラッキング開始 |
| `end` | 作業トラッキング終了、所要時間を計算 |
| `brief` | 朝のブリーフィング生成 |
| `review` | 1日の振り返り生成 |

## 必要条件

- macOS
- [Alfred](https://www.alfredapp.com/) (Powerpack)
- [Obsidian](https://obsidian.md/)
- [gcalcli](https://github.com/insanum/gcalcli) (briefとreview機能用)

## インストール

```bash
git clone https://github.com/yourusername/obsidian-claude-workflow.git
cd obsidian-claude-workflow
./install.sh
```

インストール後、Alfredを再起動してください。

## 設定

スクリプト内のVault パスを環境に合わせて変更してください：

```bash
VAULT="$HOME/Dropbox/Sync/Obsidian"
```

### ディレクトリ構成

```
Obsidian/
├── Daily/           # Daily noteの保存先
├── Templates/
│   └── Daily        # Daily noteテンプレート
└── TaskNotes/
    └── Tasks/       # タスクファイルの保存先
```

## 使い方

### メモの追加

Alfredで `memo 買い物リストを作る` と入力すると、今日のDaily noteに時刻付きで追記されます。

```
- 14:30 買い物リストを作る
```

### タスクの作成

`task レポートを書く` で翌日予定のタスクファイルが作成されます。

### 作業時間トラッキング

1. `start 論文執筆` で作業開始
2. `end` で作業終了

Daily noteに以下のように記録されます：
```
- 10:00 🟢 開始: 論文執筆
- 12:30 🔴 終了: 論文執筆 (2h30m)
```

### 朝のブリーフィング

`brief` で今日の予定とフォーカスすべきタスクを生成します：

- 📅 今日のカレンダー予定
- 🔥 今日のフォーカス（優先度高・今日予定・期限切れタスク）
- 📊 タスクサマリー

### 1日の振り返り

`review` で1日の振り返りを生成します：

- 📅 今日の予定（実績）
- ✅ 完了したタスク
- ⏱️ 作業時間サマリー

## ライセンス

MIT

## 作者

Claude + Xinru
