/-
# 三平方の定理（ベクトル版）の証明で、各行のあとのゴールを表示する（docs/lean/README.md の 2 節で使う）

lean/with-mathlib/WithMathlib/Pythagoras.lean の pythagoras_vec と同じ証明に、
`trace_state`（その時点の前提とゴールを表示する命令）を挟んだだけのもの。証明の中身は変えていない。
-/
module
import Mathlib

theorem pythagoras_vec_traced (u v : EuclideanSpace ℝ (Fin 2)) (h : inner ℝ u v = 0) :
    ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2 := by
  trace_state
  rw [norm_sub_sq_real]
  trace_state
  rw [h]
  trace_state
  ring
