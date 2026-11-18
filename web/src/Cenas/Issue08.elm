module Cenas.Issue08 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 8
      , title = "Elm: interface, temas e animações"
      , steps =
            [ { notes = "Quem sabe de onde cada peça veio? O Prolog, porque é regra de jogo: o move_trace devolve o caminho de cada peça. O Elm não calcula nada, só aplica. Cada peça tem um id que não muda, então é o mesmo nó do navegador numa casa nova, e o CSS desliza. A view é função pura do Model: mesmo Model, mesma tela."
              , secs = 20
              , blocks =
                    [ Lead "O caminho vem do Prolog; o Elm só aplica."
                    , Converte
                        { title = "moves do /api/move  →  tela (tecla A)"
                        , pairs =
                            [ ( "from [0,1]  to [0,0]  merged", "o 2 desliza sobre o outro 2 e vira 4" )
                            , ( "from [1,3]  to [1,0]", "o 8 atravessa a linha" )
                            , ( "from [3,0]  to [3,0]", "o 16 fica parado" )
                            , ( "mesmo id, outra casa", "mesmo nó: a transition do CSS desliza" )
                            ]
                        }
                    ]
              }
            , { notes = "Ao vivo: carregue as fusões, ligue a câmera lenta e aperte A. Cada peça anda até a casa nova, o par funde com um pop, e só depois a peça sorteada cresce. Na rampa, todas as peças de 2 a 8192, legíveis nos dois temas."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: câmera lenta, aperte A."
                    , Demo
                    , Cenarios
                        [ etapa "fusões: câmera lenta e A" "" fusoes
                        , etapa "rampa de cores: 2 a 8192" "" rampa
                        ]
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
