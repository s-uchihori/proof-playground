/-
# 相加平均と相乗平均の不等式（2数）

  x, y が 0 以上のとき  √(xy) ≤ (x + y) / 2

もとになるのは「実数の2乗は 0 以上」: (a - b)² ≥ 0。
-/
module                      -- Lean の新しいモジュール方式でこのファイルを扱う、という宣言（Mathlib を読むときは付ける。無いと警告が出る）
import Mathlib              -- Mathlib の全部を読み込む

-- まず、ルートの無い形。どんな実数 a, b でも ab ≤ (a² + b²) / 2。
theorem mul_le_half_sq_add_sq (a b : ℝ) : a * b ≤ (a ^ 2 + b ^ 2) / 2 := by
  have h : 0 ≤ (a - b) ^ 2 :=                   -- 出発点: (a - b)² は 0 以上
    sq_nonneg (a - b)                           -- Mathlib の定理「2乗は 0 以上」に a - b を入れる
  have h2 : (a - b) ^ 2 = a ^ 2 - 2 * (a * b) + b ^ 2 := by
    ring                                        -- 展開の等式は ring で示す
  rw [h2] at h                                  -- h の (a - b)² を展開した形に置き換える。h : 0 ≤ a² - 2ab + b²
  linarith                                      -- `linarith` は、手元の一次不等式を足し引きして結論を出す
                                                -- （a², b², ab をそれぞれ1つの文字と見れば、h を移項して 2 で割るだけ）

-- 本題。x, y が 0 以上のとき √(xy) ≤ (x + y) / 2。
-- hx, hy は「x は 0 以上」「y は 0 以上」という前提に付けた名前。
theorem am_gm (x y : ℝ) (hx : 0 ≤ x) (hy : 0 ≤ y) : √(x * y) ≤ (x + y) / 2 := by
  rw [Real.sqrt_le_iff]     -- Mathlib の補題「√s ≤ t  ⇔  0 ≤ t かつ s ≤ t²」でルートを外す
                            -- →  ゴール: 0 ≤ (x + y) / 2  ∧  x * y ≤ ((x + y) / 2) ^ 2
  constructor               -- 「かつ」（∧）のゴールを、2つのゴールに分ける
  · positivity              -- 【1つ目】0 ≤ (x + y) / 2。`positivity` は hx, hy を見て「0 以上」を示す
  · have h : 0 ≤ (x - y) ^ 2 :=                 -- 【2つ目】x * y ≤ ((x + y) / 2)²。ここでも (x - y)² ≥ 0 から始める
      sq_nonneg (x - y)
    have h2 : ((x + y) / 2) ^ 2 - x * y = (x - y) ^ 2 / 4 := by
      ring                                      -- (右辺 − 左辺) を計算すると (x - y)² / 4 になる
    linarith                                    -- h と h2 から、右辺 − 左辺 ≥ 0 が出る
