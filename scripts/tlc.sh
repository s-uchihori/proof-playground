#!/bin/sh
# TLC（TLA+ のモデル検査器）で仕様を1つ検査する。
#   使い方: scripts/tlc.sh tla/01_lost_update/LostUpdate
#           （拡張子なしで渡す。同じ名前の .tla と .cfg を読む）
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAR="$ROOT/tools/tla2tools.jar"
if [ ! -f "$JAR" ]; then
  echo "tools/tla2tools.jar がありません。先に make setup-tla を実行してください。" >&2
  exit 2
fi
if ! command -v java >/dev/null 2>&1; then
  echo "java が見つかりません。README の「道具の入れ方」を見てください。" >&2
  exit 2
fi
SPEC="$1"
DIR="$(cd "$(dirname "$SPEC")" && pwd)"
NAME="$(basename "$SPEC" .tla)"
# TLC の作業ファイルは .tlc/ にまとめる（.gitignore 済み）。
META="$ROOT/.tlc/$NAME"
mkdir -p "$META"
cd "$DIR"
# -XX:+UseParallelGC  TLC が勧める GC の設定（付けないと警告が出る）
# -workers 1          1スレッドで動かす。出力が毎回同じ順番になる
exec java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC \
  -workers 1 -metadir "$META" \
  -config "$NAME.cfg" "$NAME.tla"
