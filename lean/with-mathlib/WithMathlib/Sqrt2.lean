/-
# √2 は無理数（背理法）

高校で習う証明をそのまま書く。
  √2 = m / n（これ以上約分できない分数）と書けたとする。
  2乗して分母を払うと m² = 2n²。
  すると m² は偶数、だから m も偶数で、m = 2k と書ける。
  代入すると 4k² = 2n²、つまり n² = 2k²。だから n も偶数。
  m も n も偶数なら 2 で約分できる。約分できないとしたことに反する。

ここでは、ルートや分数を持ち出さず、自然数だけの形で示す:
「互いに素（共通の約数が 1 だけ）な自然数 m, n で m² = 2n² となるものは存在しない」。
-/
module                      -- Lean の新しいモジュール方式でこのファイルを扱う、という宣言（Mathlib を読むときは付ける。無いと警告が出る）
import Mathlib              -- Mathlib の全部を読み込む

-- `¬` は「〜でない」、`∃ m n : ℕ, ...` は「... を満たす自然数 m, n が存在する」、`∧` は「かつ」。
-- `Nat.Coprime m n` は「m と n は互いに素」（最大公約数が 1）。
theorem no_coprime_sq_eq_two_mul_sq :
    ¬ ∃ m n : ℕ, Nat.Coprime m n ∧ m ^ 2 = 2 * n ^ 2 := by
  intro ⟨m, n, hcop, h⟩     -- 背理法の始まり: そういう m, n があったと仮定して、中身に名前を付ける
                            --   hcop : m と n は互いに素     h : m ^ 2 = 2 * n ^ 2
                            -- ゴールは False（矛盾）になる。これを示せば証明終わり
  have hm2 : 2 ∣ m ^ 2 :=   -- m² は 2 で割り切れる（`a ∣ b` は「a は b を割り切る」。記号は \| で打つ縦棒で、キーボードの | とは別）
    ⟨n ^ 2, h⟩              --   「m² = 2 × (何か)」の「何か」として n² を出す。その証拠が h
  have hm : 2 ∣ m :=        -- だから m も 2 で割り切れる
    Nat.Prime.dvd_of_dvd_pow Nat.prime_two hm2
                            --   Mathlib の定理「素数 p が a の累乗を割り切るなら、p は a を割り切る」に、
                            --   「2 は素数」（Nat.prime_two）と hm2 を渡す
  obtain ⟨k, hk⟩ := hm      -- 「m は 2 で割り切れる」から、m = 2 * k となる k を取り出す。hk : m = 2 * k
  rw [hk] at h              -- h の m を 2 * k に置き換える。h : (2 * k) ^ 2 = 2 * n ^ 2
  have h4 : 2 * (2 * k ^ 2) = 2 * n ^ 2 := by
    rw [← h]                -- 右辺の 2 * n ^ 2 を、h を逆向きに使って (2 * k) ^ 2 に戻す →  2 * (2 * k ^ 2) = (2 * k) ^ 2
    ring                    -- 両辺とも 4k²
  have h' : n ^ 2 = 2 * k ^ 2 := by
    omega                   -- h4 の両辺を 2 で割る（k², n² をそれぞれ1つの文字と見れば一次式の話）
  have hn2 : 2 ∣ n ^ 2 :=   -- n² も 2 で割り切れる
    ⟨k ^ 2, h'⟩
  have hn : 2 ∣ n :=        -- だから n も 2 で割り切れる（m のときと同じ理屈）
    Nat.Prime.dvd_of_dvd_pow Nat.prime_two hn2
  have h2m : 2 ∣ m :=       -- m が 2 で割り切れることを、もう一度手元に置く（さっき k を取り出すのに使ってしまったので）
    ⟨k, hk⟩
  have hgcd : 2 ∣ Nat.gcd m n :=  -- 2 は m も n も割り切るので、m と n の最大公約数も割り切る
    Nat.dvd_gcd h2m hn
  rw [hcop] at hgcd         -- 互いに素なので最大公約数は 1。置き換えると hgcd : 2 ∣ 1
  omega                     -- 2 は 1 を割り切らない。矛盾が出たので証明終わり

/-
Mathlib には、実数の √2 についての定理がそのまま入っている。

  名前:  irrational_sqrt_two
  場所:  Mathlib/NumberTheory/Real/Irrational.lean
  中身:  Irrational √2
         （`Irrational x` は「x はどんな有理数とも等しくない」）
-/
example : Irrational (√2 : ℝ) :=
  irrational_sqrt_two       -- Mathlib の定理をそのまま当てはめる
