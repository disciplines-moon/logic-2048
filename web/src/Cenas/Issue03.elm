module Cenas.Issue03 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 3
      , title = "Prolog: mover nas 4 direções"
      , steps =
            [ { notes = "Escrevemos uma regra só, a esquerda, e ganhamos as outras três por transformação. A direita é a esquerda num espelho. Cima e baixo são esquerda e direita com as colunas viradas em linhas."
              , blocks =
                    [ Lead "Uma regra de verdade, três por transformação."
                    , Pre "left   =                      slide_left em cada linha\nright  =  mirror           →  left   →  mirror\nup     =  transpose_board  →  left   →  transpose_board\ndown   =  transpose_board  →  right  →  transpose_board"
                    ]
              }
            , { notes = "O move/4 só confere que o tabuleiro veio pronto e passa para o move_dir, que tem uma cláusula por direção. A direção vem primeiro para o Prolog escolher a cláusula direto pelo átomo, sem tentar as outras. A esquerda é direta: slide_rows."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 37, to = 45, mark = [ 39, 44, 45 ] }
                    ]
              }
            , { notes = "O slide_rows é composição de predicados: o maplist aplica o slide_left da #2 em cada linha e devolve a lista de pontos de cada uma. O Score da jogada é a soma dessas pontuações. Não há laço nem índice: o maplist percorre quantas linhas houver."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 59, to = 63, mark = [ 62, 63 ] }
                    , Etapas
                        [ etapa "Board" "" exemplo
                        , etapa "slide_rows(Board, NewBoard, Score)" "+4" esquerda
                        ]
                    ]
              }
            , { notes = "Direita: espelha cada linha com reverse, desliza para a esquerda e espelha de volta. Deslizar para a direita é deslizar para a esquerda no espelho. Repare que o par funde do lado para onde as peças vão."
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
            , { notes = "Cima: o transpose_board vira as colunas em linhas. Aí é só ir para a esquerda, que já sabemos fazer, e transpor de volta. Aqui as colunas fundem: 2 com 2, 4 com 4 e 8 com 8, total 28."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 50, to = 53, mark = [ 51, 52, 53 ] }
                    , Etapas
                        [ etapa "Board" "" exemplo
                        , etapa "transpose_board" "" transposto
                        , etapa "move_dir(left)" "+28" transpostoEsquerda
                        , etapa "transpose_board" "" cima
                        ]
                    ]
              }
            , { notes = "Baixo é cima com a direita no lugar da esquerda. E a direita já é a esquerda no espelho. São camadas de composição: baixo usa direita, que usa esquerda, que usa o slide_left. Só existe uma regra de deslizar no programa inteiro."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 54, to = 57, mark = [ 55, 56, 57 ] }
                    , Etapas
                        [ etapa "Board" "" exemplo
                        , etapa "transpose_board" "" transposto
                        , etapa "move_dir(right)" "+28" transpostoDireita
                        , etapa "transpose_board" "" baixo
                        ]
                    ]
              }
            , { notes = "Como o transpose_board funciona para qualquer N: o maplist(first_rest) tira a primeira peça de todas as linhas de uma vez, e isso é uma coluna. O resto das linhas dá as outras colunas. A primeira linha só serve de guia para contar quantas colunas faltam. Não existe nenhum 4 escrito no código."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 78, to = 85, mark = [ 81, 82, 83 ] }
                    , Etapas
                        [ etapa "Rows" "" exemplo
                        , etapa "transpose_board(Rows, Cols)" "" transposto
                        ]
                    ]
              }
            , { notes = "O exemplo do contrato: o mesmo tabuleiro, quatro direções, quatro resultados. Para a esquerda, as duas linhas fundem ou deslizam e o Score é 4. Para cima nada funde, então o Score é 0, mas as peças andaram. Score 0 não quer dizer que nada mudou: quem decide se a jogada valeu é a comparação dos tabuleiros, feita no Python (moved)."
              , blocks =
                    [ Clear
                    , Tabuleiros
                        [ etapa "Board" "" contrato
                        , etapa "left" "+4" [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                        , etapa "right" "+4" [ [ 0, 0, 0, 4 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 4 ], [ 0, 0, 0, 0 ] ]
                        , etapa "up" "+0" [ [ 2, 4, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                        , etapa "down" "+0" [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 2, 4, 0, 2 ] ]
                        ]
                    , Pre "?- move([[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], left, B, S).\nB = [[4,0,0,0],[0,0,0,0],[4,0,0,0],[0,0,0,0]],\nS = 4.\n\n?- move([[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], up, B, S).\nB = [[2,4,0,2],[0,0,0,0],[0,0,0,0],[0,0,0,0]],\nS = 0."
                    ]
              }
            , { notes = "O mesmo código vale de 3×3 a 6×6: o maplist percorre quantas linhas houver e o transpose_board conta as colunas pela primeira linha. Os testes cobrem as 4 direções em N = 3, 4, 5 e 6, e conferem propriedades em 400 tabuleiros sorteados: a soma das peças não muda, as peças ficam encostadas e girar o tabuleiro troca a direção."
              , blocks =
                    [ Clear
                    , Lead "Nenhum 4 fixo: de 3×3 a 6×6."
                    , Tabuleiros
                        [ etapa "3×3" "" [ [ 2, 2, 4 ], [ 0, 4, 4 ], [ 2, 0, 2 ] ]
                        , etapa "up" "+12" [ [ 4, 2, 8 ], [ 0, 4, 2 ], [ 0, 0, 0 ] ]
                        , etapa "6×6" "" [ [ 2, 2, 4, 4, 8, 8 ], [ 2, 0, 0, 0, 0, 2 ], [ 4, 4, 4, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 2, 4, 8, 16, 32, 64 ], [ 2, 0, 0, 0, 0, 0 ] ]
                        , etapa "down" "+24" [ [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 0 ], [ 4, 0, 0, 0, 0, 8 ], [ 4, 2, 8, 4, 8, 2 ], [ 4, 8, 8, 16, 32, 64 ] ]
                        ]
                    ]
              }
            , { notes = "Agora ao vivo. Cada tecla manda o tabuleiro para o /api/move; o Python chama o move/4 e devolve o resultado. O Python não mudou nada: ele já chamava o move/4, que antes era um esboço que devolvia o tabuleiro igual. A peça nova que aparece depois de cada jogada não vem do Prolog: quem sorteia é o Elm (#6)."
              , blocks =
                    [ Clear
                    , Lead "Jogue com W A S D: cada jogada chama o move/4."
                    , Demo
                    ]
              }
            , { notes = "A natureza relacional. Com a direção livre, o mesmo predicado lista as quatro direções, inclusive as que não mudam nada: para saber se ainda há jogada, a #4 ainda precisa comparar o tabuleiro novo com o de entrada. O transpose_board também roda ao contrário: dada a saída, ele acha a entrada. Já o move/4 não roda com o tabuleiro de entrada livre, porque o slide_left usa o is/2, que só calcula com valores prontos. O must_be acusa isso logo na entrada."
              , blocks =
                    [ Clear
                    , Pre "?- move([[2,2,0],[0,0,0],[2,0,0]], D, B, S).\nD = left,  B = [[4,0,0],[0,0,0],[2,0,0]], S = 4 ;\nD = right, B = [[0,0,4],[0,0,0],[0,0,2]], S = 4 ;\nD = up,    B = [[4,2,0],[0,0,0],[0,0,0]], S = 4 ;\nD = down,  B = [[0,0,0],[0,0,0],[4,2,0]], S = 4.\n\n?- game:transpose_board(M, [[1,4],[2,5]]).\nM = [[1,2],[4,5]].\n\n?- move(B, left, [[4,0,0],[0,0,0],[0,0,0]], 4).\nERROR: Arguments are not sufficiently instantiated"
                    , Code { file = "prolog/game.pl", from = 37, to = 39, mark = [ 38 ] }
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Tabuleiros da cena, escritos à mão. Em prolog/test_game.pl, o teste
-- `cena_issue03` confere os de baixo, e os do contrato, de 3×3 e de 6×6 são os
-- mesmos dos testes contrato_*, n3_up e n6_down.


exemplo : List (List Int)
exemplo =
    [ [ 2, 0, 2, 0 ], [ 2, 4, 0, 0 ], [ 0, 4, 0, 8 ], [ 4, 0, 0, 8 ] ]


esquerda : List (List Int)
esquerda =
    [ [ 4, 0, 0, 0 ], [ 2, 4, 0, 0 ], [ 4, 8, 0, 0 ], [ 4, 8, 0, 0 ] ]


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


transpostoDireita : List (List Int)
transpostoDireita =
    [ [ 0, 0, 4, 4 ], [ 0, 0, 0, 8 ], [ 0, 0, 0, 2 ], [ 0, 0, 0, 16 ] ]


baixo : List (List Int)
baixo =
    [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 4, 0, 0, 0 ], [ 4, 8, 2, 16 ] ]


contrato : List (List Int)
contrato =
    [ [ 2, 0, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 4, 0, 0 ], [ 0, 0, 0, 0 ] ]
