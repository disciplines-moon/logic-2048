module Cenas.Issue06 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene)


cenas : List Scene
cenas =
    [ { issue = 6
      , title = "Elm: estado, Random e TEA"
      , steps =
            [ { notes = "Toda tela em Elm segue o mesmo ciclo. Uma Msg descreve o que aconteceu. O update, uma função pura, recebe a Msg e o Model antigo e devolve um Model novo: é o único lugar onde o estado muda. O antigo continua intacto. A view só lê o Model e desenha, e o ciclo recomeça."
              , secs = 20
              , blocks =
                    [ Lead "Msg → update → Model novo → view, e de novo."
                    , Ciclo { nodes = tea, back = "↩  a view espera a próxima Msg, e o ciclo recomeça" }
                    ]
              }
            , { notes = "Quando o Prolog responde, o update soma os pontos. Se o tabuleiro mudou, ele não sorteia: devolve um pedido, Random.generate, para o runtime sortear. O resultado volta como outra Msg, Spawned. Se não mudou, nada nasce."
              , secs = 20
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 456, to = 462, mark = [ 456, 457, 458, 462 ] }
                    , Converte
                        { title = "uma jogada, Msg por Msg"
                        , pairs =
                            [ ( "Pressed Left", "Cmd: POST /api/move   (waiting = True)" )
                            , ( "GotMove (Ok res), res.moved", "Cmd: Random.generate (Spawned board) …" )
                            , ( "Spawned [ peça 2 em (3, 1) ]", "Model novo: a peça nasce, waiting = False" )
                            ]
                        }
                    ]
              }
            , { notes = "Por que o sorteio fica no Elm? As regras em Prolog são relações: mesma entrada, mesma saída. Sortear muda a cada vez, então é um efeito. Um Generator não sorteia, só descreve: 2 com peso 90, 4 com peso 10. Quem executa é o runtime."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "O sorteio é um efeito: quem executa é o runtime."
                    , Converte
                        { title = "puro  ×  efeito"
                        , pairs =
                            [ ( "move(B, left, N, S)", "mesma entrada → mesma saída (Prolog)" )
                            , ( "Random.weighted ( 90, 2 ) [ ( 10, 4 ) ]", "só descreve o sorteio (Generator)" )
                            , ( "Random.generate Spawned gerador", "o runtime sorteia → Msg Spawned" )
                            ]
                        }
                    ]
              }
            ]
      }
    ]


{-| O ciclo da arquitetura TEA, que gira sozinho.
-}
tea : List FlowNode
tea =
    [ { label = "Msg", sub = "o que aconteceu", detail = "Pressed Left", art = "keyboard" }
    , { label = "update", sub = "função pura", detail = "Msg → Model → (Model, Cmd)", art = "" }
    , { label = "Model", sub = "estado imutável", detail = "um valor novo; o antigo fica", art = "" }
    , { label = "view", sub = "desenha", detail = "Model → Html Msg", art = "elm" }
    ]
