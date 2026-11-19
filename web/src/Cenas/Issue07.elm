module Cenas.Issue07 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 7
      , title = "Elm: desfazer e replay"
      , steps =
            [ { notes = "Toda jogada que mexe guarda o jogo de antes numa lista. Em Elm nenhum valor muda depois de criado, então guardar um estado é só guardar o valor, sem cópia. Desfazer é tirar o primeiro da lista. O replay toca a lista de novo, sem sortear nem perguntar ao Prolog: a partida sai idêntica."
              , secs = 20
              , blocks =
                    [ Lead "O histórico é uma lista de estados imutáveis."
                    , Etapas
                        [ etapa "início" "" s0
                        , etapa "A" "+4" s1
                        , etapa "W" "+8" s2
                        , etapa "D" "" s3
                        ]
                    , Code { file = "web/src/Game/History.elm", from = 49, to = 53, mark = [ 52, 53 ] }
                    ]
              }
            , { notes = "Ao vivo: jogue quatro vezes e desfaça uma com Ctrl+Z ou com o botão. Volta com a mesma peça sorteada. Depois, o Replay toca as três jogadas que ficaram, com pausa e velocidade."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "Jogue 4 vezes, desfaça 1 (Ctrl+Z) e abra o Replay."
                    , DemoCom aoVivo
                    , Bullets [ "Desfazer: tira o primeiro da lista.", "Replay: toca a lista com Time.every." ]
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Uma partida de verdade: cada tabuleiro é o move/4 do anterior mais a peça que o
-- Elm sorteou (o histórico guarda o jogo já com a peça nova).


s0 : List (List Int)
s0 =
    [ [ 2, 0, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 4, 0, 0 ], [ 0, 0, 0, 0 ] ]


s1 : List (List Int)
s1 =
    [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 4, 0, 0, 0 ], [ 0, 0, 2, 0 ] ]


s2 : List (List Int)
s2 =
    [ [ 8, 0, 2, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 4 ] ]


s3 : List (List Int)
s3 =
    [ [ 0, 0, 8, 2 ], [ 2, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 4 ] ]


{-| Começo de partida, com histórico vazio: três jogadas, dois desfazer e o Replay.
-}
aoVivo : List (List Int)
aoVivo =
    [ [ 2, 2, 0, 0 ], [ 0, 4, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 2 ] ]
