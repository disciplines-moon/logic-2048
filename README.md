# Logic2048

2048 com **Prolog** no motor de regras e **Elm** na interface. Trabalho final de
Paradigmas de Programação. Veja o [planejamento](docs/planejamento.md).

```
prolog/   regras do jogo (SWI-Prolog) e testes plunit
server/   API em Python (FastAPI + janus) que chama o Prolog
web/      interface em Elm (Vite)
```

## Apresentação

A apresentação do trabalho é uma página do próprio app, em
`http://localhost:5173/#/apresentacao` (também pelo botão **Apresentar** na tela
inicial). Setas navegam, `W A S D` jogam, `n` mostra as notas e `f` abre a tela
cheia. Detalhes em [`docs/apresentacao.md`](docs/apresentacao.md).

## O que cada pessoa faz

Cada issue entrega **código e a própria cena da apresentação**. Rode o projeto,
abra `#/apresentacao`, ache a cena marcada como pendente da sua issue e preencha
`web/src/Cenas/IssueNN.elm` (passos, anotações e código real ou demo). O passo a
passo está na seção "Por onde começar" de cada issue e em `docs/apresentacao.md`.

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

### Instalando as ferramentas

```bash
# Ubuntu/Debian
sudo apt install swi-prolog swi-prolog-nox libswipl-dev build-essential nodejs npm
curl -LsSf https://astral.sh/uv/install.sh | sh        # uv

# macOS (Homebrew)
brew install swi-prolog node uv
```

Confira com `swipl --version`, `uv --version` e `node --version`. Se o
`apt` trouxer um SWI-Prolog antigo (< 9.1.12), use o PPA oficial `swi-prolog/stable`.

## Versões das stacks (as do `lock`, testadas)

| Camada | Biblioteca | Versão |
|---|---|---|
| Prolog | SWI-Prolog (com `clpfd` e `plunit`) | 9.2.9 |
| Python | FastAPI / pydantic / uvicorn | 0.162.0 / 2.14.3 / 0.54.0 |
| Python | janus-swi (ponte com o Prolog) | 1.5.3 |
| Python (testes) | pytest / httpx | 9.2.0 / 0.28.1 |
| Elm | compilador `elm` / `elm-test` / `elm-format` | 0.19.3 / 0.19.3 / 0.8.8 |
| Elm | pacotes (`elm.json`) | browser 1.0.2, core 1.0.5, html 1.0.0, http 2.0.0, json 1.1.3, random 1.0.0, svg 1.0.1, time 1.0.0, url 1.0.0 |
| Web | Vite / vite-plugin-elm | 8.3.6 / 3.0.1 |

As versões exatas ficam nos arquivos abaixo; `uv sync` e `npm install` instalam
exatamente elas.

## Arquivos de dependências

| Arquivo | Contém |
|---|---|
| `server/pyproject.toml` e `server/uv.lock` | FastAPI, janus-swi, pytest e httpx, com versões travadas |
| `web/package.json` e `web/package-lock.json` | Vite, vite-plugin-elm, elm, elm-test e elm-format (`overrides` força `cross-spawn` 7, por segurança) |
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
`http://localhost:5173/#/apresentacao` (as fotos da equipe vêm do GitHub e precisam de internet).

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
sem alterações (veja os `TODO` em `prolog/game.pl` e `web/src/Game.elm`).
