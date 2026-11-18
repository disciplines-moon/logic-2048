module Cenas.Issue10 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene)


cenas : List Scene
cenas =
    [ { issue = 10
      , title = "Python: a ponte para o Prolog"
      , steps =
            [ { notes = "O Python não decide nada de jogo. Ele recebe o tabuleiro em JSON, confere a entrada e, pelo janus, transforma em pergunta ao Prolog."
              , secs = 15
              , blocks = [ Flow { nodes = ponte, active = 2, back = "" } ]
              }
            , { notes = "O janus traduz os tipos entre os paradigmas. A string \"left\" vira o átomo left, e é por isso que a cláusula move_dir(left, ...) casa direto. Lista vira lista. Na volta, o Prolog liga N e S, e eles chegam num dict. Um par left-12.5 vira tupla, e falhar não é erro: volta como truth False."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "O janus traduz os tipos entre os dois paradigmas."
                    , Converte
                        { title = "Python  →  Prolog  →  Python"
                        , pairs =
                            [ ( "\"left\"", "left   (átomo)" )
                            , ( "[[2, 2, 0], [0, 4, 4], [0, 0, 8]]", "[[2,2,0],[0,4,4],[0,0,8]]   (lista)" )
                            , ( "game:move(B, D, N, S)", "{'N': [[4,0,0],[8,0,0],[8,0,0]], 'S': 12}" )
                            , ( "left-12.5", "('left', 12.5)" )
                            , ( "game_lost(B) falha", "{'truth': False}" )
                            ]
                        }
                    ]
              }
            , { notes = "Entrada inválida nunca chega ao Prolog. Os tipos e o validar_tabuleiro param cada erro na borda, com um 422 que diz o campo e o que vale, em português, porque o Elm mostra essa mensagem a quem joga. Só a jogada válida chega ao Prolog."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "Entrada inválida nunca chega ao Prolog."
                    , Converte
                        { title = "POST /api/move"
                        , pairs =
                            [ ( "\"direction\": \"diagonal\"", "422  direction: use 'left', 'right', 'up' ou 'down'" )
                            , ( "peça 3", "422  board: valor inválido 3: use 0 ou uma potência de 2" )
                            , ( "\"2\" no lugar de 2", "422  board[0][1]: deve ser um número inteiro" )
                            , ( "JSON quebrado", "422  JSON inválido" )
                            , ( "jogada válida", "200  board, score, moved, won, lost" )
                            ]
                        }
                    ]
              }
            ]
      }
    ]


{-| As mesmas etapas da cena "Como uma jogada acontece", agora com o foco no Python.
-}
ponte : List FlowNode
ponte =
    [ { label = "Teclado", sub = "você", detail = "", art = "keyboard" }
    , { label = "Elm", sub = "interface", detail = "", art = "elm" }
    , { label = "Python", sub = "ponte", detail = "Recebe o JSON, confere a entrada e, pelo janus, transforma em consulta Prolog. Não conhece as regras do 2048.", art = "python" }
    , { label = "Prolog", sub = "regras", detail = "", art = "prolog" }
    ]
