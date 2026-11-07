# Logic2048

2048 com **Prolog** no motor de regras e **Elm** na interface. Trabalho final de
Paradigmas de Programação. Veja o [planejamento](docs/planejamento.md).

```
prolog/   regras do jogo (SWI-Prolog) e testes plunit
server/   API em Python (FastAPI + janus) que chama o Prolog
web/      interface em Elm (Vite)
```

## Requisitos do sistema

| Ferramenta | Versão | Para quê |
|---|---|---|
| SWI-Prolog | >= 9.1.12 (testado com 9.2.9) | regras do jogo e ponte `janus` |
| Python | >= 3.11 (testado com 3.14) | API FastAPI |
| [uv](https://docs.astral.sh/uv/) | >= 0.5 | cria o ambiente Python e instala as dependências |
| Node.js | >= 20 (testado com 22) | Vite, Elm e testes da interface |
| gcc e cabeçalhos do SWI-Prolog | `swi-prolog-nox` ou equivalente com `-dev` | compilar o `janus-swi` |

Navegador moderno para a interface (desktop). Linux e macOS são os alvos; no
Windows, use WSL.

## Arquivos de dependências

| Arquivo | Contém |
|---|---|
| `server/pyproject.toml` e `server/uv.lock` | FastAPI, janus-swi, pytest e httpx, com versões travadas |
| `web/package.json` e `web/package-lock.json` | Vite, vite-plugin-elm, elm, elm-test e elm-format |
| `web/elm.json` | pacotes Elm (browser, html, http, json, random, svg, time, url) |

Não edite os `lock` à mão: use `uv add` / `npm install` e faça commit do arquivo
que mudou.

## Como rodar

Com SWI-Prolog, uv e Node instalados, em **dois terminais**:

```bash
# 1. API (http://localhost:8000). Na primeira vez o uv compila o janus-swi.
cd server
uv sync
uv run fastapi dev main.py --port 8000

# 2. Interface (http://localhost:5173)
cd web
npm install
npm run dev
```

Abra `http://localhost:5173`. A apresentação fica em
`http://localhost:5173/#/apresentacao`.

Se a porta 8000 estiver ocupada, suba a API em outra e avise o Vite:

```bash
cd server && uv run fastapi dev main.py --port 8010
cd web && API_URL=http://localhost:8010 npm run dev
```

Build de produção da interface: `cd web && npm run build` (saída em `web/dist`).

> **gcc 14+:** o `janus-swi` pode falhar ao compilar com
> `incompatible-pointer-types`. Se acontecer, rode o `uv sync` assim:
> `CFLAGS="-Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types" uv sync`.

## Testes

```bash
swipl -g "load_files('prolog/test_game.pl'),run_tests" -t halt   # Prolog
cd server && uv run pytest                                      # API
cd web && npm run check                                          # Elm: formato, testes e build
```

## Estado atual

Esqueleto de ponta a ponta: as setas do teclado enviam o tabuleiro para
`POST /api/move`, que chama `game:move/4`. O Prolog ainda devolve o tabuleiro
sem alterações (veja os `TODO` em `prolog/game.pl` e `web/src/Main.elm`).
