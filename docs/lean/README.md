# Lean の「証明が通った」は何を保証したのか

> **想定読者**：Lean を知らないエンジニア。テストや CI の緑は見慣れていて、高校数学（ベクトルと内積、二次式の展開、三平方の定理）は覚えている前提で書いた（この前提は書き手の推測。理由は末尾の「この資料が置いた前提」）。
> **省いたもの**：道具の入れ方（[リポジトリの README](../../README.md#道具の入れ方)）、タクティクの網羅、Lean の型理論、リーマン予想そのものの数学。
> **所要時間**：15 分。手元で走らせなくても読める。
> **検証方法**：本文に引用したコードと出力は、`checks.json` のコマンドで再実行し、実物と照合している。リーマン予想の話は外部の出来事で、照合できない（出典と確認日は末尾）。

2026年11月20日、Levent Alpöge 氏がリーマン予想の証明を、Lean のコードとして公開しました（[本人の remark](https://alpo.ge/remark.pdf)）。
翌日、Lean FRO と Mathlib Initiative は共同声明で、約1700万行のこのコードが Lean の検査を通ること、そして定理の文が Mathlib（Lean の数学ライブラリ）にあるリーマン予想の定義と一致することを確かめた、と発表しました（[声明](https://leanprover-community.github.io/blog/posts/riemann-hypothesis/)）。
著者本人は remark で、人が読める形の長い文書は出さず、Lean だけを公開すると書いています。
読める人がいなくても、機械は検査できるわけです。AI が書いた大量のコードを、全部は読み切れないままレビューで受け取るのと、似た立場です。（2026-11-25 時点の情報。数学界での評価は、この資料では扱わない）

では、その「通った」は何を保証したのか。
そして、コミュニティが証明とは別に「定理の文」を確かめたのは、なぜか。

**Lean のビルドが通って保証されるのは、書いた定理の文・前提・定義から、結論まで、飛躍が一歩も無いことです。**
定理の文や定義が、言いたいことを正しく写しているかは保証されません。期待値を実装から計算してしまったテストが、緑でも何も確かめていないのと同じ構造です。
この資料は、それを三平方の定理で、高校の証明と並べて見せます。読み終えたら、「証明が通った」と聞いたときに、どこを読めばよいかが言えるようになります。

<details>
<summary>この資料の構成</summary>

| 節 | 役割 | 見せるもの | なぜ |
| --- | --- | --- | --- |
| 1 | 「通った」が何を保証し、何を保証しないかを言えるようにする | 通ったとき・壊れたときの出力、前提が成り立たない定理、`sorry` | 緑を過大に受け取るのが一番の落とし穴 |
| 2 | 短い証明を1行ずつ追えるようにする | 三平方の定理の、高校の証明と Lean の証明の対応、各行のあとのゴール | 証明を読めないと、何を示したかも読めない |
| 3 | 定理の文と定義で、主張の強さが変わることを見る | 座標版・ベクトル版・Mathlib 版の定理の文 | 「通った」より「何を示したか」を読む習慣のため |
| 4 | TLA+ との違いを一言で言えるようにする | 有限個の総当たりと、無限の場合の証明 | 2つを一括りにしないため |
| 5 | レビューに持ち帰る | チェックリストと、リーマン予想の検査での確かめ方 | 1〜3 節を、人の「証明した」を読む形にする |

</details>

## 0. 一枚で

| 問い | 答え |
| --- | --- |
| 「通った」で何が言えるか | 書いた定理の文・前提・定義のもとで、結論が正しい。どの一歩にも飛躍が無い |
| 何が言えないか | 定理の文と定義が、言いたいことを写しているか。前提が成り立ちえないなら、何も言っていない。`sorry`（証明を後回しにする仮置き）が残っていれば、その証明は無い |
| 証明はどう読むか | 高校の証明の1歩が、Lean の1行に当たる。Lean は「まだ示せていないこと」（ゴール）を持っていて、1行ごとに書き換わる |
| TLA+ とどう違うか | 総当たりではないので、無限にある場合もまとめて示せる。そのかわり、証明は人（や AI）が書く |

## 1. 「通った」が保証すること

Lean では、示したい命題と、その証明を書きます。
証明は**タクティク**（証明を一歩進める命令）を1行ずつ並べたもので、Lean は一歩ずつ検査します。
全部の一歩がつながっていれば、何も言わずに通します。
`make lean-mathlib`（三平方の定理などの例をビルドする）の最後の行はこうです。

<!-- output: lean-mathlib-build -->
```text
Build completed successfully (18260 jobs).
```

一歩でもつながらなければ、止まった行と、そのとき残っている**ゴール**（まだ示せていないこと）を出します。
次は、「1 + 2 + ... + n の2倍 = n(n + 1)」の帰納法の証明から、帰納法の仮定を使う1行をわざと消したものです（`make lean-broken`）。

<!-- output: lean-broken -->
```text
broken/SumFormulaBroken.lean:25:8: error: Tactic `rewrite` failed: Did not find an occurrence of the pattern
  ?n * ?k + ?m * ?k
in the target expression
  2 * sumTo k + 2 * (k + 1) = (k + 1) * (k + 1 + 1)

case succ
k : Nat
ih : 2 * sumTo k = k * (k + 1)
⊢ 2 * sumTo k + 2 * (k + 1) = (k + 1) * (k + 1 + 1)
```

`:25:8` が止まった行です。
`⊢` の右が、まだ示せていないゴールで、その上の行が手元にある前提です（`ih` が帰納法の仮定）。
`?n` のように `?` の付いた名前は「何が入ってもよい穴」で、くくり出せる形を探して見つからなかった、と言っています。

**Lean は「だいたい合っている」では通しません。**
ただし、検査するのは「前提と定義から結論が出るか」だけです。
次の定理は、前提 `h : n < 0`（n は 0 より小さい）を置いています。

<!-- source: examples/Vacuous.lean -->
```lean
theorem nonsense (n : Nat) (h : n < 0) : n = 42 := by
  omega                     -- 前提 h が矛盾していることを見つけて、証明を閉じる
```

<!-- output: vacuous -->
```text
エラーなし（定理 nonsense は通った）
```

0 より小さい自然数は無いので、この定理はどんな n についても何も言っていません。
それでも「前提から結論が出る」は正しい（前提が偽なら、何でも出せる）ので、Lean は通します。

もう1つ、`sorry` は「この証明はあとで書く」という仮置きで、Lean は警告を出しますが、エラーにはしません。

<!-- output: sorry -->
```text
Sorry.lean:6:8: warning: declaration uses `sorry`
終了コード 0
```

ここまでをまとめると、次の図の内側が Lean の保証で、外側は人が読んで判断するところです。

![外側の枠は人が判断すること：定義と前提は、言いたいことを正しく写しているか。内側の枠は Lean が検査したこと：前提と定義から、結論が一歩ずつ出ること。例として、前提 inner u v = 0、定義は Mathlib のもの、結論 ‖u - v‖² = ‖u‖² + ‖v‖²](figures/guarantee.svg)

## 2. 証明を1行ずつ追う：三平方の定理

### 高校の証明

使う道具を2つ思い出しておきます。

- 内積：u・v = |u||v|cos θ。2つのベクトルが直交するとき、u・v = 0。
- 展開：|u − v|² = |u|² − 2 u・v + |v|²。(a − b)² = a² − 2ab + b² と同じ形です。

証明はこうです。

> 直角をはさむ2辺をベクトル u, v とする。斜辺は u − v で表される。
> u と v は直交するから、u・v = 0 である。……（仮定）
> 示すことは |u − v|² = |u|² + |v|² である。
> |u − v|² を展開すると、|u − v|² = |u|² − 2 u・v + |v|² ……①
> ① に仮定 u・v = 0 を代入すると、|u − v|² = |u|² − 2・0 + |v|² ……②
> ② を整理すると |u − v|² = |u|² + |v|² となり、示すことと一致する。（証明終わり）

### Lean で書くとこうなる

<!-- source: ../../lean/with-mathlib/WithMathlib/Pythagoras.lean -->
```lean
theorem pythagoras_vec (u v : EuclideanSpace ℝ (Fin 2)) (h : inner ℝ u v = 0) :
    ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2 := by
  rw [norm_sub_sq_real]     -- Mathlib の補題「‖u - v‖² = ‖u‖² - 2 × (u と v の内積) + ‖v‖²」で左辺を書き換える
                            -- （(a - b)² = a² - 2ab + b² のベクトル版）
  rw [h]                    -- 前提 h で内積を 0 に置き換える →  ‖u‖² - 2 * 0 + ‖v‖² = ‖u‖² + ‖v‖²
  ring                      -- 2 * 0 = 0 を消せば両辺は同じ
```

高校の証明の1歩ずつが、Lean のどこに当たるかを並べます。

| 高校の証明 | Lean |
| --- | --- |
| 直角をはさむ2辺をベクトル u, v とする | `(u v : EuclideanSpace ℝ (Fin 2))` |
| 仮定：u・v = 0 | `(h : inner ℝ u v = 0)`（`h` は仮定に付けた名前） |
| 示すこと：\|u − v\|² = \|u\|² + \|v\|² | `: ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2` |
| ① 展開する | `rw [norm_sub_sq_real]`（展開の公式を、Mathlib にある名前で呼ぶ） |
| ② 仮定を使って置き換える | `rw [h]` |
| ③ 整理して、両辺が同じ | `ring` |

記号の読み替えは次のとおりです。

| Lean | 高校の記号 |
| --- | --- |
| `EuclideanSpace ℝ (Fin 2)` | 平面のベクトル（実数 ℝ を成分に2つ持つ） |
| `‖u‖` | 長さ \|u\| |
| `inner ℝ u v` | 内積 u・v |
| `^ 2` | 2乗 |

`‖u‖`、`inner`、`EuclideanSpace`、実数 `ℝ` は、Lean 本体ではなく Mathlib が定義しているものです。
`^` の記号だけは Lean 本体にあります。つまりこの証明の「通った」は、Mathlib の定義を信じたうえでの結果です（5節の「何を信じたか」）。Lean に、それぞれの定義がどのモジュールにあるかを答えさせると、こうなります（`Mathlib.` で始まるのが Mathlib、`Init.` で始まるのが Lean 本体）。

<!-- output: where-defined -->
```text
EuclideanSpace は Mathlib.Analysis.InnerProductSpace.PiL2 で定義
Real は Mathlib.Basic.Real.Basic で定義
Norm は Mathlib.Analysis.Normed.Group.Defs で定義
Inner は Mathlib.Analysis.InnerProductSpace.Defs で定義
HPow は Init.Prelude で定義
```

### 各行のあとのゴール

Lean に、証明の各行のあとのゴールを表示させたものが次です（各行の間に、その時点の様子を表示する命令 `trace_state` を挟んだ写し `examples/PythagorasGoals.lean` を走らせた）。
`⊢` の行が、順に「始め」「①のあと」「②のあと」です。

<!-- output: pythagoras-goals -->
```text
u v : EuclideanSpace ℝ (Fin 2)
h : inner ℝ u v = 0
⊢ ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2
u v : EuclideanSpace ℝ (Fin 2)
h : inner ℝ u v = 0
⊢ ‖u‖ ^ 2 - 2 * inner ℝ u v + ‖v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2
u v : EuclideanSpace ℝ (Fin 2)
h : inner ℝ u v = 0
⊢ ‖u‖ ^ 2 - 2 * 0 + ‖v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2
```

①のあとのゴールの左辺 `‖u‖ ^ 2 - 2 * inner ℝ u v + ‖v‖ ^ 2` は、高校の証明の ① の右辺 |u|² − 2 u・v + |v|² と同じ形です。
②のあとの `2 * 0` も、高校の証明の ② と同じです。
最後の `ring` が③に当たり、両辺が一致してゴールが無くなったところで証明が終わります。

仮定 h を使っているのは `rw [h]` の1行だけです。
証明を追うと、**どの前提がどこで効いているか**が分かります。

## 3. 定理の文と定義で、主張の強さが変わる

`Pythagoras.lean` には、三平方の定理が何通りか入っています。
どれも「通った」ですが、示したことの強さが違います。

一番素朴なのは、座標で置いた版です。
まず、2点の距離の2乗を、座標の差の2乗の和として**定義**します。

<!-- source: ../../lean/with-mathlib/WithMathlib/Pythagoras.lean -->
```lean
def distSq (p q : ℝ × ℝ) : ℝ :=
  (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2
```

そのうえで、直角の頂点を原点に、2辺を x 軸と y 軸に置きます。

<!-- source: ../../lean/with-mathlib/WithMathlib/Pythagoras.lean -->
```lean
theorem pythagoras_on_axes (a b : ℝ) : distSq (a, 0) (0, b) = a ^ 2 + b ^ 2 := by
  unfold distSq             -- distSq を定義で開く →  ((a, 0).1 - (0, b).1) ^ 2 + ((a, 0).2 - (0, b).2) ^ 2 = a ^ 2 + b ^ 2
  simp                      -- `simp` は決まりきった簡単化をまとめてやる。組から成分を取り出し、- 0 や 0 - を整理する
```

証明は、定義を開いて整理するだけです。
「距離の2乗 = x 方向の差の2乗 + y 方向の差の2乗」という定義そのものが、x 軸と y 軸が直角であることを前提にした三平方の定理だからです。
**この版は、定義に織り込んだことを取り出して見せただけで、三平方の定理を示したとはほとんど言えません。**

ほかの版は、定理の文だけを並べます（`example` は名前を付けない `theorem`、`∠ A C B` は角 ACB の大きさ、`Real.pi / 2` は 90 度）。

<!-- source: ../../lean/with-mathlib/WithMathlib/Pythagoras.lean -->
```lean
theorem pythagoras_coord (A B C : ℝ × ℝ)
    (h : (A.1 - C.1) * (B.1 - C.1) + (A.2 - C.2) * (B.2 - C.2) = 0) :
    distSq A B = distSq A C + distSq B C := by
```

<!-- source: ../../lean/with-mathlib/WithMathlib/Pythagoras.lean -->
```lean
example (A B C : EuclideanSpace ℝ (Fin 2)) (h : ∠ A C B = Real.pi / 2) :
    dist A B * dist A B = dist A C * dist A C + dist B C * dist B C :=
```

| 版 | 直角の書き方 | 距離 | 言えたこと |
| --- | --- | --- | --- |
| `pythagoras_on_axes` | 2辺を x 軸・y 軸に置く | 自作の `distSq` | 定義をほぼそのまま言い直した |
| `pythagoras_coord` | 内積 = 0 という前提 | 自作の `distSq` | どこに、どの向きに置いた直角三角形でも |
| `pythagoras_vec`（2節） | 内積 = 0 という前提 | Mathlib の長さ `‖ ‖` | 同上を、Mathlib のベクトルの言葉で |
| Mathlib の定理（`example`） | 角度が 90 度 | Mathlib の `dist` | 角度で書いた直角から。元の定理は逆向き（a² + b² = c² なら直角）も込み |

どれも、Lean の答えは同じ「通った」です。
違いは定理の文と定義に書いてあり、それを読むのは人です。
自作の定義（`distSq`）が言いたいことを写しているかは、自分で読むしかありません。Mathlib の定義を使えば、読む対象が Mathlib の定義に移ります。
冒頭のリーマン予想で、コミュニティが証明とは別に確かめたのも、この「定理の文が、どの定義を使っているか」でした（5節）。

プログラムの性質でも同じことが起きます。
「ソート関数の出力は昇順に並んでいる」だけを定理にすると、空のリストを返す関数でも成り立ちます（空のリストは昇順だから）。「出力は入力の並べ替えである」も文に入れて、初めて言いたいことになります（この例は Lean では書いていない）。

## 4. TLA+ との違い

`lean/basics/Basics/FirstSteps.lean` に、2つの考え方が並んでいます。

<!-- source: ../../lean/basics/Basics/FirstSteps.lean -->
```lean
example : ∀ n, n < 10 → n * n < 100 := by
  decide                  -- n = 0, 1, ..., 9 の 10 通りを計算して、どれも成り立つと確かめる
```

<!-- source: ../../lean/basics/Basics/FirstSteps.lean -->
```lean
theorem add_self_eq_two_mul (n : Nat) : n + n = 2 * n := by
  omega                   -- 一次式の等式なので omega が証明を組み立てる
```

上は有限個を全部計算して確かめる、総当たりです。
TLA+ は、同時に動く処理の設計を模型に書き、検査器 TLC がありうる状態を総当たりで調べて、壊れる手順（反例）を出す道具で、考え方はこちらです。
下は「どんな自然数 n でも」を、場合を並べずに理屈で示しています。三平方の定理も同じで、無限にある三角形を、文字のまま一度に示しました。
そのかわり、TLA+ では機械が反例を探すのに対し、Lean では証明を人（や AI）が書きます。

TLA+ 側の話は [TLA+ の「エラーなし」は何を保証したのか](../tla/README.md) にあります。

## 5. 「証明が通った」と聞いたときに読むところ

- [ ] 定理の文（`:` の右）を読み、示したことが言いたいことと合っているか
- [ ] 前提（`(h : ...)`）を読み、成り立ちうるか、強すぎないか
- [ ] 定義（`def`）を読み、結論を織り込んでいないか。自作か、Mathlib のものか
- [ ] 警告に `sorry` が無いか
- [ ] 何を信じた結果か（Mathlib などの依存、Lean 本体、ビルド済みのキャッシュ）

冒頭のリーマン予想の検査も、このリストに沿って読めます。
公開された検査用リポジトリ（[leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis)）の README に書かれている確かめ方と、対応させるとこうなります。

| チェック | リーマン予想の検査用リポジトリで、どう確かめているか（README の記述） |
| --- | --- |
| 定理の文 | 主定理の文は Mathlib の `RiemannHypothesis` そのもの。Mathlib だけを読み込むファイル `Challenge.lean` に同じ文を置き、証明側がちょうどその文を示しているかを道具（Comparator）で照合する |
| 定義 | 主定理は、自作の定義でなく Mathlib の定義をそのまま使う（ほかの4つの定理の文は、`Challenge.lean` の中で Mathlib の言葉を使って書き下している） |
| `sorry` | `Challenge.lean` は、文だけを書いて証明を `sorry` にした「問題」のファイル。証明側（`Main.lean`）と照合する |
| 何を信じたか | 証明なしで認める前提（公理）を、Lean で標準の3つに限る。Lean 本体の検査器（カーネル）と、それとは別に作られた検査器（nanoda）の両方に通す。ビルド済みのキャッシュを取ってきた場合は Lean が検査し直さないので、検査には使わない、とも書いている |

Mathlib のリーマン予想の定義は、手元の Mathlib（v4.36.0）でも表示できます。

<!-- output: rh-def -->
```text
def RiemannHypothesis : Prop :=
∀ (s : ℂ), riemannZeta s = 0 → (¬∃ n, s = -2 * (↑n + 1)) → s ≠ 1 → s.re = 1 / 2
```

「ゼータ関数の零点 s のうち、−2, −4, −6, … と s = 1 を除くものは、実部が 1/2」と読みます。
この1行が言いたいリーマン予想を正しく写しているかを確かめるのは、Lean ではなく人です。声明は、この文を Lean と数論の専門家が注意深く確かめた、と書いています。
Lean の検査が保証するのは、その先、この文から証明の最後まで飛躍が無いことです。

## 6. 理解度チェック

**問1.** 同僚が「Lean で、このソート関数の性質を証明した。ビルドも通った」と言う。まず何を読むか。

<details>
<summary>答え</summary>

証明ではなく、定理の文と前提と定義です。
ビルドが通ったことで分かるのは「書いた前提と定義から、書いた結論が出る」までで、その結論が言いたい性質かは文を読まないと分かりません（1節、3節）。
警告に `sorry` が無いかも見ます。

</details>

**問2.** 2節の証明から `rw [h]` の行を消すと、どうなるか。高校の証明では、どの1歩を飛ばしたことになるか。

<details>
<summary>答え</summary>

通らなくなります。高校の証明では ②（仮定 u・v = 0 を代入する）を飛ばしたことになります。
実際に消した写し（`examples/PythagorasWithoutH.lean`）では、Lean はこう返します。

<!-- output: pythagoras-without-h -->
```text
  The `ring` tactic failed to close the goal. Use `ring_nf` to obtain a normal form.
error: unsolved goals
⊢ ‖u‖ ^ 2 - inner ℝ u v * 2 + ‖v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2
```

ゴールに内積 `inner ℝ u v` が残っています。直角であることが、証明のどこにも入っていないからです。

</details>

**問3.** リーマン予想の Lean の証明が、Lean の検査を全部通ったとする。それでもコミュニティが、定理の文を別に確かめたのはなぜか。

<details>
<summary>答え</summary>

Lean が保証するのは「書いた定理の文から、証明に飛躍が無いこと」までだからです。
定理の文が別のこと（たとえば、成り立ちえない前提を置いた文や、自作の定義に結論を織り込んだ文）を言っていても、Lean は通します（1節、3節）。
だから、文が Mathlib のリーマン予想の定義そのものであることを、別に確かめる必要がありました（5節）。

</details>

**問4.** TLA+ の TLC は、たとえば在庫の引き当ての模型（TLA+ の資料の例）を「3人が在庫2個を取り合う場合」に限って総当たりで調べる。Lean の三平方の定理は、何個の三角形を調べたか。

<details>
<summary>答え</summary>

1つも「調べて」はいません。
三角形を1つずつ試すのではなく、文字（u, v）のまま、どの三角形でも成り立つことを一度に示しています（4節）。

</details>

## 7. 持ち帰ること

「証明が通った」と聞いたら、**証明ではなく、定理の文と前提と定義を読む**。通ったことが保証するのは、そこから先に飛躍が無いことだけです。

## 付録：再現

```sh
make lean-mathlib   # 1節のビルド（初回は Mathlib のビルド済みを約 7GB 取ってくる）
make lean-broken    # 1節の、壊した証明のエラー
make lean           # 4節の FirstSteps.lean を含む、Mathlib なしの例
```

| ファイル | 中身 |
| --- | --- |
| `lean/with-mathlib/WithMathlib/Pythagoras.lean` | 三平方の定理（座標版、ベクトル版、Mathlib の定理） |
| `lean/basics/broken/SumFormulaBroken.lean` | 1節の、わざと壊した証明 |
| `lean/basics/Basics/FirstSteps.lean` | 4節の、総当たりと理屈の比較 |
| `docs/lean/examples/Vacuous.lean` | 1節の、前提が成り立ちえない定理 |
| `docs/lean/examples/Sorry.lean` | 1節の、`sorry` で飛ばした定理 |
| `docs/lean/examples/PythagorasGoals.lean` | 2節の、各行のあとのゴールを表示する写し |
| `docs/lean/examples/WhereDefined.lean` | 2節の、記号の定義がどこにあるかを表示する |
| `docs/lean/examples/RiemannHypothesisDef.lean` | 5節の、Mathlib のリーマン予想の定義を表示する |
| `docs/lean/examples/PythagorasWithoutH.lean` | 理解度チェック 問2 の、`rw [h]` を消した写し |
| `docs/lean/checks.json` | 本文の出力を再生成して照合するコマンド |

検証は、リポジトリの直下で `npm i` をしたあと、explainer スキルの `verify-doc.mjs` にこのディレクトリを渡して走らせる。

## 付録：外部の出来事の出典と、未検証の点

冒頭と5節のリーマン予想の話は、このリポジトリの外の出来事で、`checks.json` では照合していません。
確認日は 2026-11-25 です。その後に情報が変わっている可能性があります。

| 本文の記述 | 出典 |
| --- | --- |
| 2026年11月20日、Levent Alpöge 氏が Lean のコードとして証明を公開した | [Lean FRO と Mathlib Initiative の共同声明](https://leanprover-community.github.io/blog/posts/riemann-hypothesis/)（2026-11-21）、[検査用リポジトリの README](https://github.com/leanprover-community/riemann-hypothesis)（最初の公開版を 2026-11-20 に取得したと記載） |
| 約1700万行 | 共同声明（"17 million lines of code"） |
| コードが Lean の検査を通り、定理の文が Mathlib の定義と一致することを確かめた | 共同声明（Lean の公式のカーネルと、複数の独立した検査器で検査した、とある） |
| 声明は、文を Lean と数論の専門家が確かめたと書いている | 共同声明（"carefully vetted by experts in Lean and number theory"） |
| 著者は、人が読める形の長い文書は出さず、Lean だけを公開した | [著者の remark](https://alpo.ge/remark.pdf)（"I decided to only present Lean"。きちんと書き下すつもりだ、とも書いている） |
| 5節の表（`Challenge.lean`、Comparator、公理3つ、nanoda、キャッシュは検査し直さない） | 検査用リポジトリの README と `comparator.json`（2026-11-25 に読んだ版） |

未検証・扱わないこと：

- 数学の論文としての査読や、数学界での評価。この資料では確かめておらず、扱わない
- 約1700万行という数は声明の値で、自分では数えていない
- 共同声明が挙げる検査器の名前と、リポジトリの README・`comparator.json` が挙げる検査器の名前は、一部が違う（時点の違いと思われるが未確認）。本文では「Lean のカーネルと、別に実装された検査器」とだけ書いた
- 3節の表の「元の Mathlib の定理は逆向きも込み」は、`Pythagoras.lean` のコメントによる（Mathlib のソースは読んでいない）
- 5節の `RiemannHypothesis` の表示は、このリポジトリの Mathlib（v4.36.0）のもの。検査用リポジトリが使う Mathlib の版とは違う可能性がある（未確認）

## 付録：この資料が置いた前提

この資料は「TLA+ も Lean も知らない人向け」という依頼で書きました。それ以外の読み手の像は、書き手の推測です。

- 高校数学（ベクトルと内積、二次式の展開、三平方の定理）は分かる（理由：リポジトリの README がこの範囲を想定読者にしているため）
- Web のバックエンドやアプリを書くエンジニアで、テストや CI の緑は見慣れている（理由：リポジトリの TLA+ の例の題材から）
- チームのナレッジとして後から読み返し、1本に 10〜15 分を使う

読み手の像が違っていたら直したいので、次を教えてください。

- ベクトルの内積を、どのくらい覚えているか（忘れているなら、2節の前に内積の説明を足す）
