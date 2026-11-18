module Cenas.Issue03 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 3
      , title = "Prolog: mover nas 4 direções"
      , steps =
            [ { notes = "Escrevemos uma regra só, a esquerda, e ganhamos as outras três por transformação. A direita é a esquerda no espelho. Cima e baixo viram as colunas em linhas."
              , secs = 15
              , blocks =
                    [ Lead "Uma regra de verdade, três por transformação."
                    , Pre "left   =                      slide_left em cada linha\nright  =  mirror           →  left   →  mirror\nup     =  transpose_board  →  left   →  transpose_board\ndown   =  transpose_board  →  right  →  transpose_board"
                    ]
              }
            , { notes = "Direita: espelha cada linha, desliza para a esquerda e espelha de volta. Repare que o par funde do lado para onde as peças vão."
              , secs = 15
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 46, to = 49, mark = [ 47, 48, 49 ] }
                    , Etapas
                        [ etapa "Board" "" exemplo
                        , etapa "mirror" "" espelhado
                        , etapa "slide_rows" "+4" espelhadoDeslizado
                        , etapa "mirror" "" direita
                        ]
                    ]
              }
            , { notes = "Cima: transpõe, vai à esquerda e transpõe de volta. Baixo usa a direita. Só existe uma regra de deslizar no programa, e a transposta funciona para qualquer N: nenhum 4 escrito no código."
              , secs = 15
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 50, to = 57, mark = [ 51, 52, 53, 56 ] }
                    , Etapas
                        [ etapa "Board" "" exemplo
                        , etapa "transpose_board" "" transposto
                        , etapa "move_dir(left)" "+28" transpostoEsquerda
                        , etapa "transpose_board" "" cima
                        ]
                    ]
              }
            , { notes = "Ao vivo: cada tecla manda o tabuleiro para a API, que chama o move/4. A peça nova que aparece depois não vem do Prolog: quem sorteia é o Elm."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: cada tecla chama o move/4."
                    , Demo
                    , Bullets [ "W A S D jogam.", "A peça nova é sorteada pelo Elm, não pelo Prolog." ]
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Tabuleiros da cena, escritos à mão. Em prolog/test_game.pl, o teste
-- `cena_issue03` confere cada um com o move/4.


exemplo : List (List Int)
exemplo =
    [ [ 2, 0, 2, 0 ], [ 2, 4, 0, 0 ], [ 0, 4, 0, 8 ], [ 4, 0, 0, 8 ] ]


espelhado : List (List Int)
espelhado =
    [ [ 0, 2, 0, 2 ], [ 0, 0, 4, 2 ], [ 8, 0, 4, 0 ], [ 8, 0, 0, 4 ] ]


espelhadoDeslizado : List (List Int)
espelhadoDeslizado =
    [ [ 4, 0, 0, 0 ], [ 4, 2, 0, 0 ], [ 8, 4, 0, 0 ], [ 8, 4, 0, 0 ] ]


direita : List (List Int)
direita =
    [ [ 0, 0, 0, 4 ], [ 0, 0, 2, 4 ], [ 0, 0, 4, 8 ], [ 0, 0, 4, 8 ] ]


transposto : List (List Int)
transposto =
    [ [ 2, 2, 0, 4 ], [ 0, 4, 4, 0 ], [ 2, 0, 0, 0 ], [ 0, 0, 8, 8 ] ]


transpostoEsquerda : List (List Int)
transpostoEsquerda =
    [ [ 4, 4, 0, 0 ], [ 8, 0, 0, 0 ], [ 2, 0, 0, 0 ], [ 16, 0, 0, 0 ] ]


cima : List (List Int)
cima =
    [ [ 4, 8, 2, 16 ], [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
