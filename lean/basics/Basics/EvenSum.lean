/-
# 偶数どうしの和は偶数

「m と n が偶数なら m + n も偶数」。
偶数は無限にあるので、総当たりでは示せない。文字のまま理屈で示す。
-/

-- 「n は偶数である」を、自分で定義する: ある自然数 k があって n = 2 * k と書ける。
-- `Prop` は「命題（真か偽かを問えるもの）」の型。`∃ k, ...` は「... を満たす k が存在する」。
def IsEven (n : Nat) : Prop := ∃ k, n = 2 * k

-- 具体例: 6 は偶数。「存在する」を示すには、実物（ここでは k = 3）を出せばよい。
example : IsEven 6 := by
  exists 3                  -- k として 3 を出す。残るゴール 6 = 2 * 3 は計算で確かめられ、自動で閉じる

-- 定理: 偶数どうしの和は偶数。
-- hm は「m は偶数」という前提、hn は「n は偶数」という前提に付けた名前。
theorem isEven_add (m n : Nat) (hm : IsEven m) (hn : IsEven n) : IsEven (m + n) := by
  obtain ⟨a, ha⟩ := hm      -- 前提 hm「m = 2 * k となる k がある」から、その k を a として取り出す。ha : m = 2 * a
  obtain ⟨b, hb⟩ := hn      -- 同じく hn から b を取り出す。hb : n = 2 * b
                            -- ゴール:  IsEven (m + n)  つまり  ∃ k, m + n = 2 * k
  exists a + b              -- k として a + b を出す →  ゴール: m + n = 2 * (a + b)
  rw [ha, hb]               -- m と n を、ha と hb で書き換え →  2 * a + 2 * b = 2 * (a + b)
  rw [Nat.mul_add]          -- 右辺を分配法則で展開 →  2 * a + 2 * b = 2 * a + 2 * b
                            -- 両辺が同じ形になったので、rw が自動で証明を閉じる

-- 使ってみる: 4 と 6 は偶数なので、4 + 6 も偶数。
example : IsEven (4 + 6) := by
  apply isEven_add          -- 上の定理を当てはめる。「4 は偶数」「6 は偶数」の2つが新しいゴールになる
  · exists 2                -- 4 = 2 * 2
  · exists 3                -- 6 = 2 * 3
