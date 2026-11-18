module Cenas.Issue19 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 19
      , title = "Prolog: desafios com CLP(FD)"
      , steps =
            [ { notes = "Agora é um quebra-cabeça: o tabuleiro vem pronto e nenhuma peça nasce. Dá para chegar ao alvo em até N jogadas? Repare na soma: fundir não cria valor, 2 mais 2 vira 4. A soma é sempre 16. Se o alvo passa da soma, não há resposta, e sabemos sem jogar nada."
              , secs = 20
              , blocks =
                    [ Lead "Chegar ao alvo em até N jogadas, sem peças novas."
                    , Etapas
                        [ etapa "c1: alvo 16" "soma 16" c1
                        , etapa "left" "soma 16" c1a
                        , etapa "left" "soma 16" c1b
                        , etapa "left" "16 >= 16" c1c
                        ]
                    ]
              }
            , { notes = "Isso vira restrição de CLP(FD), não if: a soma das casas, e o alvo cabe na soma. Cada jogada no máximo dobra a maior peça, então tamanhos curtos caem antes da busca. O labeling tenta 1 jogada, depois 2, depois 3: a primeira resposta é a menor. Cada direção continua sendo backtracking com o move/4."
              , secs = 25
              , blocks =
                    [ Clear
                    , Code { file = "prolog/challenge.pl", from = 46, to = 53, mark = [ 46, 47, 51, 53 ] }
                    , Converte
                        { title = "c1, alvo 16: o labeling tenta os tamanhos em ordem"
                        , pairs =
                            [ ( "alvo 32, soma 16", "32 #=< 16 falha: nenhuma jogada simulada" )
                            , ( "Len = 1, 2", "8 × 2¹ ≥ 16 passa; nenhuma sequência de 1 ou 2 chega" )
                            , ( "Len = 3", "[left, left, left]   ← a primeira é a menor" )
                            ]
                        }
                    ]
              }
            , { notes = "No 3×3, a soma é exatamente o alvo: todas as peças viram uma só, em quatro jogadas. Com só três, o Prolog esgota a busca e responde false. Sem solução não é lista vazia: é falha."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "c3: todas as peças viram uma só."
                    , Etapas
                        [ etapa "Board" "" c3
                        , etapa "left" "" c3a
                        , etapa "up" "" c3b
                        , etapa "left" "" c3c
                        , etapa "up" "16" c3d
                        ]
                    , Pre "?- challenge(C3, 16, 4, M).\nM = [left, up, left, up].\n\n?- challenge(C3, 16, 3, M).\nfalse."
                    ]
              }
            , { notes = "Ao vivo: abra Desafios e escolha o 3×3. O Elm pede a solução ao /api/challenge e mostra as setas: left, up, left, up. Cada Próximo passo é uma jogada de verdade do move/4, sem peça nova, até sobrar um 16 só."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: Desafios, o 3×3 e Próximo passo."
                    , DemoCom c3
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Tabuleiros da cena, escritos à mão. Em prolog/test_challenge.pl, o teste
-- `cena_issue19` confere cada jogada com o move/4 e cada resposta com o challenge/4.


c1 : List (List Int)
c1 =
    [ [ 2, 2, 4, 8 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c1a : List (List Int)
c1a =
    [ [ 4, 4, 8, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c1b : List (List Int)
c1b =
    [ [ 8, 8, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c1c : List (List Int)
c1c =
    [ [ 16, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c3 : List (List Int)
c3 =
    [ [ 2, 4, 0 ], [ 0, 2, 0 ], [ 4, 0, 4 ] ]


c3a : List (List Int)
c3a =
    [ [ 2, 4, 0 ], [ 2, 0, 0 ], [ 8, 0, 0 ] ]


c3b : List (List Int)
c3b =
    [ [ 4, 4, 0 ], [ 8, 0, 0 ], [ 0, 0, 0 ] ]


c3c : List (List Int)
c3c =
    [ [ 8, 0, 0 ], [ 8, 0, 0 ], [ 0, 0, 0 ] ]


c3d : List (List Int)
c3d =
    [ [ 16, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ]
