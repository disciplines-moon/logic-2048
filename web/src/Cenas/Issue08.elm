module Cenas.Issue08 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 8
      , title = "Elm: interface, temas e animações"
      , steps =
            [ { notes = "A view é uma função pura do Model. Recebe o Model e devolve Html, e mais nada: não guarda estado escondido, não fala com o servidor, não sorteia. O mesmo Model gera sempre a mesma tela. A classe do tema também sai do Model. Quando alguém clica, a view não muda nada: só devolve uma Msg para o update."
              , blocks =
                    [ Lead "Mesmo Model, mesma tela."
                    , Code { file = "web/src/Game/View.elm", from = 21, to = 37, mark = [ 24, 33 ] }
                    ]
              }
            , { notes = "Ao vivo. Carregar o tabuleiro de fusões, ligar a câmera lenta e apertar A. Cada peça anda da sua casa até a nova: o 8 atravessa a linha, os pares de 2 e de 4 deslizam um sobre o outro e a peça fundida dá o pop quando eles chegam. Só depois a peça sorteada cresce, porque o sorteio vem depois da resposta do Prolog. O 16, que não tem para onde ir, fica parado."
              , blocks =
                    [ Clear
                    , Lead "As peças andam de casa em casa."
                    , Demo
                    , Cenarios [ etapa "fusões: ligue a câmera lenta e aperte A" "" fusoes ]
                    ]
              }
            , { notes = "Quem sabe de onde cada peça veio? O Prolog, porque isso é regra de jogo. O move_trace usa o próprio move/4 para o resultado e conta o caminho: marca cada casa com a sua posição, gira o tabuleiro para a jogada virar esquerda, como o move/4 faz, e percorre cada linha. Um par igual vai para a mesma casa e funde; uma peça sozinha só desliza. Um teste confere que o caminho refaz exatamente o tabuleiro do move/4."
              , blocks =
                    [ Clear
                    , Lead "O caminho de cada peça vem do Prolog."
                    , Code { file = "prolog/game.pl", from = 140, to = 147, mark = [ 141, 144 ] }
                    , Code { file = "prolog/game.pl", from = 173, to = 178, mark = [ 174, 177 ] }
                    ]
              }
            , { notes = "O Elm não calcula nada: só aplica o caminho. Cada peça procura o movimento que sai da sua casa e vai para a casa de destino. As duas de uma fusão viram fantasmas, que deslizam e somem, e nasce uma peça nova com o valor somado. Se a resposta não trouxer o caminho, ou ele não bater com o tabuleiro, as peças são refeitas do tabuleiro."
              , blocks =
                    [ Clear
                    , Lead "O Elm só aplica o caminho."
                    , Code { file = "web/src/Game.elm", from = 651, to = 665, mark = [ 656, 659, 662 ] }
                    ]
              }
            , { notes = "Por que a peça anda? Pela chave: o id não muda, então é o mesmo nó do navegador com outra linha e coluna, e a transition do CSS o desliza. Cada peça também mora numa vaga fixa da lista, porque se o Elm movesse o nó, o deslize seria cancelado. E a forma como a peça entrou nunca muda, para a animação não ser cortada no meio."
              , blocks =
                    [ Clear
                    , Lead "A chave é a identidade da peça."
                    , Code { file = "web/src/Game/View.elm", from = 162, to = 168, mark = [ 162, 167, 168 ] }
                    , Code { file = "web/src/styles/main.css", from = 201, to = 207, mark = [ 205, 206 ] }
                    ]
              }
            , { notes = "O tema é só mais um campo do Model. O botão manda ThemeChosen, o update troca o campo, e a view desenha com outra classe. A cor de cada parte vem de variáveis CSS que o tema redefine. Guardar o tema entre sessões é da #9, pelos ports: ela só precisa mandar ThemeChosen com o tema salvo."
              , blocks =
                    [ Clear
                    , Lead "O tema é só mais um campo do Model."
                    , Demo
                    , Code { file = "web/src/Game.elm", from = 361, to = 362, mark = [ 362 ] }
                    ]
              }
            , { notes = "A mesma view serve de 3 a 6: o tamanho da peça é uma variável por N, e a letra acompanha o tamanho e o número de dígitos. Carregar a rampa: todas as peças, de 2 a 8192, com contraste de pelo menos 4,5 para 1 nos dois tons do degradê. A partir de 2048 a peça brilha. Depois, trocar o tamanho nos botões."
              , blocks =
                    [ Clear
                    , Lead "A interface escala com N, e toda peça é legível."
                    , Demo
                    , Cenarios [ etapa "rampa de cores: 2 a 8192" "" rampa ]
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }


{-| Com A: os dois 2 fundem num 4, o 8 desliza até a beirada, os dois 4 da terceira
linha fundem num 8, e o 16 da última linha já está na beirada e não se mexe.
-}
fusoes : List (List Int)
fusoes =
    [ [ 2, 2, 0, 0 ], [ 0, 0, 0, 8 ], [ 4, 0, 4, 0 ], [ 16, 0, 0, 0 ] ]


rampa : List (List Int)
rampa =
    [ [ 2, 4, 8, 16 ], [ 32, 64, 128, 256 ], [ 512, 1024, 2048, 4096 ], [ 8192, 0, 0, 0 ] ]
