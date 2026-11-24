# 使い方は `make`（引数なし）で一覧が出る。

# elan が入れた lean / lake を、シェルの設定を変えなくても見つけられるようにする。
export PATH := $(HOME)/.elan/bin:$(PATH)

TLC := scripts/tlc.sh

.DEFAULT_GOAL := help
.PHONY: help doctor setup-tla tla \
        tla-lost-update tla-lost-update-fixed tla-deadlock tla-deadlock-fixed tla-stock \
        lean lean-broken lean-mathlib clean

help:
	@echo "準備"
	@echo "  make doctor                 要る道具（java, lake）が入っているかを調べる"
	@echo "  make setup-tla              TLA+ の道具（tla2tools.jar）を tools/ に落とす"
	@echo ""
	@echo "TLA+（設計の模型を、総当たりで検査する）"
	@echo "  make tla                    全部の例を検査して、期待どおりかを表にする"
	@echo "  make tla-lost-update        例1 壊れている版: 更新が消える手順が出る"
	@echo "  make tla-lost-update-fixed  例1 直した版"
	@echo "  make tla-deadlock           例2 壊れている版: デッドロックする手順が出る"
	@echo "  make tla-deadlock-fixed     例2 直した版"
	@echo "  make tla-stock              例3 在庫の引き当て"
	@echo ""
	@echo "Lean（定理と証明を、一歩ずつ検査する）"
	@echo "  make lean                   Mathlib なしの例を検査する（数秒）"
	@echo "  make lean-broken            わざと壊した証明に、Lean がどう怒るかを見る"
	@echo "  make lean-mathlib           Mathlib を使う例を検査する（初回は約 7GB を取得する）"

doctor:
	@command -v java >/dev/null 2>&1 \
	  && echo "java : $$(java -version 2>&1 | head -1)" \
	  || echo "java : 見つかりません（TLA+ に要る。README の「道具の入れ方」へ）"
	@test -f tools/tla2tools.jar \
	  && echo "TLA+ : tools/tla2tools.jar あり" \
	  || echo "TLA+ : tools/tla2tools.jar がありません（make setup-tla で落とす）"
	@command -v lake >/dev/null 2>&1 \
	  && echo "lake : $$(cd lean/basics && lake --version 2>&1 | head -1)" \
	  || echo "lake : 見つかりません（Lean に要る。README の「道具の入れ方」へ）"

setup-tla:
	@scripts/setup-tla.sh

# ---- TLA+ ----

tla: setup-tla
	@scripts/tla-all.sh

# 壊れている版は TLC がエラーを見つけて 0 以外で終わる。それが見たい結果なので `|| true` で受ける。
tla-lost-update: setup-tla
	@$(TLC) tla/01_lost_update/LostUpdate || true

tla-lost-update-fixed: setup-tla
	@$(TLC) tla/01_lost_update/LostUpdateFixed

tla-deadlock: setup-tla
	@$(TLC) tla/02_deadlock/Deadlock || true

tla-deadlock-fixed: setup-tla
	@$(TLC) tla/02_deadlock/DeadlockFixed

tla-stock: setup-tla
	@$(TLC) tla/03_stock/Stock

# ---- Lean ----

# Mathlib なし。初回は elan が lean-toolchain に書いた版の Lean を自動で取ってくる。
lean:
	cd lean/basics && lake build

# 壊した証明は lake build の対象外。ファイルを1つだけ Lean に読ませる。
# エラーが出るのが期待どおりなので、もし通ってしまったら失敗にする。
lean-broken:
	@cd lean/basics && if lake env lean broken/SumFormulaBroken.lean; then \
	  echo "壊したはずの証明が通ってしまいました"; exit 1; \
	else \
	  echo ""; echo "↑ Lean がエラーを出しました（これが期待どおり）"; \
	fi

# Mathlib あり。`lake exe cache get` がビルド済みの Mathlib を取ってくる（自分でビルドすると数時間かかる）。
lean-mathlib:
	cd lean/with-mathlib && lake exe cache get && lake build

# ビルドの成果物と、落とした道具を消す（Mathlib の約 7GB もここで消える）。
clean:
	rm -rf .tlc tools lean/basics/.lake lean/with-mathlib/.lake
