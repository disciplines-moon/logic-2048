module Cenas.Issue09 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, FlowNode, Scene)


cenas : List Scene
cenas =
    [ { issue = 9
      , title = "Elm: ports, sons e confete"
      , steps =
            [ { notes = "O Elm é puro: não toca som nem mexe no navegador. O update decide o efeito, que é só um valor, por exemplo Sound Merge. O valor sai por um port tipado, a única porta para fora, e o JavaScript executa: toca, solta o confete, grava o recorde."
              , secs = 15
              , blocks =
                    [ Lead "Efeito é um valor; o JavaScript executa."
                    , Ciclo { nodes = efeito, back = "↩  na próxima visita, o que foi gravado volta ao Elm pelas flags" }
                    ]
              }
            , { notes = "Quem decide é uma função pura, reactions. A vitória vem do Prolog, o won. Mas o won continua verdadeiro depois de vencer, então o confete só sai uma vez por partida: o campo celebrated. O recorde só conta se o placar passou o daquele tamanho."
              , secs = 15
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 583, to = 590, mark = [ 584, 587, 590 ] }
                    , Converte
                        { title = "resposta do Prolog  →  efeitos"
                        , pairs =
                            [ ( "won, celebrated = False", "[ Sound Victory, Confetti ]" )
                            , ( "won de novo, celebrated = True", "[ ]   a festa não repete" )
                            , ( "placar 2100 > recorde 2048", "[ SaveBest 4 2100 ]" )
                            ]
                        }
                    ]
              }
            , { notes = "Ao vivo: quase vencido, aperte A. O Prolog responde won, e vem a fanfarra e o confete, tudo pelos ports. Jogue de novo: a festa não repete."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: o Prolog diz won, o port faz a festa."
                    , Demo
                    , Cenarios [ etapa "quase vencido: A" "" quaseVencido ]
                    ]
              }
            ]
      }
    ]


{-| O caminho de um efeito, do update ao navegador, que gira sozinho.
-}
efeito : List FlowNode
efeito =
    [ { label = "update", sub = "função pura", detail = "decide os efeitos da jogada", art = "elm" }
    , { label = "Effect", sub = "um valor", detail = "Sound Merge, Confetti", art = "" }
    , { label = "port", sub = "Cmd tipado", detail = "playSound \"merge\"", art = "" }
    , { label = "JavaScript", sub = "executa", detail = "sons.js, confete.js, memoria.js", art = "" }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }


{-| Com A: 1024 + 1024 = 2048, e o Prolog responde won (o mesmo cenário da #4).
-}
quaseVencido : List (List Int)
quaseVencido =
    [ [ 1024, 1024, 0, 0 ], [ 4, 8, 2, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
