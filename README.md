# proof-playground

TLA+ と Lean を初めて触る人が、最小の例を読んで、手元で走らせて、2つの違いをつかむための教材です。

- **TLA+**: 設計の模型を書くと、機械が「ありうる順番」を総当たりして、壊れる手順を見せてくれる。
- **Lean**: 定理と証明を書くと、機械が一歩ずつ検査する。総当たりではないので、無限にある場合もまとめて示せる。

高校数学（数列、数学的帰納法、二次式の展開、三平方の定理、背理法）が分かれば読めるように書いてあります。コードには1行ずつ日本語のコメントが付いています。

## 何が入っているか

| 場所 | 中身 | 走らせるコマンド |
| --- | --- | --- |
| `tla/01_lost_update/` | 2つの処理が同じ値を読んで書き戻し、更新が消える。壊れている版と直した版 | `make tla-lost-update` / `make tla-lost-update-fixed` |
| `tla/02_deadlock/` | 2つのトランザクションが逆の順でロックを取り、デッドロックする。壊れている版と直した版 | `make tla-deadlock` / `make tla-deadlock-fixed` |
| `tla/03_stock/` | 在庫の引き当て。人数と在庫数を変えて検査できる | `make tla-stock` |
| `lean/basics/` | Mathlib なしの Lean。はじめの一歩、1 から n までの和の公式（帰納法）、偶数どうしの和は偶数 | `make lean` |
| `lean/basics/broken/` | わざと壊した証明。Lean がどう怒るかを見る | `make lean-broken` |
| `lean/with-mathlib/` | Mathlib を使う Lean。二乗の展開、三平方の定理、相加平均と相乗平均、√2 は無理数 | `make lean-mathlib` |

## どう走らせるか

```sh
make doctor        # 要る道具が入っているかを調べる
make tla           # TLA+ の例を全部検査する（初回に tla2tools.jar を落とす。2MB）
make lean          # Mathlib なしの Lean の例を検査する（初回に Lean 本体を取ってくる）
make lean-broken   # 壊した証明に Lean がどう怒るかを見る
make lean-mathlib  # Mathlib を使う例を検査する（初回に約 7GB を取ってくる）
```

`make` だけ打つと、コマンドの一覧が出ます。要る道具は Java（TLA+ 用）と elan（Lean 用）の2つです。入れ方は[道具の入れ方](#道具の入れ方)にあります。

`make tla`、`make lean`、`make lean-mathlib` は互いに独立です。Mathlib を取ってこなくても、TLA+ と `lean/basics/` は動きます。

## TLA+ と Lean の違い

どちらも「機械に確かめさせる」道具ですが、確かめ方が違います。

| | TLA+（TLC） | Lean |
| --- | --- | --- |
| 書くもの | 仕組みの模型（状態と、起こりうる一手）と、守ってほしい条件 | 示したい命題と、その証明 |
| 機械がやること | たどり着ける状態を全部調べる（総当たり） | 証明の一歩一歩が正しいかを検査する |
| だめなとき | 条件が破れるまでの手順（反例）を出す | 証明のどの行で、何が示せていないかを出す |
| 言える範囲 | 設定に書いた大きさの場合だけ | 文字で書いた「すべての場合」 |
| 証明を考えるのは | 要らない。模型を書けば機械が探す | 人（機械は検査する側） |

置いてある例で言うと、次のとおりです。

- `tla/03_stock/` は「3人が在庫2個を取り合っても売りすぎない」を、10個の状態を全部調べて確かめます。6人・在庫3個に変えると 182 個に増えますが、それも全部調べます。ただし確かめたのはその人数の場合だけで、「何人でも大丈夫」とは言っていません。
- `lean/basics/Basics/SumFormula.lean` は「どんな自然数 n でも 1 + ... + n = n(n+1)/2」を示します。n は無限にあるので総当たりはできません。帰納法という理屈を人が書き、Lean はその理屈に穴が無いことを検査します。
- 2つの考え方が同じファイルに並ぶ場所もあります。`lean/basics/Basics/FirstSteps.lean` の `decide` は「10 未満の n を全部計算して確かめる」総当たりで、すぐ下の `omega` は「どんな n でも」を理屈で示します。

使いどころも分かれます。TLA+ は「処理が入り乱れる順番」のように、人が見落としやすい組み合わせを機械に洗い出させるのに向いています。Lean は「どんな入力でも成り立つ」と言い切りたい性質を、数学の証明と同じ確かさで示すのに向いています。

---

## TLA+ の部

読む順番は `01` → `02` → `03` です。それぞれ、仕様の `.tla` と、TLC（検査する道具）への指示書の `.cfg` が対になっています。

TLA+ で書くのは3つだけです。

1. **最初の状態**（`Init`）
2. **起こりうる一手**（`Next`）。「誰が先に動くか」は書きません。TLC がありうる順番を全部試します。
3. **守ってほしい条件**（不変条件 = どの状態でも成り立っていてほしい条件）

### 例1: 更新が消える（`tla/01_lost_update/`）

「いいね数」を 1 増やす処理を、2つのリクエスト A, B が同時に走らせます。どちらも「DB から読む → 読んだ値 + 1 を書き戻す」の2手です。2つとも終われば 2 になっていてほしい。

```sh
make tla-lost-update
```

TLC は条件が破れる手順を見つけて、こう出します（実際の出力。前後の起動メッセージは省略）。

```text
Error: Invariant NoLostUpdate is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ seen = [A |-> 0, B |-> 0]
/\ pc = [A |-> "read", B |-> "read"]
/\ likes = 0

State 2: <Read line 33, col 3 to line 36, col 20 of module LostUpdate>
/\ seen = [A |-> 0, B |-> 0]
/\ pc = [A |-> "write", B |-> "read"]
/\ likes = 0

State 3: <Read line 33, col 3 to line 36, col 20 of module LostUpdate>
/\ seen = [A |-> 0, B |-> 0]
/\ pc = [A |-> "write", B |-> "write"]
/\ likes = 0

State 4: <Write line 40, col 3 to line 43, col 19 of module LostUpdate>
/\ seen = [A |-> 0, B |-> 0]
/\ pc = [A |-> "done", B |-> "write"]
/\ likes = 1

State 5: <Write line 40, col 3 to line 43, col 19 of module LostUpdate>
/\ seen = [A |-> 0, B |-> 0]
/\ pc = [A |-> "done", B |-> "done"]
/\ likes = 1

13 states generated, 12 distinct states found, 3 states left on queue.
```

#### 反例の読み方

- 1行目の `Invariant NoLostUpdate is violated` が結論です。「`NoLostUpdate` という条件が破れる状態にたどり着けた」。
- そのあとの `State 1` 〜 `State 5` が、**最初の状態から、条件が破れる状態までの手順**です。上から順に時間が進みます。
- 各 `State` の `<...>` が「この状態に来るために起きた一手」。`<Read line 33 ...>` は `LostUpdate.tla` の 33 行目から始まる `Read` が起きた、という意味です。
- その下の `/\ 変数 = 値` が、その時点の全部の変数の値です。`[A |-> 0, B |-> 0]` は「A の欄が 0、B の欄が 0」の表。
- 前の `State` と見比べて、変わった変数を追います。

この出力を言葉にすると、こうなります。

| | 起きたこと | likes | A の進み | B の進み |
| --- | --- | --- | --- | --- |
| State 1 | 最初 | 0 | これから読む | これから読む |
| State 2 | A が読む（0 を見た） | 0 | 次は書く | これから読む |
| State 3 | B が読む（こちらも 0 を見た） | 0 | 次は書く | 次は書く |
| State 4 | A が 0 + 1 = 1 を書く | 1 | 終わり | 次は書く |
| State 5 | B が 0 + 1 = 1 を書く | 1 | 終わり | 終わり |

2つとも終わったのに `likes` は 1。B は A が書く前の値（0）を持ったまま書いたので、A の更新が消えました。

- 最後の行の `12 distinct states found` は、TLC がそれまでに調べた状態の数です。TLC は手数の少ない順に調べるので、出てくる反例はいちばん短い手順です。
- どちらのリクエストが先に動くかは対称なので、出てくる手順は A と B が入れ替わっても同じ意味です。

#### 直した版

読むのと書くのを、割り込まれない一手にまとめます（SQL なら `UPDATE ... SET likes = likes + 1`）。

```sh
make tla-lost-update-fixed
```

```text
Model checking completed. No error has been found.
5 states generated, 4 distinct states found, 0 states left on queue.
```

`No error has been found` が「たどり着ける状態（4個）を全部調べたが、条件が破れるものは無かった」です。`0 states left on queue` は、調べ残しが無いことを表します。

### 例2: デッドロック（`tla/02_deadlock/`）

2つのトランザクションが、口座 a, b の行を両方ロックしてから更新します。T1 は a → b の順、T2 は b → a の順に取ります。

この例では、守ってほしい条件を1つも書きません。TLC は頼まなくても「まだ終わっていないのに、誰も動けない状態」を探します。

```sh
make tla-deadlock
```

```text
Error: Deadlock reached.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ owner = [a |-> "free", b |-> "free"]
/\ step = [T1 |-> 0, T2 |-> 0]

State 2: <Acquire line 31, col 3 to line 35, col 45 of module Deadlock>
/\ owner = [a |-> "T1", b |-> "free"]
/\ step = [T1 |-> 1, T2 |-> 0]

State 3: <Acquire line 31, col 3 to line 35, col 45 of module Deadlock>
/\ owner = [a |-> "T1", b |-> "T2"]
/\ step = [T1 |-> 1, T2 |-> 1]

8 states generated, 7 distinct states found, 2 states left on queue.
```

読み方は例1と同じです。T1 が a を取り、T2 が b を取ったところ（State 3）で、T1 は b を、T2 は a を待ち続けます。どちらも次の一手を起こせません。

直した版は、ロックを取る順番を全員 a → b にそろえたものです。仕様の違いは `Order` の1行だけです。

```sh
make tla-deadlock-fixed
```

```text
Model checking completed. No error has been found.
14 states generated, 12 distinct states found, 0 states left on queue.
```

### 例3: 在庫の引き当て（`tla/03_stock/`）

人数と在庫数を仕様の中で決めず、`Stock.cfg` で決める形です。条件は「在庫は負にならない」「残りの在庫 + 売れた数 = 最初の在庫数」の2つ。

```sh
make tla-stock
```

```text
Model checking completed. No error has been found.
16 states generated, 10 distinct states found, 0 states left on queue.
```

`Stock.cfg` の `Buyers` と `InitialStock` を書き換えて走らせ直すと、調べる状態の数が変わります。6人・在庫3個にすると `182 distinct states found` になります。TLC が言っているのは、いつも「この大きさでは大丈夫だった」です。

### 全部まとめて確かめる

```sh
make tla
```

```text
TLA+ の例を TLC で検査します
  期待どおり  01_lost_update/LostUpdate        不変条件 NoLostUpdate が破れる（調べた状態 12 個）
  期待どおり  01_lost_update/LostUpdateFixed   エラーなし（調べた状態 4 個）
  期待どおり  02_deadlock/Deadlock             デッドロックが見つかる（調べた状態 7 個）
  期待どおり  02_deadlock/DeadlockFixed        エラーなし（調べた状態 12 個）
  期待どおり  03_stock/Stock                   エラーなし（調べた状態 10 個）
```

壊れている版は、TLC がエラーを見つけるのが「期待どおり」です。

### 試してみること

- `LostUpdateFixed.tla` を、`LostUpdate.tla` と見比べる。違いは「読む」と「書く」が1つの一手か、2つの一手か。
- `LostUpdate.tla` の `Reqs` を `{"A", "B", "C"}` に、`NoLostUpdate` の `2` を `3` に変えて走らせる。
- `Stock.tla` の `Buy` を、例1のように「在庫を読む」と「引いて書く」の2手に分けてみる。`NoOversell` が破れる手順が出るかを確かめる（この版は置いていないので、自分で書く練習に）。

---

## Lean の部

Lean では「示したいこと」と「その証明」を書きます。証明は**タクティク**（証明を一歩進める命令）を並べて書きます。Lean は「いま残っている示すべきこと」（**ゴール**）を持っていて、タクティクがそれを書き換えたり片付けたりします。ゴールが全部片付けば、証明の完成です。

ビルドが通る ＝ すべての証明が検査を通った、です。Lean は通ったときは何も言いません。

### Mathlib なしの例（`lean/basics/`）

```sh
make lean
```

```text
✔ [2/10] Built Basics.FirstSteps (341ms)
✔ [4/10] Built Basics.SumFormula (352ms)
✔ [6/10] Built Basics.EvenSum (341ms)
✔ [8/10] Built Basics (166ms)
Build completed successfully (10 jobs).
```

読む順番は次のとおりです。

1. `Basics/FirstSteps.lean` … 書き方の形。計算で分かる等式（`rfl`）、有限個の総当たり（`decide`）、無限にある場合（`omega`）。
2. `Basics/SumFormula.lean` … 数学的帰納法で `2 * (1 + ... + n) = n * (n + 1)`。高校の証明と1行ずつ対応します。
3. `Basics/EvenSum.lean` … 「偶数である」を自分で定義して、偶数どうしの和は偶数を示す。

`SumFormula.lean` の証明の本体はこうなっています。右のコメントが、その行のあとのゴールです。

```lean
theorem two_mul_sumTo (n : Nat) : 2 * sumTo n = n * (n + 1) := by
  induction n with          -- n についての数学的帰納法
  | zero =>                 -- 【n = 0 の場合】
    rfl                     -- 両辺とも計算すると 0
  | succ k ih =>            -- 【n = k + 1 の場合】ih が帰納法の仮定: 2 * sumTo k = k * (k + 1)
    rw [sumTo]              -- →  2 * (sumTo k + (k + 1)) = (k + 1) * (k + 1 + 1)
    rw [Nat.mul_add]        -- →  2 * sumTo k + 2 * (k + 1) = (k + 1) * (k + 1 + 1)
    rw [ih]                 -- →  k * (k + 1) + 2 * (k + 1) = (k + 1) * (k + 1 + 1)
    rw [← Nat.add_mul]      -- →  (k + 2) * (k + 1) = (k + 1) * (k + 1 + 1)
    rw [Nat.mul_comm]       -- →  (k + 1) * (k + 2) = (k + 1) * (k + 1 + 1)   両辺が同じ形なので証明終わり
```

### 証明を壊すと、Lean はどう怒るか

`lean/basics/broken/SumFormulaBroken.lean` は、上の証明から帰納法の仮定を使う1行 `rw [ih]` を消したものです。ビルドの対象には入れていません（`lakefile.toml` の対象は `Basics` だけ）。

```sh
make lean-broken
```

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

読み方:

- `SumFormulaBroken.lean:25:8` … 25 行目（`:8` は行の中の位置）。`rw [← Nat.add_mul]` の行で止まった。
- `Did not find an occurrence of the pattern ?n * ?k + ?m * ?k` … 「（何か）×（共通のもの）＋（何か）×（共通のもの）」という形を探したが、ゴールの中に無かった。`?` の付いた名前は「何でもよい」穴です。
- `case succ` より下が、止まった時点の様子です。`⊢` の右が**まだ示せていないゴール**、その上が手元にある前提。
- 前提に `ih`（帰納法の仮定）があるのに、ゴールには `2 * sumTo k` が残ったままです。本物の証明ではここを `ih` で `k * (k + 1)` に置き換えていたので、`(k + 1)` でくくれました。置き換えを忘れたので、くくれる形になっていません。

Lean は「だいたい合っている」では通しません。一歩でも理屈がつながらなければ、その行と、そのとき残っているゴールを見せて止まります。

自分でも壊してみてください。`lean/basics/Basics/SumFormula.lean` のタクティクを1行消すか、定理の右辺を `n * n` に変えて `make lean` を走らせると、ビルドが失敗して同じようにゴールが出ます。

### Mathlib を使う例（`lean/with-mathlib/`）

Mathlib は Lean の数学ライブラリです。実数、ベクトル、式の計算を任せられるタクティクが入っています。

```sh
make lean-mathlib
```

初回はビルド済みの Mathlib（約 7GB）を取ってくるので、回線によって 10 分ほどかかります。2回目からは数秒です。

```text
✔ [18250/18260] Built WithMathlib.SquareExpansion (16s)
✔ [18252/18260] Built WithMathlib.Pythagoras (16s)
✔ [18254/18260] Built WithMathlib.Sqrt2 (16s)
✔ [18256/18260] Built WithMathlib.AmGm (16s)
Build completed successfully (18260 jobs).
```

（ジョブが 18260 あるのは Mathlib の分です。取ってきたビルド済みのものをそのまま使うので、実際に検査されるのは上の4ファイルです。）

読む順番は次のとおりです。

1. `WithMathlib/SquareExpansion.lean` … `(a + b)² = a² + 2ab + b²`。タクティク `ring` が展開して見比べる。
2. `WithMathlib/Pythagoras.lean` … 三平方の定理。下に詳しく書きます。
3. `WithMathlib/AmGm.lean` … `√(xy) ≤ (x + y) / 2`。`(x - y)² ≥ 0` から出す。
4. `WithMathlib/Sqrt2.lean` … √2 は無理数。高校の背理法（m も n も偶数になって矛盾）をそのまま書く。

#### 三平方の定理

`Pythagoras.lean` には3通りが入っています。

1. **座標で置いて、自分で示す。** 点を実数の組で表し、距離の2乗を「座標の差の2乗の和」で定義します。直角の頂点 C から出る2辺の内積が 0 のとき、`AB² = AC² + BC²`（`pythagoras_coord`）。
2. **ベクトルで置いて、自分で示す。** 直角をはさむ2辺をベクトル u, v とすると、斜辺は u − v。u と v が直交するなら `‖u - v‖² = ‖u‖² + ‖v‖²`（`pythagoras_vec`）。

   ```lean
   theorem pythagoras_vec (u v : EuclideanSpace ℝ (Fin 2)) (h : inner ℝ u v = 0) :
       ‖u - v‖ ^ 2 = ‖u‖ ^ 2 + ‖v‖ ^ 2 := by
     rw [norm_sub_sq_real]     -- ‖u - v‖² を ‖u‖² - 2 × (内積) + ‖v‖² に書き換える
     rw [h]                    -- 内積を 0 に置き換える
     ring                      -- 2 * 0 = 0 を消せば両辺は同じ
   ```

3. **Mathlib にすでにある三平方の定理を使う。**

   | | |
   | --- | --- |
   | 名前 | `EuclideanGeometry.dist_sq_eq_dist_sq_add_dist_sq_iff_angle_eq_pi_div_two` |
   | 場所 | `Mathlib/Geometry/Euclidean/Angle/Unoriented/RightAngle.lean` |
   | 中身 | `dist p₁ p₃ * dist p₁ p₃ = dist p₁ p₂ * dist p₁ p₂ + dist p₃ p₂ * dist p₃ p₂ ↔ ∠ p₁ p₂ p₃ = π / 2` |

   「p₂ の角が直角であること」と「a² + b² = c² が成り立つこと」が同値（`↔`）、という形です。逆（a² + b² = c² なら直角）も込みで、平面に限らず何次元でも使えます。ベクトル版は `norm_sub_sq_eq_norm_sq_add_norm_sq_iff_real_inner_eq_zero` という名前で `Mathlib/Analysis/InnerProductSpace/Basic.lean` にあります。

   手元でソースを読むには、`make lean-mathlib` のあと `lean/with-mathlib/.lake/packages/mathlib/` の下の同じパスを開きます。

同じように、`Sqrt2.lean` の最後では Mathlib の `irrational_sqrt_two`（`Mathlib/NumberTheory/Real/Irrational.lean`）を紹介しています。

### エディタで読むと分かりやすい

VS Code に拡張機能「Lean 4」を入れて `lean/basics` か `lean/with-mathlib` のフォルダを開くと、カーソルを置いた行の時点のゴールが右側に表示されます。コメントに書いた「→ ゴール」を、自分の目で一行ずつ確かめられます。なくても `make` で検査はできます。

---

## 道具の入れ方

入れるものは2つです。どちらもホームディレクトリの下に入り、`sudo` は要りません。

### Java（TLA+ 用）

TLC は Java で動きます。11 以上が要ります。まず入っているかを見ます。

```sh
java -version
```

無ければ、どれか1つで入れます。

```sh
mise use -g java@21        # mise を使っている場合
brew install openjdk@21    # Homebrew を使う場合（入れたあとに出る PATH の案内に従う）
```

TLA+ の道具そのもの（`tla2tools.jar`、2MB）は `make tla` が初回に `tools/` へ落とします。`tools/` は git に入りません。

### elan（Lean 用）

elan は Lean の版を管理する道具です。`lean` と `lake`（Lean のビルド道具）が一緒に入ります。

```sh
curl https://elan.lean-lang.org/elan-init.sh -sSf | sh -s -- -y --no-modify-path --default-toolchain none
```

- `--no-modify-path` を付けると、`.zshrc` などのシェルの設定を書き換えません。`~/.elan/` の下に入るだけです。
- この `Makefile` は `~/.elan/bin` を自分で見に行くので、`make lean` などは PATH を通さなくても動きます。
- `lake` や `lean` を自分で直接打ちたいとき（と、VS Code の拡張を使うとき）は、`~/.elan/bin` を自分で PATH に足してください。
- Lean 本体の版は、各パッケージの `lean-toolchain` に書いてあります。初回のビルドで elan がその版を自動で取ってきます。

### ディスクの使用量

| もの | 場所 | 大きさ |
| --- | --- | --- |
| tla2tools.jar | `tools/` | 2MB |
| elan と Lean 本体 | `~/.elan/` | 約 3GB |
| Mathlib（ビルド済み） | `lean/with-mathlib/.lake/` | 約 7GB |

`make clean` で、このリポジトリの中に落としたもの（Mathlib を含む）を消せます。`~/.elan/` を消すには `elan self uninstall` です。

### 確かめた版

| | 版 |
| --- | --- |
| TLA+ tools（TLC） | v1.7.4（TLC 2.19） |
| Java | OpenJDK 21 |
| Lean | 4.36.0（`lean-toolchain` で固定） |
| Mathlib | v4.36.0（`lakefile.toml` と `lake-manifest.json` で固定） |
| OS | macOS（Apple シリコン） |
