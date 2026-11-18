# Contrato do Logic2048

Fonte única de verdade entre Elm, Python e Prolog. Se algo mudar, mude aqui
primeiro, em PR, e avise o grupo. A estrutura de arquivos está em `arquitetura.md`.

## Tabuleiro

- Lista de N listas com N inteiros, com **N entre 3 e 6** (padrão 4).
- `0` é casa vazia. As outras casas são potências de 2 a partir de 2 (2, 4, 8...). O número 1 não vale.
- Direções: `left`, `right`, `up`, `down`.
- **Peça de vitória depende de N**, porque 2048 é inalcançável no 3×3:

  | N | 3 | 4 | 5 | 6 |
  |---|---|---|---|---|
  | Vitória | 256 | 2048 | 4096 | 8192 |

- Vitória: existe peça **>=** a peça de vitória do N. O jogo continua depois de vencer, e `won` continua `true` com peças maiores.
- Derrota: sem casas vazias e sem fusões possíveis.
- **Quem valida:** o Python rejeita (422) tabuleiro não quadrado, N fora de 3..6, valores negativos e qualquer número que não seja 0 nem potência de 2 a partir de 2. O Prolog assume entrada válida.

## Quem faz o quê

| Camada | Responsabilidade |
|---|---|
| Prolog | Regras puras: mover, fundir, pontuar, vitória, derrota, dica e desafios. Não sorteia nada. |
| Python | Valida a entrada, chama o Prolog (janus) e devolve JSON. Sem regras de jogo. |
| Elm | Estado da tela, sorteio de peças (`Random`: 2 com 90%, 4 com 10%), histórico, animações, ports (sons, confete, recorde). |

## API

Erros: toda entrada inválida devolve **HTTP 422** com `{ "error": "<mensagem>" }`
(o servidor troca o formato padrão `{"detail": ...}` do FastAPI). Falha inesperada
devolve **500** no mesmo formato. Não se usa 400. O Elm trata 422 mostrando a
mensagem e 500 ou rede com texto genérico. **Atenção:** `Http.expectJson` descarta
o corpo das respostas não 2xx (só entrega `BadStatus 422`). Para ler o
`{"error": ...}`, use `Http.expectStringResponse` e decodifique o corpo quando o
status for 422 (o `Api.rawResponse` já devolve status e corpo de qualquer resposta).

A mensagem é em português, porque o Elm a mostra a quem joga, e começa pelo campo
errado quando o erro é de um campo. Vários erros saem numa frase só, separados por `; `:

```
{ "error": "direction: use 'left', 'right', 'up' ou 'down'" }
{ "error": "board: valor inválido 3: use 0 ou uma potência de 2 a partir de 2" }
{ "error": "board[0][1]: deve ser um número inteiro" }
{ "error": "JSON inválido" }
```

Rota inexistente (404) e método errado (405) também respondem `{"error": ...}`. Um
corpo que o servidor nem consegue ler (por exemplo, um número com milhares de
dígitos) é entrada inválida: 422, nunca 400.

### `POST /api/move`

```json
{ "board": [[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], "direction": "left" }
```
```json
{ "board": [[4,0,0,0],[0,0,0,0],[4,0,0,0],[0,0,0,0]],
  "score": 4, "moved": true, "won": false, "lost": false,
  "moves": [ { "from": [0,0], "to": [0,0], "merged": true },
             { "from": [0,3], "to": [0,0], "merged": true },
             { "from": [2,1], "to": [2,0], "merged": false } ] }
```

`score` são os pontos ganhos **nesta jogada**. `moved` é `false` se nada mudou
(o Elm não sorteia peça nova).

`moves` (#8) é o caminho de cada peça do tabuleiro enviado: de onde saiu
(`from`, `[linha, coluna]` a partir de 0), onde chegou (`to`) e se entrou numa
fusão (`merged`; as duas peças de um par chegam à mesma casa). Peça que não andou
vem com `from` igual a `to`. Vem do `move_trace/5` do Prolog: o Elm só usa para
deslizar as peças na tela, sem calcular nada. Para o Elm, o campo é opcional: sem
ele, as peças só aparecem no lugar novo.

### `POST /api/hint`

```json
{ "board": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], "depth": 2 }
```
```json
{ "direction": "left", "depth": 2,
  "scores": { "left": 12.5, "right": 12.5, "down": 9.0 } }
```

`up` não aparece: com as peças na linha de cima, nada se move. `depth` é
opcional (padrão 2). O máximo é **3 para N <= 4 e 2 para N >= 5**, e valores
maiores devolvem 422. Para a dica não travar o servidor, o Python **reduz a
profundidade para 2** quando há mais de 6 casas vazias e devolve a profundidade
realmente usada no campo `depth` da resposta (pedir 3 com muitas vazias devolve
`"depth": 2`). Erros: `depth` fora de 1 a 3 dá
`{"error": "depth: use um número de 1 a 3"}`, e acima do limite do N dá
`{"error": "depth: no tabuleiro 5x5 o máximo é 2"}`. `direction` é `null` se
não há jogada. Direções sem movimento válido ficam fora de `scores`. Empate: vale
a primeira na ordem `left`, `right`, `up`, `down`.

### `GET /api/challenges`

Lista fixa em `server/data/challenges.json`:

```json
[ { "id": "c1", "title": "Chegue a 16 em 3 jogadas",
    "board": [[2,2,4,8],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    "target": 16, "max_moves": 3 } ]
```

### `POST /api/challenge`

```json
{ "board": [[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], "target": 8, "max_moves": 2 }
```
```json
{ "solvable": true, "moves": ["left", "left"] }
```

Sem solução: `{ "solvable": false, "moves": [] }`. Os três campos são
obrigatórios. `target` é uma potência de 2 a partir de 2 (senão 422:
`"target: use uma potência de 2 a partir de 2"`) e `max_moves` vai de 1 a 6
(`"max_moves: use um número de 1 a 6"`). Nos desafios **nenhuma peça
nova nasce**: só vale deslizar e fundir o que já está no tabuleiro.

Regras do desafio:
- Vence quando **alguma peça >= `target`** (não precisa ser igual).
- `moves` é a **menor** sequência encontrada, com **no máximo** `max_moves` jogadas (`max_moves` entre 1 e 6, senão 422). Entre sequências do mesmo tamanho, vale a primeira na ordem `left`, `right`, `up`, `down` (a mesma do `available_moves/2`).
- Jogada que não muda o tabuleiro não conta e nunca entra em `moves`.
- Se o tabuleiro **já** tem peça >= `target`, a resposta é `{ "solvable": true, "moves": [] }`. Os desafios de `challenges.json` começam sempre com todas as peças menores que `target`.
- Como a soma das peças não muda sem peças novas, `target` maior que a soma não tem solução.

## Predicados Prolog (`prolog/game.pl`)

```prolog
slide_left(+Row, -NewRow, -Points)
move(+Board, ?Dir, -NewBoard, -Score)      % se nada muda, devolve o mesmo tabuleiro com Score 0
                                           % det com Dir pronto; com Dir livre, enumera as 4 direções
move_trace(+Board, +Dir, -NewBoard, -Score, -Moves)   % o move/4 mais o caminho de cada peça (#8):
                                           % Moves = [[LinhaDe, ColunaDe, LinhaPara, ColunaPara, Fundiu], ...]
available_moves(+Board, -Dirs)             % só direções que mudam o tabuleiro
game_won(+Board)                           % usa a peça de vitória do N do tabuleiro
game_lost(+Board)
hint(+Board, +Depth, -Best, -Scores)       % Scores = [left-V1, right-V2, ...]; Best = none se não há jogada
challenge(+Board, +Target, +MaxMoves, -Moves)   % falha se não houver solução
```

Conversões na fronteira (feitas no Python, em `server/extras.py`, testadas em `server/test_extras.py`):
`Scores` vira objeto JSON, `Best = none` vira `null`, e a falha de `challenge`
vira `{"solvable": false, "moves": []}`. O janus converte strings Python em
átomos, então `direction` chega ao Prolog como `left`, `right`, `up` ou `down`.
Listas e inteiros passam como estão. Na volta, `janus.query_once` devolve um `dict`
com as variáveis ligadas e `"truth"` (`False` quando o objetivo falha), e um par
Prolog `left-12.5` vira a tupla Python `("left", 12.5)`. O átomo `true` do
`move_trace/5` chega como a string `"true"`, e o Python o troca pelo booleano do `merged`.

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

## Trabalhar em paralelo com stubs

O esqueleto começou só com o `POST /api/move`, e o `move/4` de verdade chegou na #3,
então ninguém precisa esperar a issue anterior para começar. Os outros endpoints são criados
pelas issues #11 e #10, e o Elm pode usar os JSONs deste arquivo como mock:

- **Elm:** use os JSONs de exemplo deste arquivo como respostas da API (por exemplo, uma função `mock` em `Api.elm`) e troque pela API real ao integrar.
- **Python:** `/api/move` já devolve resultados reais com o `move/4` da #3, sem nenhuma mudança no Python. A validação e os handlers de erro ficaram prontos na #10: rotas novas usam o tipo `Board` do `main.py`, e os handlers do `app` já valem para elas.
- **Prolog:** cada predicado novo precisa estar no `:- module(game, [...])` de `prolog/game.pl`, senão os testes não o enxergam.
