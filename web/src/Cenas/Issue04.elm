module Cenas.Issue04 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 4
      , title = "Prolog: vitória, derrota e jogadas"
      , steps =
            [ { notes = "O fim do jogo é uma pergunta sobre o tabuleiro, não uma sequência de passos. Não escrevemos como procurar: escrevemos o que é verdade quando alguém vence, quando perde e quais jogadas existem. Quem procura a resposta é o Prolog."
              , blocks =
                    [ Lead "O fim do jogo é uma pergunta sobre o tabuleiro."
                    , Bullets
                        [ "Vence: existe uma peça >= à peça de vitória do N."
                        , "Jogadas válidas: as direções que mudam o tabuleiro."
                        , "Perde: nenhuma casa vazia e nenhuma direção que mude algo."
                        ]
                    ]
              }
            , { notes = "O game_won lê como a frase: alguma linha tem alguma casa com peça maior ou igual à de vitória. O member/2 escolhe a primeira linha e a primeira casa; se o Tile >= Win falha, o Prolog volta atrás (backtracking) e tenta a próxima casa, depois a próxima linha. Não há laço nem índice. O corte no fim para a busca na primeira peça que serve. A peça de vitória vem do win_tile, que são só fatos: a tabela do contrato escrita como relação."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 92, to = 105, mark = [ 95, 96, 97 ] }
                    , Pre "?- game_won([[0,0,0],[0,256,0],[0,0,0]]).\ntrue."
                    ]
              }
            , { notes = "O can_move responde: esta direção muda o tabuleiro? Com a direção livre, o member/2 tenta left, right, up e down por backtracking, e o move/4 da #3 diz o que acontece. Só sobrevivem as direções em que o tabuleiro novo é diferente. Aqui o up não muda nada, porque as peças já estão na linha de cima: o \\== falha e o Prolog volta atrás para tentar o down."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 107, to = 113, mark = [ 111, 113 ] }
                    , Tabuleiros
                        [ etapa "Board" "" exemplo
                        , etapa "left" "" [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                        , etapa "right" "" [ [ 0, 0, 0, 4 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                        , etapa "up: igual, fica fora" "" exemplo
                        , etapa "down" "" [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 2, 2, 0, 0 ] ]
                        ]
                    ]
              }
            , { notes = "O available_moves não percorre nada: o findall junta numa lista todas as respostas do can_move, na ordem em que o backtracking as encontra. É o exemplo da issue: left, right e down. A dica (#5) e os desafios (#19) partem dessa lista."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 115, to = 120, mark = [ 120 ] }
                    , Pre "?- available_moves([[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], D).\nD = [left, right, down]."
                    ]
              }
            , { notes = "Derrota é a negação de ter jogada. O \\+ é negação por falha: \\+ Objetivo é verdadeiro quando o Prolog não consegue provar o Objetivo. Primeiro: não existe casa vazia (o member procura um 0 e não acha). Depois: não existe direção que mude algo (o can_move falha nas quatro). O que não se prova é tomado como falso: é a hipótese do mundo fechado. A casa vazia vem primeiro porque é barata e já decide quase todas as jogadas."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 122, to = 130, mark = [ 129, 130 ] }
                    ]
              }
            , { notes = "O tabuleiro do contrato: cheio, e nenhuma peça igual encosta em outra, nem na linha nem na coluna. Nenhuma das quatro direções muda nada, a lista de jogadas é vazia e o game_lost responde true."
              , blocks =
                    [ Clear
                    , Tabuleiros [ etapa "game_lost(Board)" "true" perdido ]
                    , Pre "?- available_moves([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]], D).\nD = [].\n\n?- game_lost([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]]).\ntrue."
                    ]
              }
            , { notes = "Ao vivo. No quase perdido só W e S mudam o tabuleiro: available_moves é [up, down]. Depois da jogada, o Elm sorteia a peça e não sobra saída. O Prolog olhou o tabuleiro antes da peça nova, então o Fim de jogo vem na tecla seguinte, com lost = true. No quase vencido, A funde 1024 + 1024 e o won vira true na mesma resposta."
              , blocks =
                    [ Clear
                    , Lead "Carregue um cenário e jogue com W A S D."
                    , Demo
                    , Cenarios
                        [ etapa "quase perdido: W ou S" "" quasePerdido
                        , etapa "quase vencido: A" "" quaseVencido
                        ]
                    , Bullets [ "Sem saída: a próxima tecla responde lost = true." ]
                    ]
              }
            , { notes = "No 3×3 só cabem 9 peças e o 2048 é inalcançável, então ali se vence com 256: decisão do contrato. Por isso o game_won mede o N com length e pergunta ao win_tile. O won continua true depois de vencer porque a regra é >=. Experimente: A funde 128 + 128 e já é vitória."
              , blocks =
                    [ Clear
                    , Lead "A peça de vitória depende de N."
                    , Demo
                    , Pre "N         3      4      5      6\nVitória   256    2048   4096   8192"
                    , Cenarios [ etapa "3×3 quase vencido: A" "" quaseVencido3 ]
                    , Bullets [ "Vale >=: com 4096 no 4×4, won continua true." ]
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


{-| Só `up` e `down` mudam o tabuleiro, e qualquer uma delas, com qualquer peça
sorteada (2 ou 4), deixa o tabuleiro sem saída.
-}
quasePerdido : List (List Int)
quasePerdido =
    [ [ 128, 8, 32, 64 ], [ 8, 64, 16, 32 ], [ 64, 32, 8, 128 ], [ 64, 16, 128, 64 ] ]


quaseVencido : List (List Int)
quaseVencido =
    [ [ 1024, 1024, 0, 0 ], [ 4, 8, 2, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


quaseVencido3 : List (List Int)
quaseVencido3 =
    [ [ 128, 128, 0 ], [ 4, 8, 0 ], [ 0, 0, 0 ] ]
