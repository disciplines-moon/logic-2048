# Apresentação interativa dentro do app

A apresentação é uma **página do próprio Logic2048**, em `#/apresentacao`. Não tem
slides externos: cada pessoa apresenta a sua parte, de preferência quem fez a
issue, com a demo rodando ao lado da explicação.

## Como funciona

- A apresentação é um conjunto de **cenas**. Cada issue tem a sua cena em
  `web/src/Cenas/IssueNN.elm`, então ninguém mexe no arquivo de outra pessoa.
- Cada cena tem **passos**. Ao avançar, o próximo passo **acrescenta** blocos na
  tela, no ritmo da fala.
- Cada passo tem uma **anotação do apresentador** (`notes`): o que dizer naquele
  momento. Ela aparece no painel de baixo (tecla `n`).
- Os blocos podem ser texto (`Paragraph`, `Bullets`, `Pre`), **código real do
  repositório** com números de linha e destaque (`Code`), a **demo ao vivo** com o
  jogo funcionando (`Demo`), um **fluxo animado** (`Flow`) ou **pedidos de verdade
  à API** (`Pedidos`), que mostram o JSON enviado e a resposta do servidor.
- `Clear` apaga o que apareceu antes, para trocar um bloco por outro no passo seguinte.
- `Flow` desenha etapas ligadas por setas e acende uma por passo. Use `Clear` + um
  novo `Flow` com outro `active` a cada passo (veja a cena "Arquitetura" em
  `web/src/Cenas/Intro.elm`).

## Teclas

| Tecla | Ação |
|---|---|
| `→`, `PageDown` | Próximo passo (e, no último, próxima cena) |
| `←`, `PageUp` | Passo anterior |
| `↓` / `↑` | Próxima / anterior cena |
| `Home` / `End` | Primeira / última cena |
| `n` | Mostra ou esconde as anotações |
| `W` `A` `S` `D` | Jogam na demo (as setas navegam) |
| `f` | Tela cheia |
| `Esc` | Volta ao jogo |

Também dá para clicar nas bolinhas do rodapé para ir a um passo. A barra no topo mostra
o progresso da apresentação inteira. O endereço guarda a posição (`#/apresentacao/<cena>/<passo>`), então dá para
abrir direto na sua parte e recarregar sem perder o lugar.

## Como escrever a sua cena

1. Abra `web/src/Cenas/Issue<NN>.elm` (o número da sua issue). Hoje ele tem uma
   cena `pending`, que aparece em vermelho.
2. Troque por uma cena de verdade:

```elm
module Cenas.Issue02 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 2
      , title = "Prolog: deslizar e fundir uma linha"
      , steps =
            [ { notes = "Começar pelo caso base: linha vazia."
              , blocks = [ Code { file = "prolog/game.pl", from = 1, to = 10, mark = [] } ]
              }
            , { notes = "Agora a fusão: dois iguais viram um dobrado."
              , blocks = [ Code { file = "prolog/game.pl", from = 1, to = 10, mark = [ 7, 8 ] } ]
              }
            , { notes = "Rodar ao vivo para mostrar que funciona."
              , blocks = [ Demo ]
              }
            ]
      }
    ]
```

3. Para mostrar outro arquivo do repositório, importe-o em `web/src/main.js`
   com `?raw` e dê um nome a ele (a chave usada em `Code`).
4. Ensaie rodando `npm run dev` e abrindo `http://localhost:5173/#/apresentacao`.

## O que cada cena deve ter

- Pelo menos um passo com **anotação** do que falar.
- Código real ou demo, não só texto.
- O **papel do paradigma**: a seção "Para explicar na apresentação" da sua issue
  é o roteiro.
- Nenhum bloco `Pending`. A revisão final (#14) confere isso com
  `Cenas.pendingCount`.

## Manter as cenas em dia

O que atualiza sozinho e o que não atualiza:

| Bloco | Atualiza sozinho? |
|---|---|
| `Demo` | Sim. É o jogo real: quando o `move/4` e o sorteio de peças ficarem prontos, a demo passa a funcionar. |
| `Code` (texto) | Sim. Lê o arquivo como ele está no repositório. |
| `Code` (`from`, `to`, `mark`) | **Não.** Os números de linha são fixos e mudam de lugar quando o arquivo muda. Confira ao concluir. |
| Animações e exemplos escritos à mão (por exemplo "Como uma jogada acontece", em `Cenas/Intro.elm`) | **Não.** Mostram um exemplo, não o jogo rodando. |

Ao mudar um comportamento, percorra as cenas que falam dele, confira os intervalos de `Code` e corrija a cena. Se a cena for de outra pessoa, comente na issue dela o que mudou. Cada issue tem o critério "Cena em dia" e a #14 confere tudo no final.

## Fora do escopo desta base

A demo (`Demo`) hoje mostra o jogo do esqueleto, com botões de direção. Deixar a
demo especial de cada cena (por exemplo, rodar só o `slide_left` com uma linha
digitada) é trabalho da própria issue. O modo apresentador em duas janelas é um
extra opcional.
