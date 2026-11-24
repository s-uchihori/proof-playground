#!/bin/sh
# TLA+ の仕様の、コメントと空行を除いた行数を数える（docs/tla/README.md の 1 節で使う）。
#   使い方: examples/count-lines.sh <file.tla>
# (* ... *) で囲んだ複数行のコメント（行末の *) で閉じる）と、\* で始まる行と、空行を数えない。
awk '
  /\(\*/ { inb = 1 }
  inb    { if (/\*\)[[:space:]]*$/) inb = 0; next }
  /^[[:space:]]*(\\\*|$)/ { next }
  { c++ }
  END { print c " 行（コメントと空行を除く）" }
' "$1"
