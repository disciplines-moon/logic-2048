# Logic2048

2048 com **Prolog** no motor de regras e **Elm** na interface. Trabalho final de
Paradigmas de Programação. Veja o [planejamento](docs/planejamento.md).

```
prolog/   regras do jogo (SWI-Prolog) e testes plunit
server/   API em Python (FastAPI + janus) que chama o Prolog
web/      interface em Elm (Vite)
```

## Requisitos

SWI-Prolog >= 9.1.12, [uv](https://docs.astral.sh/uv/), Node.js e pnpm (ou npm).

## Rodando

Em dois terminais:

```bash
# API
cd server && uv run fastapi dev main.py --port 8000

# Interface (abre em http://localhost:5173)
cd web && pnpm install && pnpm dev
```

> **gcc 14+:** o `janus-swi` pode falhar ao compilar com
> `incompatible-pointer-types`. Se acontecer, prefixe o comando do `uv` com
> `CFLAGS="-Wno-error=incompatible-pointer-types"`.

## Testes

```bash
swipl -g "load_files('prolog/test_game.pl'),run_tests" -t halt   # Prolog
cd server && uv run pytest                                      # API
cd web && pnpm check                                            # Elm: formato, testes e build
```

## Estado atual

Esqueleto de ponta a ponta: as setas do teclado enviam o tabuleiro para
`POST /api/move`, que chama `game:move/4`. O Prolog ainda devolve o tabuleiro
sem alterações (veja os `TODO` em `prolog/game.pl` e `web/src/Main.elm`).
