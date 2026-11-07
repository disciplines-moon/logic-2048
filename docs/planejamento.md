# Logic2048: planejamento

Trabalho final de Paradigmas de Programação (34% da nota). Grupo de 7 pessoas.
Jogo 2048 com **Prolog** no motor de regras e **Elm** na interface.

## Objetivo

Implementar o 2048 de forma que cada paradigma tenha um papel claro:

| Camada | Tecnologia | Responsabilidade |
|---|---|---|
| Interface | Elm (TEA) + Vite | Tabuleiro, entrada do teclado, estado da tela, sorteio de novas peças |
| Ponte | Python (`uv`) | Servidor HTTP que recebe JSON e chama o Prolog |
| Regras | SWI-Prolog (>= 9.1.12) | Mover, fundir, pontuar, detectar vitória e derrota |

## Arquitetura

```
Teclado ──> Elm ──(JSON/HTTP)──> Python ──(janus)──> Prolog
              ^                                        │
              └──────────── novo tabuleiro + score ────┘
```

O Prolog é puro: não sorteia nada. Recebe um tabuleiro e uma direção e devolve
o resultado. O Elm sorteia a peça nova (`Random`) e atualiza a tela.

### Contrato da API

`POST /move`

```json
// requisição
{ "board": [[0,2,0,2],[0,0,0,0],[4,0,0,0],[0,0,0,0]], "direction": "left" }

// resposta
{ "board": [[4,0,0,0],[0,0,0,0],[4,0,0,0],[0,0,0,0]],
  "score": 4, "moved": true, "won": false, "lost": false }
```

- `direction`: `left`, `right`, `up` ou `down`.
- `moved`: `false` se o movimento não alterou o tabuleiro (o Elm não sorteia peça).
- Erros: HTTP 400 com `{ "error": "<mensagem>" }`.

### Predicados Prolog previstos

```prolog
move(+Board, +Dir, -NewBoard, -Score)   % mover e fundir
game_won(+Board)                        % existe peça 2048
game_lost(+Board)                       % sem movimentos possíveis
```

Dica: mover para a esquerda é o caso base. As outras direções são
transposição e reversão do tabuleiro.

## Divisão da equipe

| Frente | Pessoas | Responsável | Tarefas |
|---|---|---|---|
| Elm | 3 | | `Model`/`Msg`/`update`/`view`, sorteio de peças, encoders/decoders JSON, tratamento de erros da API, estilo |
| Prolog | 2 | | Regras de movimento e fusão, pontuação, vitória e derrota, testes com `plunit` |
| Integração (Python) | 1 | | Servidor, integração com o Prolog via janus, CORS, validação da entrada |
| Gestão e docs | 1 | | Ambiente (`pnpm`, `uv`), CI, revisão de PRs, README, apresentação, entrega no Classroom |

## Marcos

| Data | Marco |
|---|---|
| Até 08/11 | Repositório configurado, contrato da API fechado, esqueleto rodando de ponta a ponta com uma resposta fixa |
| Até 13/11 | Prolog completo e testado. Elm com tabuleiro e movimentos funcionando |
| 18/11 | Prova de Elm. Foco nos estudos |
| Até 22/11 | Integração completa, vitória/derrota, estilo final |
| 23/11 | Congelamento do código. Só correções de bugs |
| 25/11, 27/11, 02/12 | Apresentações (a data do grupo será definida pelo professor) |

## Fluxo de trabalho

- Uma issue por tarefa, com responsável e marco.
- Branch por issue: `feat/<descricao-curta>`. Nada de commit direto na `main`.
- **Todo PR deve ter uma issue relacionada.** Se não existir, crie a issue antes de abrir o PR e coloque `Closes #<número>` na descrição.
- Todo PR precisa de pelo menos uma revisão de outra pessoa.
- Commits em português, no imperativo: `Adiciona fusão de peças no Prolog`.
- Código copiado de fora ou de IA deve ser entendido por quem o enviou. O professor
  usa detecção de plágio e anula o trabalho, sem distinguir quem copiou de quem cedeu.

## Estrutura do repositório

```
logic-2048/
├── docs/          planejamento e documentação
├── prolog/        motor de regras e testes
├── server/        servidor Python
└── web/           aplicação Elm (Vite)
```

## Fora do escopo (só se sobrar tempo)

- Desfazer jogada.
- Recorde salvo no navegador (`localStorage` via ports).
- Tabuleiros de outros tamanhos (3x3, 5x5).
- Dica de melhor jogada calculada em Prolog.

## Riscos

| Risco | Mitigação |
|---|---|
| janus exige SWI-Prolog recente | Confirmar a versão de todos na primeira semana |
| Prova de Elm em 18/11 reduz o tempo | Antecipar a parte de Elm e fechar as tarefas pesadas antes |
| Integração só testada no fim | Esqueleto ponta a ponta já no primeiro marco |
| Pouca prática em Prolog na equipe | Parear as 2 pessoas de Prolog e revisar em grupo |
