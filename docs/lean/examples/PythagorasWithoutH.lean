/-
# 三平方の定理（ベクトル版）から `rw [h]` の行を消したもの（docs/lean/README.md の理解度チェック 問2 で使う）

前提 h（u と v は直交する）を使わないと、証明が通らないことを確かめる。
-/
module
import Mathlib

theorem pythagoras_vec_without_h (u v : EuclideanSpace ℝ (Fin 2)) (h : inner ℝ u v = 0) :
    ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2 := by
  rw [norm_sub_sq_real]
  ring
