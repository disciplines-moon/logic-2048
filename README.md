# Logic2048

2048 com **Prolog** no motor de regras e **Elm** na interface, em tabuleiros de
3×3 a 6×6. Trabalho final de Paradigmas de Programação (UnB, 2026/2).

- **Jogo completo:** mover e fundir nas 4 direções, pontos, vitória por tamanho,
  derrota, desfazer, replay, temas, sons, confete e recorde por tamanho.
- **Dica:** o Prolog escolhe a melhor jogada com expectimax (a peça nova nasce ao acaso).
- **IA que joga sozinha:** pede a dica ao Prolog e joga, com velocidade e pausa.
- **Desafios:** o Prolog acha a menor sequência de jogadas até uma peça alvo, com CLP(FD) e backtracking.
- **Apresentação embutida no app** (`#/apresentacao`), com o jogo funcionando dentro das cenas.

O relatório de entrega está em [`RELATORIO.md`](RELATORIO.md).

```
prolog/   regras do jogo, dica e desafios (SWI-Prolog) e testes plunit
server/   API em Python (FastAPI + janus) que só valida e chama o Prolog
web/      interface em Elm (Vite), a apresentação e os testes elm-test
docs/     contrato da API e dos predicados, arquitetura, planejamento, QA
scripts/  um comando para rodar tudo e o validador do relatório
```

| Documento | Conteúdo |
|---|---|
| [`RELATORIO.md`](RELATORIO.md) | Relatório de entrega: arquitetura, Prolog, Elm, testes, limitações, contribuições e uso de IA |
| [`docs/contrato.md`](docs/contrato.md) | Formato do tabuleiro, das rotas da API e dos predicados (fonte única de verdade) |
| [`docs/arquitetura.md`](docs/arquitetura.md) | Camadas, fluxo de uma jogada, arquivos e donos, decisões |
| [`docs/planejamento.md`](docs/planejamento.md) | Escopo, issues, equipe, cronograma e riscos |
| [`docs/apresentacao.md`](docs/apresentacao.md) | Como funciona a apresentação dentro do app e como escrever uma cena |
| [`docs/qa.md`](docs/qa.md) | Roteiro de QA, quem explica o quê e plano B para a apresentação |
| [`AGENTS.md`](AGENTS.md) | Regras do repositório e erros que já aconteceram (para pessoas e agentes de IA) |

## Versões das tecnologias

Todas testadas juntas (Ubuntu 26.04, Google Chrome). As versões exatas das
bibliotecas ficam travadas nos arquivos de `lock`: `uv sync` e `npm install`
instalam exatamente elas.

**Ferramentas do sistema**

| Ferramenta | Versão testada | Mínimo | Para quê |
|---|---|---|---|
| SWI-Prolog | 9.2.9 (a CI usa 10.0.2) | 9.1.12 | regras do jogo e a ponte `janus` com o Python |
| Python | 3.12.13 | 3.11 | API FastAPI |
| [uv](https://docs.astral.sh/uv/) | 0.11.25 | 0.5 | cria o ambiente Python e instala as dependências |
| Node.js | 22.22.1 | 20 | Vite, compilador Elm e testes da interface |
| npm | 11.18.0 | o que vem com o Node | dependências da interface (não use pnpm: há só `package-lock.json`) |
| gcc e cabeçalhos do SWI-Prolog | gcc 15.2, `libswipl-dev` | qualquer gcc | compilar o `janus-swi` na instalação |
| GNU Make | 4.4.1 | opcional | atalhos `make install`, `make test`... |
| Navegador | Google Chrome 155 | qualquer navegador moderno de desktop | a interface |

**Bibliotecas**

| Camada | Biblioteca | Versão |
|---|---|---|
| Prolog | SWI-Prolog com `library(clpfd)` (desafios) e `plunit` (testes), ambos embutidos | 9.2.9 |
| Python | FastAPI / Starlette | 0.162.0 / 1.10.0 |
| Python | pydantic / pydantic-core | 2.14.3 / 2.50.4 |
| Python | uvicorn (servidor) / fastapi-cli | 0.54.0 / 0.0.32 |
| Python | janus-swi (ponte com o Prolog) | 1.5.3 |
| Python (testes) | pytest / httpx | 9.2.0 / 0.28.1 |
| Elm | compilador `elm` | 0.19.3 (linguagem Elm 0.19.1) |
| Elm | `elm-test` / `elm-format` | 0.19.3 / 0.8.8 |
| Elm | pacotes (`web/elm.json`) | `elm/browser` 1.0.2, `elm/core` 1.0.5, `elm/html` 1.0.0, `elm/http` 2.0.0, `elm/json` 1.1.3, `elm/random` 1.0.0, `elm/svg` 1.0.1, `elm/time` 1.0.0, `elm/url` 1.0.0 |
| Elm (testes) | `elm-explorations/test` | 2.2.0 |
| Web | Vite / vite-plugin-elm | 8.3.6 / 3.0.1 |
| Web | JavaScript puro, sem bibliotecas: sons (Web Audio), confete (canvas) e recorde (`localStorage`) | `web/src/*.js` |
| CI | GitHub Actions com a imagem `swipl:10.0.2` (Prolog e Python) e Node 22 (Elm) | `.github/workflows/ci.yml` |

**Arquivos de dependências**

| Arquivo | Contém |
|---|---|
| `server/pyproject.toml` e `server/uv.lock` | FastAPI, janus-swi, pytest e httpx, com versões travadas |
| `web/package.json` e `web/package-lock.json` | Vite, vite-plugin-elm, elm, elm-test e elm-format (`overrides` força `cross-spawn` 7, por segurança) |
| `web/elm.json` | pacotes Elm |

Não edite os `lock` à mão: use `uv add` / `npm install` e faça commit do arquivo
que mudou.

## Como colocar o projeto para rodar

### 1. Instalar as ferramentas

```bash
# Ubuntu/Debian
sudo apt install swi-prolog swi-prolog-nox libswipl-dev build-essential python3-dev nodejs npm make
curl -LsSf https://astral.sh/uv/install.sh | sh        # uv

# macOS (Homebrew)
brew install swi-prolog node uv
xcode-select --install                                  # compilador, para o janus-swi

# Windows: use o WSL (Ubuntu) e siga a linha do Ubuntu dentro dele
```

Confira com `swipl --version` (precisa ser >= 9.1.12), `uv --version` e
`node --version`. Se o `apt` trouxer um SWI-Prolog antigo, use o PPA oficial
`swi-prolog/stable`.

### 2. Baixar e instalar as dependências

```bash
git clone https://github.com/disciplines-moon/logic-2048.git
cd logic-2048
make install          # o mesmo que: (cd server && uv sync) e (cd web && npm install)
```

Na primeira vez, o `uv sync` compila o `janus-swi`. Se falhar, veja
"Instalando o janus-swi", abaixo (com gcc 14 ou mais novo é quase certo que
precise do `CFLAGS`).

### 3. Rodar

**Um comando só** (compila a interface e o FastAPI serve a API e a interface
juntas):

```bash
make rodar            # o mesmo que: sh scripts/rodar.sh   (outra porta: sh scripts/rodar.sh 8010)
```

Abra `http://localhost:8000`. A apresentação fica em
`http://localhost:8000/#/apresentacao` (ou no botão **Apresentar**).

**Para desenvolver** (a interface recarrega sozinha ao salvar), em dois terminais:

```bash
# 1. API (http://localhost:8000)
cd server
uv run fastapi dev main.py --port 8000

# 2. Interface (http://localhost:5173)
cd web
npm run dev
```

Abra `http://localhost:5173`. `make dev` sobe os dois juntos (Ctrl+C encerra os
dois). Se a porta 8000 estiver ocupada, suba a API em outra e avise o Vite:

```bash
cd server && uv run fastapi dev main.py --port 8010
cd web && API_URL=http://localhost:8010 npm run dev
```

Depois de mudar algo em `prolog/` ou `server/`, reinicie a API e o `npm run dev`:
a apresentação mostra os arquivos como estavam quando o Vite subiu.

### Instalando o janus-swi

O `janus-swi` é a ponte entre o Python e o SWI-Prolog. O `uv sync` o compila na
primeira vez, contra o SWI-Prolog instalado, então precisa de gcc e dos
cabeçalhos do SWI-Prolog. Confira antes com `swipl --version` (>= 9.1.12).

| Sistema | Antes do `uv sync` |
|---|---|
| Ubuntu/Debian | `sudo apt install swi-prolog-nox libswipl-dev build-essential python3-dev` |
| macOS | `brew install swi-prolog` e `xcode-select --install` (compilador) |
| Windows | use o WSL (Ubuntu) e siga a linha do Ubuntu, dentro do WSL |

**gcc 14 ou mais novo** (Ubuntu 24.10+, Fedora 40+, Arch): a compilação falha com
`error: ... [-Wincompatible-pointer-types]`. Rode o `uv sync` assim:

```bash
cd server
CFLAGS="-Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types" uv sync
```

**`ImportError: libswipl.so...`** ou o janus quebrou depois de atualizar o
SWI-Prolog: o pacote foi compilado contra a versão antiga. Recompile ignorando o
cache do uv (com o `CFLAGS` acima, se o seu gcc for 14+):

```bash
cd server
uv sync --reinstall-package janus-swi --no-binary-package janus-swi --no-cache
```

Se o `swipl` não for achado, o SWI-Prolog não está no `PATH` (no macOS, confira
`brew --prefix swi-prolog`). Para conferir que a ponte funciona:
`uv run python -c "import janus_swi as j; print(j.query_once('X is 1+1'))"`, que
responde `{'truth': True, 'X': 2}`.

## Testes

```bash
make test             # tudo abaixo
make test-prolog      # plunit: prolog/test_game.pl, test_hint.pl e test_challenge.pl (164 testes)
make test-backend     # pytest da API, chamando o Prolog de verdade (55 testes)
make test-web         # elm-format, armadilhas conhecidas, elm-test (150 testes) e build
make validar          # forma do RELATORIO.md, com o validador do professor
```

Sem `make`, os mesmos comandos:

```bash
for f in prolog/test_*.pl; do swipl -g "load_files('$f'),run_tests" -t halt; done
cd server && uv run pytest
cd web && npm run check
uv run scripts/validar_entrega.py RELATORIO.md
```

A CI (`.github/workflows/ci.yml`) roda os testes do Prolog, o `pytest` e o
`npm run check` em todo PR. O roteiro de teste manual (cada funcionalidade de
3×3 a 6×6, e a apresentação sem rolagem) está em [`docs/qa.md`](docs/qa.md).

## Apresentação

A apresentação do trabalho é uma página do próprio app, em `#/apresentacao`
(também pelo botão **Apresentar** na tela inicial). Setas navegam, `W A S D`
jogam na demo, `n` mostra as notas com a foto e o nome de quem fala, e `f` abre a
tela cheia. Cada issue tem a sua cena em `web/src/Cenas/IssueNN.elm`, com código
real do repositório e o jogo funcionando. As fotos da equipe vêm do GitHub e
precisam de internet (sem rede, aparece a inicial). Detalhes em
[`docs/apresentacao.md`](docs/apresentacao.md).

## Estado atual

Todas as issues de funcionalidade estão entregues (#2 a #11, #13, #14, #19 e
#20):

| Camada | O que está pronto |
|---|---|
| Prolog | `slide_left/3`, `move/4` nas 4 direções para qualquer N, `game_won/1` (256, 2048, 4096 ou 8192 conforme o N), `game_lost/1`, `available_moves/2`, `move_trace/5` (caminho das peças para a animação), `hint/4` (expectimax) e `challenge/4` (CLP(FD) e busca) |
| Python | `POST /api/move`, `POST /api/hint`, `POST /api/challenge` e `GET /api/challenges`, com validação na borda e erros 422 em português |
| Elm | jogo de 3×3 a 6×6 com teclado e swipe, sorteio de peças, desfazer, replay, temas, deslize e fusão animados, sons, confete, recorde por tamanho, dica liga e desliga, IA que joga sozinha com velocidade e pausa, desafios passo a passo, mensagens de erro da API, e a apresentação |

Limitações conhecidas e o que faríamos com mais tempo estão na seção 9 do
[`RELATORIO.md`](RELATORIO.md).
