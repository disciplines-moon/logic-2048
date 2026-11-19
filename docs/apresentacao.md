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
  momento, e quantos segundos ela leva (`secs`). O painel de baixo (tecla `n`)
  mostra a fala, quem fala e o relógio do ensaio ("até 3:40 de 13:41"). Um teste
  garante que a soma cabe em 14 minutos e que todos os integrantes falam.
- Os blocos podem ser texto (`Paragraph`, `Bullets`, `Pre`), **código real do
  repositório** com números de linha e destaque (`Code`), a **demo ao vivo** com o
  jogo funcionando (`Demo`), um **fluxo animado** (`Flow`) ou **pedidos de verdade
  à API** (`Pedidos`), que mostram o JSON enviado e a resposta do servidor.
- Há também blocos feitos para cenas específicas: `Hero` (capa), `Team` (equipe
  com foto), `Lead` (frase de destaque), `Slide` e `Fases` (o `slide_left/3`
  animado), `Etapas` e `Tabuleiros` (tabuleiros lado a lado ou ligados por setas),
  `Cenarios` (botões que carregam um tabuleiro pronto na `Demo`) e `PedidosEm`
  (pedidos a outra rota da API). A lista completa, com o que cada um faz, está em
  `web/src/Cenas/Types.elm`.
- Três blocos animam sozinhos, sem precisar de um passo por etapa: `Ciclo` (etapas
  que acendem uma de cada vez, em laço: o TEA, a máquina de estados da IA, a CI),
  `Converte` (linhas "entra → sai", como o janus traduzindo tipos ou uma entrada
  inválida virando 422) e `Arvore` (a árvore do expectimax, das folhas à raiz).
- Num `Code` com 2 ou mais linhas marcadas, elas acendem uma de cada vez (o "tour").
- `DemoCom tabuleiro` é a `Demo` que já entra no passo com aquele tabuleiro (na
  #9, quase vencido: é só apertar A). Sem lista ao lado, o jogo fica sozinho no
  centro. Todo passo ao vivo usa `DemoCom`: cada um começa zerado, sem a dica, a
  IA, a câmera lenta, o desafio ou a vitória de um slide anterior. Voltar ao
  passo, ou apertar "Novo jogo" nele, carrega o tabuleiro de novo, para repetir a
  demonstração. A resposta de um pedido ao vivo (`Pedidos`) também some ao trocar
  de passo.
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

1. Abra `web/src/Cenas/Issue<NN>.elm` (o número da sua issue). No começo do
   projeto cada arquivo tinha uma cena `pending`, em vermelho; hoje todas estão
   escritas (`Cenas.pendingCount == 0`).
2. Uma cena de verdade é assim:

```elm
module Cenas.Issue02 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 2
      , title = "Prolog: deslizar e fundir uma linha"
      , steps =
            [ { notes = "Começar pelo caso base: linha vazia."
              , secs = 15
              , blocks = [ Code { file = "prolog/game.pl", from = 1, to = 10, mark = [] } ]
              }
            , { notes = "Agora a fusão: dois iguais viram um dobrado."
              , secs = 20
              , blocks = [ Code { file = "prolog/game.pl", from = 1, to = 10, mark = [ 7, 8 ] } ]
              }
            , { notes = "Rodar ao vivo para mostrar que funciona."
              , secs = 15
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
| `Demo` | Sim. É o jogo real, com as regras do Prolog como estão agora. |
| `Code` (texto) | Sim. Lê o arquivo como ele está no repositório. |
| `Code` (`from`, `to`, `mark`) | **Não.** Os números de linha são fixos e mudam de lugar quando o arquivo muda. Confira ao concluir. |
| Animações e exemplos escritos à mão (por exemplo "Como uma jogada acontece", em `Cenas/Intro.elm`) | **Não.** Mostram um exemplo, não o jogo rodando. |

Ao mudar um comportamento, percorra as cenas que falam dele, confira os intervalos de `Code` e corrija a cena. Se a cena for de outra pessoa, comente na issue dela o que mudou. Cada issue tem o critério "Cena em dia" e a #14 confere tudo no final.

## A demo

- A `Demo` é o jogo de verdade (a mesma `Game.View` da tela inicial), com dica, IA,
  desafios, desfazer e replay. Os botões de `Cenarios` carregam um tabuleiro pronto
  nela; esses tabuleiros não contam para o recorde.
- O jogo da demo só roda enquanto o passo atual mostra a `Demo`
  (`Presentation.showsDemo`): ao passar de slide, a IA e o replay ficam pausados e
  `W A S D` param de jogar. Ao voltar ao passo, continuam de onde estavam.
- `Code` lê os arquivos pelo Vite (`?raw` em `web/src/main.js`). Depois de mudar
  algo em `prolog/` ou `server/`, reinicie a API e o `npm run dev`.
- Com "reduzir movimento" ligado no sistema, o confete não aparece (respeita a
  preferência de acessibilidade).
- O modo apresentador em duas janelas ficou de fora: as notas aparecem no painel
  de baixo (`n`), com a foto e o nome de quem fala.
