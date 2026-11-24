#!/bin/sh
# TLA+ の例を全部走らせ、それぞれが「期待どおりの結果」になったかを表にする。
# 壊れている版は、TLC がエラーを見つけるのが期待どおり。
# TLC の出力そのものを読みたいときは、make tla-lost-update などで1つずつ走らせる。
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

# check <仕様のパス> <期待する終了コード> <期待する結果の説明>
#   TLC の終了コード: 0 = エラーなし, 12 = 不変条件が破れた, 11 = デッドロック
check() {
  OUT="$("$ROOT/scripts/tlc.sh" "$ROOT/tla/$1" 2>&1)"
  CODE=$?
  STATES="$(printf '%s\n' "$OUT" | sed -n 's/.* \([0-9]*\) distinct states found.*/\1/p')"
  if [ "$CODE" -eq "$2" ]; then
    printf '  期待どおり  %-32s %s（調べた状態 %s 個）\n' "$1" "$3" "$STATES"
  else
    printf '  ちがう結果  %-32s 終了コード %s（期待は %s: %s）\n' "$1" "$CODE" "$2" "$3"
    printf '%s\n' "$OUT" | sed 's/^/      | /'
    FAILED=1
  fi
}

echo "TLA+ の例を TLC で検査します"
check 01_lost_update/LostUpdate      12 "不変条件 NoLostUpdate が破れる"
check 01_lost_update/LostUpdateFixed  0 "エラーなし"
check 02_deadlock/Deadlock           11 "デッドロックが見つかる"
check 02_deadlock/DeadlockFixed       0 "エラーなし"
check 03_stock/Stock                  0 "エラーなし"
exit $FAILED
