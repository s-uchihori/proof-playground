/-
# 記号がどこで定義されているかを表示する（docs/lean/README.md の 2 節で使う）

三平方の定理の文に出てくる記号が、Lean 本体（`Init`、`Std` などで始まるモジュール）と、
数学ライブラリ Mathlib（`Mathlib` で始まるモジュール）のどちらで定義されているかを、Lean 自身に答えさせる。
-/
module
import Mathlib

open Lean Elab Command in
#eval show CommandElabM Unit from do
  let env ← getEnv
  for n in [``EuclideanSpace, ``Real, ``Norm, ``Inner, ``HPow] do
    match env.getModuleIdxFor? n with
    | some idx => logInfo m!"{n} は {env.header.moduleNames[idx.toNat]!} で定義"
    | none => logInfo m!"{n} はこのファイルで定義"
