/-
# 三平方の定理

直角三角形で、直角をはさむ2辺の長さを a, b、斜辺の長さを c とすると  a² + b² = c²。

3通りで書く。
  1. 座標で置いて、自分で示す
  2. ベクトルで置いて、自分で示す
  3. Mathlib にすでにある三平方の定理を使う
-/
module                      -- Lean の新しいモジュール方式でこのファイルを扱う、という宣言（Mathlib を読むときは付ける。無いと警告が出る）
import Mathlib              -- Mathlib の全部を読み込む

/-! ## 1. 座標で置いて、自分で示す -/

-- 平面の点を、実数の組 (x, y) で表す。`ℝ × ℝ` は「実数2つの組」。
-- 点 p の x 座標は `p.1`、y 座標は `p.2` と書く。
-- 2点 p, q の距離の2乗を、座標の差の2乗の和として定義する。
def distSq (p q : ℝ × ℝ) : ℝ :=
  (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2

-- まず一番素朴な形。直角の頂点を原点 (0, 0) に、2辺を x 軸と y 軸に置く。
-- A = (a, 0), B = (0, b) とすると、斜辺 AB の長さの2乗は a² + b²。
theorem pythagoras_on_axes (a b : ℝ) : distSq (a, 0) (0, b) = a ^ 2 + b ^ 2 := by
  unfold distSq             -- distSq を定義で開く →  ((a, 0).1 - (0, b).1) ^ 2 + ((a, 0).2 - (0, b).2) ^ 2 = a ^ 2 + b ^ 2
  simp                      -- `simp` は決まりきった簡単化をまとめてやる。組から成分を取り出し、- 0 や 0 - を整理する
                            -- →  (a - 0)² + (0 - b)² が a² + b² に整理されて、両辺が一致する

-- 次に、三角形がどこにどんな向きで置かれていてもよい形。
-- 3点 A, B, C があり、C のところが直角だとする。
-- 「C が直角」は、C から A へのベクトルと C から B へのベクトルの内積が 0、と書ける（h がその前提）。
-- このとき AB² = AC² + BC²。
theorem pythagoras_coord (A B C : ℝ × ℝ)
    (h : (A.1 - C.1) * (B.1 - C.1) + (A.2 - C.2) * (B.2 - C.2) = 0) :
    distSq A B = distSq A C + distSq B C := by
  -- 鍵になる等式: AB² = AC² + BC² - 2 × (内積)。余弦定理を座標で書いたものにあたる。
  have key : distSq A B
      = distSq A C + distSq B C
        - 2 * ((A.1 - C.1) * (B.1 - C.1) + (A.2 - C.2) * (B.2 - C.2)) := by
    unfold distSq           -- distSq を定義で開くと、両辺は座標の多項式になる
    ring                    -- 展開して整理すれば両辺は同じ式
  rw [key]                  -- ゴールの左辺 distSq A B を key の右辺で置き換える
  rw [h]                    -- 前提 h で、内積の部分を 0 に置き換える →  ... - 2 * 0 = ...
  ring                      -- 2 * 0 = 0 を消せば両辺は同じ

/-
注意: 上の2つは「距離の2乗は、座標の差の2乗の和」を定義として出発している。
この定義そのものが三平方の定理（x 方向と y 方向が直角）を織り込んでいる。
示したのは、「軸に沿っていない、斜めに置かれた直角三角形でも a² + b² = c² が成り立つ」こと。
-/

/-! ## 2. ベクトルで置いて、自分で示す -/

-- 直角の頂点から出る2辺を、ベクトル u, v とする。斜辺は u - v。
--   `EuclideanSpace ℝ (Fin 2)`  平面（実数2つを成分に持つベクトルの集まり）
--   `‖u‖`                        ベクトル u の長さ
--   `inner ℝ u v`               u と v の内積。0 なら直交している
-- 定理: u と v が直交するなら、‖u - v‖² = ‖u‖² + ‖v‖²。
theorem pythagoras_vec (u v : EuclideanSpace ℝ (Fin 2)) (h : inner ℝ u v = 0) :
    ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2 := by
  rw [norm_sub_sq_real]     -- Mathlib の補題「‖u - v‖² = ‖u‖² - 2 × (u と v の内積) + ‖v‖²」で左辺を書き換える
                            -- （(a - b)² = a² - 2ab + b² のベクトル版）
  rw [h]                    -- 前提 h で内積を 0 に置き換える →  ‖u‖² - 2 * 0 + ‖v‖² = ‖u‖² + ‖v‖²
  ring                      -- 2 * 0 = 0 を消せば両辺は同じ

-- 3点 A, B, C の形でも書ける。C が直角なら AB² = AC² + BC²。`dist A B` は2点の距離。
theorem pythagoras_points (A B C : EuclideanSpace ℝ (Fin 2))
    (h : inner ℝ (A - C) (B - C) = 0) :
    dist A B ^ 2 = dist A C ^ 2 + dist B C ^ 2 := by
  rw [dist_eq_norm, dist_eq_norm, dist_eq_norm]   -- 3つの距離を、差のベクトルの長さに書き換える: dist A B = ‖A - B‖ など
  have key : A - B = (A - C) - (B - C) := by      -- 斜辺のベクトルは、2辺のベクトルの差
    abel                                          -- `abel` は足し算・引き算だけの等式を整理して示す
  rw [key]                                        -- ゴールの A - B を (A - C) - (B - C) に置き換える
  exact pythagoras_vec (A - C) (B - C) h          -- 上で示したベクトル版に u = A - C, v = B - C を入れれば、ゴールそのもの

/-! ## 3. Mathlib にすでにある三平方の定理 -/

/-
Mathlib には、三平方の定理が「逆も込み」で入っている。

  名前:  EuclideanGeometry.dist_sq_eq_dist_sq_add_dist_sq_iff_angle_eq_pi_div_two
  場所:  Mathlib/Geometry/Euclidean/Angle/Unoriented/RightAngle.lean
  中身:  dist p₁ p₃ * dist p₁ p₃ = dist p₁ p₂ * dist p₁ p₂ + dist p₃ p₂ * dist p₃ p₂
           ↔  ∠ p₁ p₂ p₃ = π / 2
         （p₂ の角が直角であることと、a² + b² = c² が成り立つことは同じ。`↔` は「同値」）

平面に限らず、何次元のユークリッド空間でも使える形で書かれている。
ベクトル版は次の名前で、Mathlib/Analysis/InnerProductSpace/Basic.lean にある。

  norm_sub_sq_eq_norm_sq_add_norm_sq_iff_real_inner_eq_zero
  norm_add_sq_eq_norm_sq_add_norm_sq_iff_real_inner_eq_zero

手元でソースを読むには、ビルドのあと .lake/packages/mathlib/ の下の同じパスを開く。
-/

open EuclideanGeometry in   -- 角度の記号 ∠ を、次の1つの example の中で使えるようにする
-- 使ってみる: 角 ACB が直角（π/2 ラジアン = 90 度）なら、AB² = AC² + BC²。
example (A B C : EuclideanSpace ℝ (Fin 2)) (h : ∠ A C B = Real.pi / 2) :
    dist A B * dist A B = dist A C * dist A C + dist B C * dist B C :=
  -- Mathlib の定理に p₁ = A, p₂ = C, p₃ = B を入れ、`.mpr` で「↔ の右から左へ」向きを取り出して、h を渡す。
  (dist_sq_eq_dist_sq_add_dist_sq_iff_angle_eq_pi_div_two A C B).mpr h
