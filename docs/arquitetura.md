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
3. Python chama `game:move_trace/5` (o `move/4` mais o caminho das peças) e calcula `moved`, `won`, `lost`.
4. Elm recebe a resposta. Se `moved`, **o Elm** sorteia a peça nova (`Random`: 2 com 90%, 4 com 10%) e atualiza o `Model`.
5. `view` desenha o novo `Model`. Efeitos (som, confete, recorde) saem por **ports**: o `update` devolve a lista de efeitos da jogada como dados (`Game.Effects.Effect`), e cada um vira um `Cmd` de port. O JavaScript executa.

> **É um ponto de partida, não uma lei.** Quem implementa a issue tem a palavra final sobre como fazer, desde que não quebre o `contrato.md` nem o que outras issues consomem. Mudou algo? Registre em *Desvios do planejado*, avise as issues que dependem e atualize este arquivo no mesmo PR.

## Estrutura de arquivos e donos

Um arquivo por responsabilidade, para duas issues não editarem o mesmo arquivo ao mesmo tempo.

### Prolog (`prolog/`)

| Arquivo | Conteúdo | Issue |
|---|---|---|
| `game.pl` | módulo `game`: `slide_left`, `move`, `available_moves`, `game_won`, `game_lost` e `move_trace` (caminho das peças). Também **reexporta** `hint/4` e `challenge/4` | #2, #3, #4, #8 (`move_trace`) |
| `hint.pl` | módulo `hint`: expectimax | #5 |
| `challenge.pl` | módulo `challenge`: CLP(FD) e busca | #19 |
| `test_game.pl`, `test_hint.pl`, `test_challenge.pl` | testes plunit de cada um | cada issue |

O Python continua chamando `game:hint(...)` e `game:challenge(...)`: o `game.pl` só faz `:- use_module(hint)` e reexporta. Assim o contrato não muda.

### Python (`server/`)

| Arquivo | Conteúdo | Issue |
|---|---|---|
| `main.py` | cria o `app`, validação (tipos `Board` e `Direction`, reusados pelo `extras.py`), handlers de erro, `POST /api/move` e serve a interface compilada (`web/dist`) se existir | #10 (move), #13 (estáticos) |
| `extras.py` | `APIRouter` com `/api/hint`, `/api/challenge`, `/api/challenges`; incluído por `main.py` | #11 |
| `data/challenges.json` | lista fixa de desafios | #11 |
| `test_main.py`, `test_extras.py` | testes pytest | cada issue |

### Scripts e automação (`scripts/`, `.github/`)

| Arquivo | Conteúdo | Issue |
|---|---|---|
| `scripts/rodar.sh` | compila a interface e sobe o servidor FastAPI num comando só | #13 |
| `.github/workflows/ci.yml` | CI com jobs de teste para Prolog, Python e Elm | #13 |
| `.github/pull_request_template.md` | template com checklist para PRs | #13 |

### Elm (`web/src/`)

`Main.elm` é só a **casca**: roteamento (`#/` e `#/apresentacao`), `Browser.application` e subscriptions. Ele **não** guarda regra de tela do jogo.

| Módulo | Conteúdo | Issue |
|---|---|---|
| `Game.elm` | `Model`, `Msg`, `update`, `init`, teclado, sorteio, tamanho, Novo jogo | #6 |
| `Game/History.elm` | histórico, desfazer e replay (funções puras sobre uma lista de estados; o `Game` guarda `Snapshot`s) | #7 |
| `Game/View.elm` | `view` do tabuleiro, placar, controles, temas, `Html.Keyed` (uma chave por peça, o `id`, numa vaga fixa) | #8 |
| `Ports.elm` + `web/src/*.js` | ports (`playSound`, `celebrate`, `saveBest`, `saveTheme`, `saveMuted`) e efeitos em `sons.js`, `confete.js` e `memoria.js` (`localStorage`); o `main.js` liga cada port e manda as preferências salvas nas flags | #9 |
| `Game/Effects.elm` | o tipo `Effect` (efeito como dado), `perform` (efeito vira `Cmd` de port) e o decoder das preferências das flags | #9 |
| `Api.elm` | cliente HTTP, decoders, `Http.Error` tratado | #6 (move), #20 (hint, challenge, erros) |
| `Game/Assist.elm` | dica, modo IA, desafios na interface | #20 |
| `Presentation.elm`, `Cenas/*` | motor da apresentação e as cenas | todas (uma cena cada) |

Regras de módulo:
- `Main` conhece `Game` e `Presentation`; um não conhece o outro.
- `Game.View` só lê o `Model`. Nada de HTTP nem `Random` na `view`.
- A apresentação reusa `Game.View` na `Demo`, então o jogo da cena é o jogo real.
- Quando uma issue precisar de campo novo no `Model`, adicione-o em `Game.elm` num PR pequeno e avise as issues que dependem dela.
- Campos da tela (#8): `theme` (`Dark | Light`), `pieces` (peças com `id`, posição, entrada, fantasma, idade e vaga), `nextId` e `slowMotion`. Novo jogo e troca de tamanho mantêm o tema.
- Campos das comemorações (#9): `best` (recorde por N, das flags), `muted`, `celebrated` (a partida já comemorou: o confete sai uma vez, mesmo com `won` seguindo `true`), `showWin` (tela de vitória) e `ranked` (falso nos tabuleiros prontos da apresentação, que não contam para o recorde). `Game.init` recebe as preferências salvas (recorde, tema e som), que o `main.js` lê do `localStorage` e manda nas flags.

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
| **Deslizar fluido das peças (#8)** | **Resolvido na #8: com `moves`.** O `move/4` não mudou. O predicado novo `move_trace/5` usa o próprio `move/4` e devolve também o caminho de cada peça, e o `/api/move` o manda no campo `moves` (contrato). O Elm só aplica o caminho: cada peça tem um `id` estável (chave do `Html.Keyed`) numa vaga fixa da lista de nós, e mudar a linha e a coluna faz a `transition` do CSS deslizá-la. A vaga fixa evita que o Elm mova nós (mover cancela a transição), a entrada da peça nunca muda (a animação não é cortada) e a fantasma de uma fusão fica três jogadas antes de sair. Sem `moves` na resposta, as peças são refeitas do tabuleiro. |
| **Replay determinístico (#7)** | Resolvido: o `Model` guarda em `history` o tabuleiro de antes de cada jogada, já com a peça sorteada, e o replay só mostra essa lista de novo, sem sortear nem chamar o Prolog. |
