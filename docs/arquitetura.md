# Arquitetura do Logic2048

Este é o desenho que **todas as issues seguem**. Se precisar fugir dele, mude aqui
primeiro, em PR, e avise o grupo. O formato dos dados fica em `contrato.md`.

## Visão geral

```
Teclado ──▶ Elm (estado, sorteio, tela) ──HTTP/JSON──▶ Python (ponte) ──janus──▶ Prolog (regras)
                  ▲                                                                   │
                  └───────────────────── resposta (tabuleiro, score, flags) ◀─────────┘
```

| Camada | Paradigma | Faz | **Não** faz |
|---|---|---|---|
| Prolog | lógico, puro | mover, fundir, pontuar, vitória, derrota, dica, desafios | sortear, guardar estado, falar HTTP |
| Python | imperativo/OO | validar, chamar o Prolog, devolver JSON | regra de jogo |
| Elm | funcional | estado, sorteio de peças, histórico, tela, animações, ports | regra de jogo (pergunta ao Prolog) |

Regra de ouro: **uma regra de jogo existe em um só lugar, o Prolog.** O Elm
manda o tabuleiro e recebe o resultado; nunca recalcula o movimento.

## Fluxo de uma jogada

1. Elm recebe a tecla e monta `{board, direction}`.
2. `POST /api/move` leva ao Python, que valida (422 se inválido).
3. Python chama `game:move/4` e calcula `moved`, `won`, `lost`.
4. Elm recebe a resposta. Se `moved`, **o Elm** sorteia a peça nova (`Random`: 2 com 90%, 4 com 10%) e atualiza o `Model`.
5. `view` desenha o novo `Model`. Efeitos (som, confete, recorde) saem por **ports**.

> **É um ponto de partida, não uma lei.** Quem implementa a issue tem a palavra final sobre como fazer, desde que não quebre o `contrato.md` nem o que outras issues consomem. Mudou algo? Registre em *Desvios do planejado*, avise as issues que dependem e atualize este arquivo no mesmo PR.

## Estrutura de arquivos e donos

Um arquivo por responsabilidade, para duas issues não editarem o mesmo arquivo ao mesmo tempo.

### Prolog (`prolog/`)

| Arquivo | Conteúdo | Issue |
|---|---|---|
| `game.pl` | módulo `game`: `slide_left`, `move`, `available_moves`, `game_won`, `game_lost`. Também **reexporta** `hint/4` e `challenge/4` | #2, #3, #4 |
| `hint.pl` | módulo `hint`: expectimax | #5 |
| `challenge.pl` | módulo `challenge`: CLP(FD) e busca | #19 |
| `test_game.pl`, `test_hint.pl`, `test_challenge.pl` | testes plunit de cada um | cada issue |

O Python continua chamando `game:hint(...)` e `game:challenge(...)`: o `game.pl` só faz `:- use_module(hint)` e reexporta. Assim o contrato não muda.

### Python (`server/`)

| Arquivo | Conteúdo | Issue |
|---|---|---|
| `main.py` | cria o `app`, validação, handlers de erro, `POST /api/move` | #10 |
| `extras.py` | `APIRouter` com `/api/hint`, `/api/challenge`, `/api/challenges`; incluído por `main.py` | #11 |
| `data/challenges.json` | lista fixa de desafios | #11 |
| `test_main.py`, `test_extras.py` | testes pytest | cada issue |

### Elm (`web/src/`)

`Main.elm` é só a **casca**: roteamento (`#/` e `#/apresentacao`), `Browser.application` e subscriptions. Ele **não** guarda regra de tela do jogo.

| Módulo | Conteúdo | Issue |
|---|---|---|
| `Game.elm` | `Model`, `Msg`, `update`, `init`, teclado, sorteio, tamanho, Novo jogo | #6 |
| `Game/History.elm` | histórico, desfazer e replay (funções puras sobre `Game.Model`) | #7 |
| `Game/View.elm` | `view` do tabuleiro, placar, controles, temas, `Html.Keyed` | #8 |
| `Game/Ports.elm` + `web/src/*.js` | ports e efeitos (sons, confete, recorde) | #9 |
| `Api.elm` | cliente HTTP, decoders, `Http.Error` tratado | #6 (move), #20 (hint, challenge, erros) |
| `Game/Assist.elm` | dica, modo IA, desafios na interface | #20 |
| `Presentation.elm`, `Cenas/*` | motor da apresentação e as cenas | todas (uma cena cada) |

Regras de módulo:
- `Main` conhece `Game` e `Presentation`; um não conhece o outro.
- `Game.View` só lê o `Model`. Nada de HTTP nem `Random` na `view`.
- A apresentação reusa `Game.View` na `Demo`, então o jogo da cena é o jogo real.
- Quando uma issue precisar de campo novo no `Model`, adicione-o em `Game.elm` num PR pequeno e avise as issues que dependem dela.

## Convenções

- **Nomes:** código em inglês (`slide_left`, `Model`), texto para o usuário em português.
- **Tamanho:** o Elm e o Prolog aceitam N de 3 a 6; nada de `4` fixo.
- **Erros:** 422 e 500 sempre como `{"error": "..."}` (veja `contrato.md`).
- **Gerenciador de pacotes:** **npm** (há `package-lock.json`). Não use pnpm.
- **Testes:** `plunit` (Prolog), `pytest` (Python), `elm-test` (Elm). `npm run check` roda formato, armadilhas, testes e build do Elm.
- **Commits e PRs:** veja `AGENTS.md`.

## Decisões em aberto

| Tema | Situação |
|---|---|
| **Deslizar fluido das peças (#8)** | O contrato devolve só o tabuleiro final, sem identidade das peças, então dá para animar **aparecer** e **fundir** com `Html.Keyed`, mas o **deslizar** exige o Prolog devolver `moves: [{from,to,merged}]`. Decidir antes de a #3 fechar; afeta #3, #10, #6 e #8. Sem isso, a #8 entrega aparecer e fundir. |
| **Replay determinístico (#7)** | O replay deve guardar também as peças sorteadas, para não sortear de novo. Registrar no `Model`. |
