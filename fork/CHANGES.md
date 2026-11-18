# 변경 기록 (upstream과 달라진 점)

기준 upstream: `tt-a1i/archify` `44781293`(2026-11-17). 새로 바꿀 때마다 아래에 항목을 추가한다. 병합 방법은 [FORK.md](FORK.md)에 있다.

## C1. explainer 페이지 링크 `page:` (2026-11-18)

**왜**: explainer는 다른 HTML 파일로 가는 링크를 만들 수 없었다. 개요 1개와 상세 여러 개로 나눈 문서(예: `security-audit.html`과 `security-audit.setup.html` 등 10개)가 별도 색인 페이지를 거쳐야 서로 이동했다.

**쓰는 법**
```
[설정 페이지](page:security-audit.setup.html)
```
- 같은 폴더의 `.html` 파일 이름만 받는다. 디렉터리(`dir/x.html`), `..`, 맨 앞 `.`, 쿼리(`?q=`), 앵커(`#a`), `.html`이 아닌 확장자, 공백은 거부한다.
- 렌더는 `<a class="page-link" href="파일명.html">라벨</a>`이고 `target`이 없어 같은 탭에서 열린다.
- 파일이 실제로 있는지는 검사하지 않는다.
- 원래 있던 거부 메시지는 `… route, page or typical destination`으로 바뀌었다.

**바꾼 파일**
- `archify/explainer/inline.mjs`: `referenceFor`에 `page:` 분기와 `pageFile` 정규식, `renderInline`에 `page` 렌더 분기, 오류 문구
- `archify/references/explainer-authoring.md`: "Inline links and sources"에 한 문장
- `test/explainer-inline.test.mjs`: 테스트 1개(허용 2건, 거부 11건)

**건드리지 않은 곳**: `validate.mjs`, `prepare.mjs`, `check.mjs`. 링크 종류 검사가 `page`를 무시하고 `check.mjs`가 상대 href를 막지 않아 그대로 통과한다.

**확인**: `finalize explainer --quality showcase`로 `skill-explainers/cloudflare/security-audit`의 10개 페이지를 렌더해 통과. 링크 67개가 모두 같은 폴더의 실제 파일을 가리킴을 스크립트로 확인. 개요 `browser-check` 통과.

**한계**: 링크를 눌러 이동하는 동작은 브라우저에서 사람이 확인하지 않았다. 팝업(`<dialog>`로 여는 방식)은 만들지 않았다. 이미지·PDF 내보내기에서의 모양은 확인하지 않았다.

**upstream conflict 위험**: 중간. `inline.mjs`는 upstream이 고칠 수 있다. 병합 때 `page:` 분기와 렌더 분기가 남았는지 본다.

## C2. `@steps` 라벨 행 (2026-11-18)

**왜**: `@steps`의 detail은 문단 하나라서 `**입력** … · **참조** … · **출력** …`를 AI가 굵은 글씨로 흉내 낸 한 덩어리로 읽기 어려웠다.

**쓰는 법**: detail이 짧은 굵은 라벨로 시작하면 라벨 행으로 렌더된다.
```
| s-mode | 모드 판단? | **입력** 사용자 요청 · **참조** `SKILL.md` · **출력** 모드 결정. **처리** … **다음** … | audit-flow | mode |
```
- 조건: detail이 `**라벨**`로 시작하고 라벨이 2개 이상. 라벨은 8자 이하, 공백·backtick·`*` 없음, 뒤에 공백이나 끝이 와야 한다.
- 라벨 사이의 텍스트가 그 필드다. 필드 끝의 `·`와 공백은 뗀다. backtick 코드 안의 `**`는 라벨로 보지 않는다.
- 그 밖의 detail(라벨이 하나뿐인 경우 포함)은 이전처럼 문단 하나다.
- 렌더: `<dl class="step-fields"><div><dt>라벨</dt><dd>내용</dd></div>…</dl>`.

**바꾼 파일**
- `archify/explainer/step-fields.mjs`(새 파일): `splitStepFields`
- `archify/explainer/render.mjs`: `import`와 `stepDetail` 함수, steps 케이스가 이를 호출
- `archify/explainer/reader.css`: `.steps .step-fields` 스타일, walk 때 흐리게 하는 선택자에 `dl` 추가
- `archify/references/explainer-authoring.md`: `@steps` 설명 문단 하나
- `test/explainer-step-fields.test.mjs`(새 파일): 테스트 2개

**건드리지 않은 곳**: 문법과 스키마(`parse.mjs`)는 그대로다. 렌더할 때만 변환하므로 `validate`·`check`가 달라지지 않는다.

**확인**: 단위 테스트 2개와 explainer 관련 8개 파일 71개 통과. `candidate.archify.md`(원고 수정 없음)를 `finalize --browser-check`로 렌더해 통과, step 10개가 모두 라벨 행으로 렌더됨. headless Chrome 스크린샷으로 1단계 모양 확인.

**한계**: 2~10단계의 모양, 라이트 테마, 좁은 화면, "Step through" 동작은 눈으로 확인하지 않았다. 라벨 폭은 48px 고정이라 긴 영어 라벨은 잘릴 수 있다.

**upstream conflict 위험**: 낮음~중간. `render.mjs`의 steps 케이스와 `reader.css`의 `.steps` 규칙을 upstream이 고치면 합쳐야 한다.

## P1. 안 쓰는 폴더 삭제 (2026-11-18)

`journal/`, `integrations/`, `.agents/`, `community/`와 의존 테스트·스크립트 3개(`test/archify-tuning.test.mjs`, `test/community-packages.test.mjs`, `scripts/check-community-packages.mjs`)를 지웠다. 목록은 `fork/prune.list`, 스크립트는 `fork/prune.mjs`. 남긴 것과 이유는 [FORK.md](FORK.md).

## I1. 설치 스크립트 `fork/link-install.ps1` (2026-11-18)

`~/.agents/skills/archify`를 이 fork의 `archify/` 폴더로 연결(junction)하거나 해제한다. `status`, `install`, `uninstall`. 실제 폴더는 `-Force` 없이는 교체하지 않는다. GitHub branch에서 `npx skills`로 설치하는 방법과의 비교는 [FORK.md](FORK.md)의 "설치".

## AI가 이 변경을 알게 되는 경로

AI는 설치된 archify skill의 문서를 읽고, 설치된 CLI로 렌더한다. 이 fork의 변경이 AI에게 닿으려면 아래 세 지점이 맞아야 한다.

| 지점 | 무엇 | 지금 상태 |
|---|---|---|
| `archify/SKILL.md` | explainer 문법은 `references/explainer-authoring.md`를 읽으라고만 안내한다(24행). 문법 자체는 적혀 있지 않다 | 바꾸지 않았다. upstream이 자주 고치는 파일이라 conflict를 줄이려고 일부러 건드리지 않는다 |
| `archify/references/explainer-authoring.md` | AI가 읽는 문법 문서 | fork에서 C1, C2를 반영했다 |
| 어느 사본을 읽고 실행하나 | 설치본 `~/.agents/skills/archify`(`~/.claude/skills/archify`는 그 링크) 또는 이 fork | **설치본에는 변경이 없다.** 설치본 CLI는 `page:`를 거부한다. 렌더할 때 이 fork의 `archify/bin/archify.mjs`를 써야 한다 |

설치본을 이 fork로 바꾸는 것은 루트 `AGENTS.md` 규칙상 사용자가 명시적으로 요청할 때만 한다. 설치하지 않고 쓰려면 AI에게 지시하는 문서(예: `skills-analize/EXPLAINER-PROMPT.md`의 5행 문서 경로와 230행 CLI 경로)가 이 fork의 경로를 가리키게 해야 한다.
