/-
# わざと壊した証明（ビルドの対象外）

Basics/SumFormula.lean の証明から、帰納法の仮定を使う1行 `rw [ih]` を消したもの。
Lean がどこでどう怒るかを見るためのファイルで、`lake build` の対象には入っていない。

  見る方法:  make lean-broken   （リポジトリの直下で）

名前が本物とぶつからないように、全体を `namespace Broken` で囲んである。
-/
namespace Broken

def sumTo : Nat → Nat
  | 0 => 0
  | n + 1 => sumTo n + (n + 1)

theorem two_mul_sumTo (n : Nat) : 2 * sumTo n = n * (n + 1) := by
  induction n with
  | zero =>
    rfl
  | succ k ih =>
    rw [sumTo]
    rw [Nat.mul_add]
    -- rw [ih]            ← 本物にはこの行がある。帰納法の仮定を使うのを「忘れた」
    rw [← Nat.add_mul]    -- ← Lean はここで止まる
    rw [Nat.mul_comm]

end Broken
