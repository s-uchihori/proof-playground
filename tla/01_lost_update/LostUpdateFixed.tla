-------------------------- MODULE LostUpdateFixed --------------------------
(* 例1（直した版）: 読むのと書くのを、割り込まれない一手にまとめる。

   SQL でいえば、アプリで読んで足して書くのをやめて
     UPDATE posts SET likes = likes + 1 WHERE id = ...
   と DB に任せる形。LostUpdate.tla との違いは Incr の中身だけ。            *)

EXTENDS Naturals              \* 自然数と + を使えるようにする

VARIABLES
  likes,                      \* DB に入っている「いいね数」
  pc                          \* 各リクエストがどこまで進んだか（"todo" → "done"）

Reqs == {"A", "B"}            \* リクエストは A と B の2つ

\* 最初の状態。
Init ==
  /\ likes = 0                          \* いいね数は 0
  /\ pc = [r \in Reqs |-> "todo"]       \* どのリクエストも、まだ何もしていない

\* 一手: リクエスト r が「今の値 + 1」を書く。読むのと書くのが同じ一手の中にある。
Incr(r) ==
  /\ pc[r] = "todo"                     \* r がまだ済んでいないときだけ起こせる
  /\ likes' = likes + 1                 \* この一手の直前の likes に 1 を足す（間に他人は割り込めない）
  /\ pc' = [pc EXCEPT ![r] = "done"]    \* r は終わり

\* 次に起こりうる一手: どれかのリクエストが Incr する。
Next == \E r \in Reqs : Incr(r)

\* 仕様の全体: Init から始まり、あとは Next の一手を繰り返す。
Spec == Init /\ [][Next]_<<likes, pc>>

\* 守ってほしい性質は、壊れている版と同じ。
NoLostUpdate == (\A r \in Reqs : pc[r] = "done") => likes = 2

=============================================================================
