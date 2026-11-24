/-
# Mathlib の「リーマン予想」の定義を表示する（docs/lean/README.md の冒頭と 5 節で使う）

リーマン予想を Lean で証明した、と言うときの「定理の文」は、Mathlib にあるこの定義。
ここでは表示するだけで、何も証明しない。
-/
module
import Mathlib

#print RiemannHypothesis
