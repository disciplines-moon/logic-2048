module Cenas.Issue20 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene)


cenas : List Scene
cenas =
    [ { issue = 20
      , title = "Elm: dica, IA e desafios"
      , steps =
            [ { notes = "O jogo já entra no meio da partida. Ligue a Dica: o Elm manda o tabuleiro e segue a vida; a resposta chega depois, como mais uma Msg. Agora ligue a IA: ela é dica seguida de jogada, em loop, pelo mesmo caminho de uma tecla. Por isso o desfazer e a festa funcionam. Dá para mudar a velocidade e pausar."
              , secs = 20
              , blocks =
                    [ Lead "Ao vivo: Dica e IA joga."
                    , DemoCom meioDeJogo
                    ]
              }
            , { notes = "Por dentro, a IA é uma máquina de estados. O relógio, o Time.every, só existe quando ela está jogando e nada está em voo. Assim nunca há duas requisições ao mesmo tempo. Ela para sozinha ao vencer, perder ou dar erro, e diz por quê."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "Uma máquina de estados: no máximo uma requisição em voo."
                    , Ciclo { nodes = maquina, back = "vence, perde, sem jogada ou erro  →  Off, com o motivo na tela" }
                    , Code { file = "web/src/Game/Assist.elm", from = 222, to = 225, mark = [ 224, 225 ] }
                    ]
              }
            , { notes = "E se a API cair? Falha é um valor: o Http devolve um Result, e o nosso tipo Error tem um caso para cada problema. O compilador obriga a tratar todos, e cada um vira uma frase. O 422 traz a mensagem do servidor. O jogo não trava."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "Falha é um valor, e cada caso vira uma frase."
                    , Converte
                        { title = "Api.Error  →  mensagem na tela"
                        , pairs =
                            [ ( "Network", "Sem resposta do servidor. A API está rodando?" )
                            , ( "Rejected msg   (422)", "O servidor recusou o pedido: msg" )
                            , ( "Server 500", "Erro no servidor (500). Tente de novo." )
                            , ( "Invalid", "Resposta inválida do servidor." )
                            ]
                        }
                    ]
              }
            ]
      }
    ]


{-| A IA por dentro, que gira sozinha.
-}
maquina : List FlowNode
maquina =
    [ { label = "Playing", sub = "espera o intervalo", detail = "Time.every", art = "" }
    , { label = "Thinking", sub = "dica em voo", detail = "POST /api/hint", art = "prolog" }
    , { label = "GotHint", sub = "chegou a direção", detail = "Play dir", art = "" }
    , { label = "Playing", sub = "jogada em voo", detail = "POST /api/move", art = "elm" }
    ]


{-| Meio de partida: a Dica tem o que escolher e a IA tem o que jogar (um
tabuleiro carregado não conta para o recorde).
-}
meioDeJogo : List (List Int)
meioDeJogo =
    [ [ 2, 4, 8, 16 ], [ 4, 8, 16, 2 ], [ 2, 0, 0, 0 ], [ 0, 0, 0, 4 ] ]
