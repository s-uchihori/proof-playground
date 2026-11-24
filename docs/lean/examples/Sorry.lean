/-
# 証明を `sorry` で飛ばしても、ビルドは失敗しない（docs/lean/README.md の 1 節で使う）

`sorry` は「この証明はあとで書く」という仮置き。Lean は警告を出すが、エラーにはしない。
-/
theorem not_proved_yet (n : Nat) : 2 * n = n + n := by
  sorry
