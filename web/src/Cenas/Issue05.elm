module Cenas.Issue05 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 5
      , title = "Prolog: dica com expectimax"
      , steps =
            [ { notes = "O problema da dica: eu escolho a jogada, mas depois dela nasce uma peça ao acaso, 2 com 90% e 4 com 10%, numa casa vazia qualquer. Uma jogada boa agora pode ficar ruim depois do sorteio. Como decidir sob incerteza?"
              , secs = 20
              , blocks =
                    [ Lead "Depois da minha jogada, uma peça nasce ao acaso."
                    , Etapas
                        [ etapa "Board" "" arvore
                        , etapa "right" "" arvoreRight
                        , etapa "nasce 2" "90%" arvoreRight2
                        , etapa "nasce 4" "10%" arvoreRight4
                        ]
                    ]
              }
            , { notes = "O expectimax é uma árvore com dois tipos de nó. Na minha vez, fico com a jogada de maior valor. Na vez do acaso, faço a média ponderada sobre o que pode nascer. Com o left, se nascer um 2 o tabuleiro trava: é derrota, que vale menos um milhão. Com o up, perde se nascer um 4. O right nunca perde e é a dica. O teste cena_issue05 confere estes números."
              , secs = 25
              , blocks =
                    [ Clear
                    , Lead "Máximo nas minhas jogadas, média no sorteio."
                    , Arvore
                        { root = "22 → right"
                        , branches =
                            [ { label = "left", value = "−899.997,8", best = False, leaves = [ ( "2 · 90%", "PERDE" ), ( "4 · 10%", "22" ) ] }
                            , { label = "right", value = "22,0", best = True, leaves = [ ( "2 · 90%", "22" ), ( "4 · 10%", "22" ) ] }
                            , { label = "up", value = "−99.987,4", best = False, leaves = [ ( "2 · 90%", "14" ), ( "4 · 10%", "PERDE" ) ] }
                            ]
                        }
                    ]
              }
            , { notes = "No código, a árvore é uma recursão mútua: o nó de máximo fica com o maior filho, o nó de sorteio faz a média, os dois com aggregate_all. Os filhos vêm por backtracking no member, cada casa vazia e cada peça. Nenhum laço."
              , secs = 15
              , blocks =
                    [ Clear
                    , Code { file = "prolog/hint.pl", from = 103, to = 109, mark = [ 103, 104, 105, 106, 108 ] }
                    , Converte
                        { title = "nó de sorteio depois do right: uma casa vazia, E = 1"
                        , pairs =
                            [ ( "member(0-0, Empty), spawn(2, 0.9)", "P = 0,9 / 1   →   max_value = 22" )
                            , ( "member(0-0, Empty), spawn(4, 0.1)", "P = 0,1 / 1   →   max_value = 22" )
                            , ( "aggregate_all(sum(P * V1), ...)", "0,9 × 22 + 0,1 × 22 = 22,0" )
                            ]
                        }
                    ]
              }
            , { notes = "Ao vivo: o tabuleiro da issue já está carregado; ligue a Dica. A seta aponta left, a mesma resposta da consulta ao Prolog, com o valor de cada direção. Jogou, a dica nova vem sozinha. A profundidade é limitada, porque cada nível multiplica o trabalho."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: o botão Dica chama este hint/4."
                    , DemoCom exemplo
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Tabuleiros da cena, escritos à mão. Em prolog/test_hint.pl, o teste
-- `cena_issue05` confere cada jogada com o move/4, cada nota com o evaluate/2
-- e cada resposta com o hint/4.


arvore : List (List Int)
arvore =
    [ [ 2, 0, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


arvoreRight : List (List Int)
arvoreRight =
    [ [ 0, 2, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


arvoreRight2 : List (List Int)
arvoreRight2 =
    [ [ 2, 2, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


arvoreRight4 : List (List Int)
arvoreRight4 =
    [ [ 4, 2, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


exemplo : List (List Int)
exemplo =
    [ [ 2, 2, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
