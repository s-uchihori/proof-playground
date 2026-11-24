------------------------------- MODULE Stock -------------------------------
(* 例3: 在庫の引き当て。人数と在庫数を、あとから変えられる形で書く。

   在庫 InitialStock 個の商品を、Buyers の人たちが1個ずつ買おうとする。
   引き当ては、在庫の確認と引き算を1つの SQL でやる。
     UPDATE items SET stock = stock - 1 WHERE id = ... AND stock > 0
   更新できた行が 1 なら買えた、0 なら売り切れ。

   人数と在庫数は Stock.cfg で決める。TLC が調べるのは、そこに書いた大きさの場合だけ。 *)

EXTENDS Integers, FiniteSets  \* 整数（負の数も）と、集合の要素数 Cardinality を使えるようにする

CONSTANTS
  Buyers,                     \* 買おうとする人の集まり（中身は .cfg で決める）
  InitialStock                \* 最初の在庫数（これも .cfg で決める）

VARIABLES
  stock,                      \* 今の在庫数
  result                      \* 各人の結果（"waiting": まだ, "bought": 買えた, "soldout": 売り切れだった）

\* 最初の状態。
Init ==
  /\ stock = InitialStock                   \* 在庫は満タン
  /\ result = [b \in Buyers |-> "waiting"]  \* 全員まだ買っていない

\* 一手その1: b が買える。在庫の確認と引き算が、同じ一手の中にある。
Buy(b) ==
  /\ result[b] = "waiting"                      \* b がまだ試していない
  /\ stock > 0                                  \* 在庫がある
  /\ stock' = stock - 1                         \* 1個減らす
  /\ result' = [result EXCEPT ![b] = "bought"]  \* b は買えた

\* 一手その2: b が買えない。
SoldOut(b) ==
  /\ result[b] = "waiting"                      \* b がまだ試していない
  /\ stock = 0                                  \* 在庫がない
  /\ result' = [result EXCEPT ![b] = "soldout"] \* b は売り切れだった
  /\ UNCHANGED stock                            \* 在庫は変わらない

\* 一手その3: 全員の結果が出たら、何も変えずに居続ける（正常な終わりをデッドロックと数えさせない）。
Finished ==
  /\ \A b \in Buyers : result[b] /= "waiting"   \* /= は「等しくない」
  /\ UNCHANGED <<stock, result>>

\* 次に起こりうる一手。
Next == (\E b \in Buyers : Buy(b) \/ SoldOut(b)) \/ Finished

\* 仕様の全体。
Spec == Init /\ [][Next]_<<stock, result>>

\* 買えた人の数。{b \in S : 条件} は「S のうち条件に合うものの集まり」。
BoughtCount == Cardinality({b \in Buyers : result[b] = "bought"})

\* 不変条件その1: 在庫は負にならない（売りすぎない）。
NoOversell == stock >= 0

\* 不変条件その2: 残りの在庫 + 売れた数 は、いつも最初の在庫数に等しい（数が合う）。
Consistent == stock + BoughtCount = InitialStock

=============================================================================
