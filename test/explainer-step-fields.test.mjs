import test from 'node:test';
import assert from 'node:assert/strict';
import {splitStepFields} from '../archify/explainer/step-fields.mjs';

test('a detail that opens with bold labels splits into ordered fields',()=>{
  const fields=splitStepFields('**입력** 사용자 요청 · **참조** `SKILL.md` · **출력** 모드 결정. **처리** 에이전트가 고른다.[](source:a) **다음** 끝난다.');
  assert.deepEqual(fields,[
    {label:'입력',text:'사용자 요청'},
    {label:'참조',text:'`SKILL.md`'},
    {label:'출력',text:'모드 결정.'},
    {label:'처리',text:'에이전트가 고른다.[](source:a)'},
    {label:'다음',text:'끝난다.'}
  ]);
});

test('ordinary details, a single label and bold inside code or prose are left alone',()=>{
  assert.equal(splitStepFields('평범한 설명이다.'),null);
  assert.equal(splitStepFields('**입력** 하나뿐이다.'),null);
  assert.equal(splitStepFields('설명 **입력** 중간 굵게 **출력** 둘'),null);
  const fields=splitStepFields('**입력** `a **b** c` 값 · **출력** **아주 긴 문장은 라벨이 아니다** 이어짐');
  assert.deepEqual(fields.map(f=>f.label),['입력','출력']);
  assert.match(fields[0].text,/`a \*\*b\*\* c` 값/);
  assert.match(fields[1].text,/\*\*아주 긴 문장은 라벨이 아니다\*\* 이어짐/);
});
