# Contrato do Logic2048

Fonte única de verdade entre Elm, Python e Prolog. Se algo mudar, mude aqui
primeiro, em PR, e avise o grupo.

## Tabuleiro

- Lista de N listas com N inteiros, com **N entre 3 e 6** (padrão 4).
- `0` é casa vazia. As outras casas são potências de 2 (2, 4, 8...).
- Direções: `left`, `right`, `up`, `down`.
- Vitória: existe peça >= 2048. O jogo continua depois de vencer.
- Derrota: sem casas vazias e sem fusões possíveis.

## Quem faz o quê

| Camada | Responsabilidade |
|---|---|
| Prolog | Regras puras: mover, fundir, pontuar, vitória, derrota, dica e desafios. Não sorteia nada. |
| Python | Valida a entrada, chama o Prolog (janus) e devolve JSON. Sem regras de jogo. |
| Elm | Estado da tela, sorteio de peças (`Random`: 2 com 90%, 4 com 10%), histórico, animações, ports (sons, confete, recorde). |

## API

Erros: HTTP 400/422 com `{ "error": "<mensagem>" }`.

### `POST /api/move`

```json
{ "board": [[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], "direction": "left" }
```
```json
{ "board": [[4,0,0,0],[0,0,0,0],[4,0,0,0],[0,0,0,0]],
  "score": 4, "moved": true, "won": false, "lost": false }
```

`score` são os pontos ganhos **nesta jogada**. `moved` é `false` se nada mudou
(o Elm não sorteia peça nova).

### `POST /api/hint`

```json
{ "board": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], "depth": 2 }
```
```json
{ "direction": "left",
  "scores": { "left": 12.5, "right": 12.5, "up": 9.0, "down": 9.0 } }
```

`depth` é opcional (padrão 2, máximo 3). `direction` é `null` se não há jogada.
Direções sem movimento válido ficam fora de `scores`.

### `GET /api/challenges`

Lista fixa em `server/data/challenges.json`:

```json
[ { "id": "c1", "title": "Chegue a 16 em 3 jogadas",
    "board": [[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    "target": 16, "max_moves": 3 } ]
```

### `POST /api/challenge`

```json
{ "board": [[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], "target": 8, "max_moves": 2 }
```
```json
{ "solvable": true, "moves": ["left", "left"] }
```

Sem solução: `{ "solvable": false, "moves": [] }`. Nos desafios **nenhuma peça
nova nasce**: só vale deslizar e fundir o que já está no tabuleiro.

## Predicados Prolog (`prolog/game.pl`)

```prolog
slide_left(+Row, -NewRow, -Points)
move(+Board, +Dir, -NewBoard, -Score)      % se nada muda, devolve o mesmo tabuleiro com Score 0
available_moves(+Board, -Dirs)             % só direções que mudam o tabuleiro
game_won(+Board)
game_lost(+Board)
hint(+Board, +Depth, -Best, -Scores)       % Scores = [left-V1, right-V2, ...]
challenge(+Board, +Target, +MaxMoves, -Moves)   % falha se não houver solução
```

## Exemplos de `slide_left`

| Entrada | Saída | Pontos |
|---|---|---|
| `[2,2,2,2]` | `[4,4,0,0]` | 8 |
| `[2,0,2,4]` | `[4,4,0,0]` | 4 |
| `[4,2,2,0]` | `[4,4,0,0]` | 4 |
| `[2,4,8,16]` | `[2,4,8,16]` | 0 |

Cada peça funde no máximo uma vez por jogada.

## Definição de pronto (vale para toda issue)

- Testes passando (`plunit`, `pytest` ou `elm-test`) e código formatado.
- Documentação atualizada neste arquivo, se o contrato mudou.
- PR com `Closes #N`, aprovado pelo revisor designado.
- Quem implementou **consegue explicar** a issue na apresentação, em especial o
  papel do paradigma (veja "Para explicar" em cada issue).
