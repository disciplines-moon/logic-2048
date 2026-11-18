module Cenas.Issue04 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 4
      , title = "Prolog: vitória, derrota e jogadas"
      , steps =
            [ { notes = "O fim do jogo é uma pergunta sobre o tabuleiro. Não escrevemos como procurar: escrevemos o que é verdade. Vence se alguma linha tem alguma casa com peça maior ou igual à de vitória do N. O member tenta casa por casa por backtracking, e o corte para na primeira que serve."
              , secs = 20
              , blocks =
                    [ Lead "O fim do jogo é uma pergunta sobre o tabuleiro."
                    , Code { file = "prolog/game.pl", from = 92, to = 98, mark = [ 94, 95, 96, 97 ] }
                    , Pre "?- game_won([[0,0,0],[0,256,0],[0,0,0]]).\ntrue.        % no 3×3 vence com 256 (win_tile/2)"
                    ]
              }
            , { notes = "Jogadas válidas: o member tenta as quatro direções por backtracking, e só sobram as que mudam o tabuleiro. O up aqui não muda nada e fica fora. O findall junta as respostas numa lista: left, right e down."
              , secs = 15
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 110, to = 113, mark = [ 111, 113 ] }
                    , Code { file = "prolog/game.pl", from = 119, to = 120, mark = [ 120 ] }
                    , Tabuleiros
                        [ etapa "Board" "" exemplo
                        , etapa "left" "" [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                        , etapa "right" "" [ [ 0, 0, 0, 4 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                        , etapa "up: igual, fica fora" "" exemplo
                        , etapa "down" "" [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 2, 2, 0, 0 ] ]
                        ]
                    ]
              }
            , { notes = "Derrota é a negação de ter jogada. O \\+ é negação por falha: é verdadeiro quando o Prolog não consegue provar o objetivo. Não existe casa vazia, e não existe direção que mude algo. Neste tabuleiro nenhuma peça igual encosta em outra: game_lost responde true."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "Derrota: negação por falha."
                    , Code { file = "prolog/game.pl", from = 128, to = 130, mark = [ 129, 130 ] }
                    , Tabuleiros [ etapa "game_lost(Board)" "true" perdido ]
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Tabuleiros da cena, escritos à mão. Em prolog/test_game.pl, o teste
-- `cena_issue04` confere que eles fazem o que a cena diz.


exemplo : List (List Int)
exemplo =
    [ [ 2, 2, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


perdido : List (List Int)
perdido =
    [ [ 2, 4, 2, 4 ], [ 4, 2, 4, 2 ], [ 2, 4, 2, 4 ], [ 4, 2, 4, 2 ] ]
