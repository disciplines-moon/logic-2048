module Cenas.Issue11 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Pedido, Scene)


cenas : List Scene
cenas =
    [ { issue = 11
      , title = "Python: dica e desafios na API"
      , steps =
            [ { notes = "A mesma ponte ganha a dica e os desafios. O caminho de uma dica: o Elm manda o tabuleiro, o Python valida e pergunta game:hint ao Prolog, e a resposta volta no formato do contrato."
              , secs = 15
              , blocks =
                    [ Lead "Mesma ponte, mais três serviços: dica, desafio e a lista de desafios."
                    , Ciclo { nodes = dica, back = "" }
                    ]
              }
            , { notes = "O trabalho de verdade é converter na fronteira. O Prolog diz none quando não há jogada; o JSON diz null. Pares viram objeto. No desafio, não ter solução é falhar; no JSON, é solvable false. E com muitas casas vazias, a profundidade cai para 2, para a dica não travar o servidor."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "O Prolog fala em átomos e falhas; o JSON, em null e booleanos."
                    , Code { file = "server/extras.py", from = 127, to = 131, mark = [ 129, 130 ] }
                    , Converte
                        { title = "Prolog  →  JSON"
                        , pairs =
                            [ ( "Best = none", "\"direction\": null" )
                            , ( "[left-135.67, right-135.67, down-134.73]", "\"scores\": {\"left\": 135.67, …}" )
                            , ( "challenge/4 falha", "\"solvable\": false, \"moves\": []" )
                            , ( "depth 3 com 14 casas vazias", "\"depth\": 2" )
                            ]
                        }
                    ]
              }
            , { notes = "Ao vivo, pedidos de verdade ao /api/hint. Duas peças: a dica é left, empatada com right. Tabuleiro travado: direction null. Depth 4 é recusado com 422, em português."
              , secs = 15
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: pedidos de verdade ao /api/hint."
                    , PedidosEm "/api/hint" pedidosDica
                    ]
              }
            ]
      }
    ]


{-| O caminho de uma dica, que gira sozinho.
-}
dica : List FlowNode
dica =
    [ { label = "Elm", sub = "botão Dica", detail = "", art = "elm" }
    , { label = "JSON", sub = "board, depth", detail = "", art = "" }
    , { label = "Python", sub = "valida", detail = "", art = "python" }
    , { label = "Prolog", sub = "hint/4", detail = "", art = "prolog" }
    , { label = "JSON", sub = "direction, scores", detail = "", art = "" }
    ]


pedidosDica : List Pedido
pedidosDica =
    [ { label = "duas peças", body = "{\n  \"board\": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],\n  \"depth\": 2\n}" }
    , { label = "travado: sem jogada", body = "{\n  \"board\": [[2,4,2],[4,2,4],[2,4,2]]\n}" }
    , { label = "depth 4", body = "{\n  \"board\": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],\n  \"depth\": 4\n}" }
    ]
