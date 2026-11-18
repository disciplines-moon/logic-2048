module Cenas.Issue13 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene)


cenas : List Scene
cenas =
    [ { issue = 13
      , title = "Como trabalhamos"
      , steps =
            [ { notes = "Cada issue virou um PR, com um revisor do grupo, e em todo PR a CI roda as três camadas: 164 testes de Prolog, 55 de Python e 153 de Elm. Só depois do verde e da revisão entra na main. E um comando só sobe tudo, inclusive esta apresentação."
              , secs = 20
              , blocks =
                    [ Lead "Todo PR: revisão de outra pessoa e a CI das três camadas."
                    , Ciclo { nodes = ci, back = "sh scripts/rodar.sh  →  API e interface juntas em http://localhost:8000" }
                    ]
              }
            ]
      }
    ]


{-| O caminho de um PR até a main, que gira sozinho.
-}
ci : List FlowNode
ci =
    [ { label = "PR", sub = "uma issue", detail = "Closes #N", art = "" }
    , { label = "Prolog", sub = "plunit", detail = "164 testes", art = "prolog" }
    , { label = "Python", sub = "pytest", detail = "55 testes", art = "python" }
    , { label = "Elm", sub = "elm-test", detail = "153 testes", art = "elm" }
    , { label = "main", sub = "revisado", detail = "merge", art = "" }
    ]
