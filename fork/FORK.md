# 이 fork의 운영 지침

이 문서는 `tt-a1i/archify`를 fork해서 `custom` branch에서 고쳐 쓰는 방법을 적는다. 원본 레포의 문서가 아니고, 원본에 PR을 올리지 않는 것을 전제로 한다. 2026-11-18 작성, 기준 upstream commit `44781293`.

## 구조

- `origin`은 이 fork(`kanggihoo/archify`), `upstream`은 원본(`tt-a1i/archify`)이다.
- 작업은 `custom` branch에서 한다. `main`은 upstream을 따라가는 용도로만 둔다.
- `fork/`는 이 fork에만 있는 파일을 모은 폴더다. `prune.list`(지울 경로), `prune.mjs`(지우는 스크립트), `link-install.ps1`(junction 설치), `CHANGES.md`(변경 기록), 이 문서가 있다.
- 분석 기록은 `oss-analysis` 작업 공간의 `visualization/reports/archify/next.md` 5.7절에 있다.

## 우리가 바꾼 것

변경 항목, 쓰는 법, 바꾼 파일, 확인한 것, 한계는 [CHANGES.md](CHANGES.md)에 있다. 요약은 아래와 같다.

| ID | 변경 | 주요 파일 |
|---|---|---|
| C1 | `[라벨](page:파일.html)` 링크 | `archify/explainer/inline.mjs` |
| C2 | `@steps` detail의 `**라벨**` 행 렌더 | `archify/explainer/step-fields.mjs`(새 파일), `render.mjs`, `reader.css` |
| P1 | 안 쓰는 폴더 삭제 | `fork/prune.list` |

upstream이 C1, C2의 파일을 고치면 진짜 conflict가 난다. 이것은 스크립트로 풀 수 없고 사람이 읽고 합쳐야 한다(아래 3번). 새 변경을 하면 `CHANGES.md`에 항목을 추가한다.

## 지운 것 (`fork/prune.list`)

`journal/`, `integrations/`, `.agents/`, `community/`와, 이 폴더가 없으면 실패하는 `test/archify-tuning.test.mjs`, `test/community-packages.test.mjs`, `scripts/check-community-packages.mjs`.

- 지운 이유: 이 fork의 용도(explainer 렌더 커스텀)에 쓰지 않는다.
- 일부러 남긴 것: `.github/`(CI 정의를 읽는 테스트 6개가 의존한다), `docs/`(코드가 가장 많이 언급한다), `website/`, `LICENSE`, `LICENSE-MIT`, `NOTICE`, `THIRD_PARTY_NOTICES.md`(Apache-2.0 고지라 지우지 않는다).
- `website/test/`는 `community/`에 의존하므로 깨진다. 루트 `package.json`의 테스트 스크립트에는 `website`가 들어 있지 않아서 `npm test`에는 영향이 없다. website 테스트는 돌리지 않는다.

## upstream을 가져오는 방법

1. 변경 사항을 먼저 `commit`한다. working tree가 더러우면 merge를 시작하지 않는다.
2. 가져온다.
   ```
   git fetch upstream
   git merge upstream/main
   ```
3. conflict가 나면 종류를 구분한다.

   | 상황 | 보이는 표시 | 처리 |
   |---|---|---|
   | 지운 경로를 upstream이 수정했다 | `deleted by us` / `CONFLICT (modify/delete)` | `node fork/prune.mjs`가 해당 경로를 지우고 해결한다 |
   | upstream이 지운 폴더 안에 새 파일을 추가했다 | 조용히 다시 생긴다 | 같은 `node fork/prune.mjs`로 다시 지운다 |
   | 우리가 고친 파일을 upstream도 고쳤다 | 파일 안에 `<<<<<<<` | 직접 합친다. 아래 4번을 본다 |
   | `package-lock.json`, `archify/assets/template.html` 같은 생성 파일 | conflict | 원본 쪽을 받고 다시 생성한다(`npm ci`, `npm --prefix archify run generate:viewer`) |

4. `node fork/prune.mjs` 실행 후에도 `git status`에 conflict가 남아 있다면 그것은 진짜 코드 conflict다. `inline.mjs`, `render.mjs`, `reader.css`, `explainer-authoring.md`가 대상이다. 합칠 때 지킬 것은 아래 두 가지다.
   - `inline.mjs`의 `referenceFor`에 있는 `page:` 분기와 `renderInline`의 `page` 렌더 분기를 남긴다.
   - `render.mjs`의 `stepDetail` 호출과 `step-fields.mjs` import를 남긴다.
5. 끝나면 확인한다.
   ```
   node fork/prune.mjs --check        # 지운 경로가 다시 추적되는지 (exit 0이어야 한다)
   npm ci --ignore-scripts
   npm --prefix archify ci --ignore-scripts
   npm run test:generated
   node --test test/explainer-*.test.mjs
   npm run test:core
   ```
6. 통과하면 `commit`한다.

## 설치 (AI가 이 fork를 쓰게 하는 방법)

AI는 `~/.agents/skills/archify`(`~/.claude/skills/archify`는 그 링크)를 읽고 그 안의 CLI로 렌더한다. 이 위치를 아래 둘 중 하나로 채운다. 설치와 교체는 사용자가 요청할 때만 한다(루트 `AGENTS.md`).

**방법 1. GitHub의 `custom` branch에서 `npx skills`로 설치**

```
npx skills add https://github.com/kanggihoo/archify/tree/custom/archify -g
```

- push한 commit의 snapshot이 설치된다. 고친 내용이 AI에 닿으려면 `git push origin custom` 후 `npx skills update archify`가 필요하다.
- 고치다 만 상태가 AI에 새지 않는다.
- 설치 전에 `npx -y skills add <같은 URL> --list --full-depth`로 skill이 정확히 하나(`archify`)인지 확인한다(루트 `AGENTS.md` 규칙).
- `npx skills update`가 `custom` branch를 따라가는지는 확인하지 않았다.
- 이미 `~/.agents/skills/archify`가 junction이면 먼저 `pwsh fork/link-install.ps1 uninstall`로 연결을 지운다.

**방법 2. junction으로 이 checkout을 직접 연결**

```
pwsh fork/link-install.ps1 status
pwsh fork/link-install.ps1 install      # 실제 폴더가 있으면 -Force가 필요하다
pwsh fork/link-install.ps1 uninstall
```

- 복사본이 없어서 이 checkout을 고치는 즉시 AI에 반영된다. 대신 working tree가 그대로 노출된다. 평소에는 `custom`을 checkout한 채로 두고, 실험은 `git worktree`로 다른 폴더에서 한다.
- 연결은 `archify/` 폴더만 가리킨다. `fork/`, `viewer/`, `scripts/`, `test/`는 AI에게 보이지 않는다.
- `npx skills update archify`는 돌리지 않는다. junction을 덮어쓰거나 거부하는지 확인하지 않았다.
- junction은 `rm -rf`로 지우지 않는다. 연결 대상 파일이 지워질 수 있다. `link-install.ps1 uninstall`을 쓴다.
- 이 checkout의 경로를 옮기면 연결이 끊어진다.

두 방법 모두 적용한 뒤에는 새 세션에서 `page:` 링크가 `validate`를 통과하는지 확인한다.

## 되돌리기

- 지운 폴더를 다시 보고 싶으면: `git checkout upstream/main -- journal`처럼 한 폴더씩 가져온다. 그 폴더를 계속 두려면 `fork/prune.list`에서 줄도 지운다.
- 지운 폴더를 쓰던 테스트까지 되살리려면 위 `prune.list`의 "Tests and scripts" 줄에서 해당 파일도 같이 가져온다.

## 환경 메모

- 이 PC는 Git Bash를 쓴다. `git sparse-checkout`처럼 `/폴더/` 모양의 인자를 줄 때는 `MSYS_NO_PATHCONV=1`을 앞에 붙인다. 안 붙이면 `C:/Program Files/Git/폴더/`로 바뀐다.
- `node_modules`는 루트와 `archify/` 둘 다에 `npm ci --ignore-scripts --no-audit --no-fund`로 설치한다. `archify/`의 `simple-icons`가 없으면 `test:generated`의 `check:brand-marks`가 실패한다.
- `npm run test:full`은 오래 걸린다(25분 넘게 끝나지 않았다). 평소에는 위 5번의 세 가지만 돌린다.
- `test/browser-gate.test.mjs`는 upstream 상태에서도 2개가 실패한다(baseline). 우리 변경이 원인이 아니다.
- 설치된 skill(`~/.claude/skills/archify`)은 이 fork와 별개다. 이 fork의 CLI(`archify/bin/archify.mjs`)로 렌더해야 `page:` 링크와 `@steps` 라벨 행이 동작한다. 설치본을 바꾸는 것은 사용자가 명시적으로 요청할 때만 한다(루트 `AGENTS.md` 규칙).
