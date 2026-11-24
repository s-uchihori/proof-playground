#!/bin/sh
# TLA+ の道具一式（tla2tools.jar。モデル検査器 TLC が入っている）を tools/ に落とす。
# tools/ は .gitignore 済み。Java 11 以上が要る。
set -eu
VERSION="v1.7.4"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAR="$ROOT/tools/tla2tools.jar"

# すでにあれば何もしない。
if [ -f "$JAR" ]; then
  exit 0
fi
mkdir -p "$ROOT/tools"
echo "tla2tools.jar ($VERSION) を落とします..."
curl -fL --progress-bar -o "$JAR.tmp" \
  "https://github.com/tlaplus/tlaplus/releases/download/$VERSION/tla2tools.jar"
mv "$JAR.tmp" "$JAR"
echo "置きました: tools/tla2tools.jar"
