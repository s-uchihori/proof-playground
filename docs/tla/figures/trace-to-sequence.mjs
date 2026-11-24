#!/usr/bin/env node
// TLC の反例の出力（make tla-lost-update の出力）から、時系列の図（vlmkit-anim の sequence）と、
// その図が守るべき事実シートを作る。図の中身は、反例の各 State の値だけから決まる。手で足さない。
//
//   node trace-to-sequence.mjs <TLC の出力> <出力先（拡張子なし）>
//   → <出力先>.scene.json, <出力先>.expect.json
//
// TLC の出力の一手の名前は "Read" "Write" だけで、誰が動いたかは付かない。
// 一手の前後で pc（進み具合）が変わったリクエストを、動いた人とする。
import { readFileSync, writeFileSync } from 'node:fs';

const [tracePath, out] = process.argv.slice(2);
const text = readFileSync(tracePath, 'utf8');

// "State 2: <Read line 33, ...>" と、その下の "/\ 変数 = 値" を、State ごとに集める
const states = [];
for (const block of text.split(/\n(?=State \d+: )/).filter((b) => /^State \d+: /.test(b))) {
  const action = block.match(/^State \d+: <(\w+)/)[1];
  const val = (name) => block.match(new RegExp(`^/\\\\ ${name} = (.*)$`, 'm'))[1];
  const rec = (s) => Object.fromEntries([...s.matchAll(/(\w+) \|-> "?(\w+)"?/g)].map((m) => [m[1], m[2]]));
  states.push({ action, likes: Number(val('likes')), pc: rec(val('pc')), seen: rec(val('seen')) });
}
if (states.length < 2) throw new Error('no counterexample in the TLC output');

const reqs = Object.keys(states[0].pc);
const messages = [];
for (let i = 1; i < states.length; i++) {
  const [before, after] = [states[i - 1], states[i]];
  const moved = reqs.filter((r) => before.pc[r] !== after.pc[r]);
  if (moved.length !== 1) throw new Error(`State ${i + 1}: expected one request to move, got ${moved}`);
  const r = moved[0];
  if (after.action === 'Read') {
    messages.push({ from: r, to: 'db', label: `State ${i + 1}: 読む`, caption: `State ${i + 1}: ${r} が likes を読む` });
    messages.push({ from: 'db', to: r, label: `${after.seen[r]}`, kind: 'return',
      caption: `${r} の手元の値は ${after.seen[r]}` });
  } else {
    messages.push({ from: r, to: 'db', label: `State ${i + 1}: ${after.seen[r]} + 1 を書く`, kind: 'async',
      caption: `State ${i + 1}: ${r} が ${after.seen[r]} + 1 を書く。likes は ${after.likes}` });
  }
}
const last = states.at(-1);
messages.push({ note: `2つとも終わって likes = ${last.likes}`, at: 'db' });

const scene = {
  format: 'vlmkit-anim/scene@1',
  kind: 'sequence',
  title: "TLC の反例: リクエスト A と B の更新が消える手順",
  participants: [
    { id: reqs[0], label: `${reqs[0]}`, kind: 'actor' },
    { id: 'db', label: 'DB（likes）', kind: 'system' },
    ...reqs.slice(1).map((r) => ({ id: r, label: `${r}`, kind: 'actor' })),
  ],
  messages,
};
const expect = {
  format: 'vlmkit-anim/expect@1',
  nodes: [reqs[0], 'db', ...reqs.slice(1)],
  messages: messages.filter((m) => m.from).map((m) => `${m.from}->${m.to}:${m.label}`),
};
writeFileSync(`${out}.scene.json`, JSON.stringify(scene, null, 2) + '\n');
writeFileSync(`${out}.expect.json`, JSON.stringify(expect, null, 2) + '\n');
console.log(`${states.length} states → ${expect.messages.length} messages; final likes = ${last.likes}`);
