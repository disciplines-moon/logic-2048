module Cenas.Issue20 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 20
      , title = "Elm: dica, IA e desafios"
      , steps =
            [ { notes = "Clique em Dica para ligar as dicas. O Elm manda o tabuleiro para o /api/hint e segue a vida: a resposta chega depois, como mais uma Msg, GotHint. A seta que aparece é a direção que o Prolog escolheu, e embaixo está o valor esperado de cada direção. A dica vale só para este tabuleiro: jogou, o Elm pede a próxima sozinho. Clique de novo e as dicas desligam."
              , blocks =
                    [ Lead "O Elm pergunta; a resposta chega como Msg."
                    , Cenarios cenarios
                    , Demo
                    ]
              }
            , { notes = "Agora ligue a IA. Ela é só dica seguida de jogada, em loop. A jogada vai pelo mesmo caminho de uma tecla, então o Elm sorteia a peça nova, o desfazer funciona e as comemorações da #9 também. Enquanto ela joga, as setas de quem joga são ignoradas. Dá para mudar a velocidade e pausar."
              , blocks =
                    [ Clear
                    , Lead "Modo IA: dica, jogada, intervalo, de novo."
                    , Demo
                    ]
              }
            , { notes = "Por dentro, a IA é uma máquina de estados com três estados. Desligada. Pensando: a dica está em voo. Jogando: a jogada foi mandada, ou a IA espera o intervalo. O relógio, o Time.every, só existe no estado Jogando e com o jogo parado. Assim nunca há duas requisições ao mesmo tempo. O mesmo relógio, com as dicas ligadas, pede a dica nova quando o tabuleiro muda."
              , blocks =
                    [ Clear
                    , Lead "Uma máquina de estados: no máximo uma requisição em voo."
                    , Pre "  Off ──ligar──▶ Playing ──Time.every──▶ Thinking ──GotHint──▶ Playing ── …\n                   │                       (POST /api/hint)    (POST /api/move)\n                   └── vence, perde, sem jogada ou erro ──▶ Off"
                    , Code { file = "web/src/Game/Assist.elm", from = 212, to = 224, mark = [ 216, 217, 219, 221 ] }
                    ]
              }
            , { notes = "O tique decide. Se o jogo acabou, se a IA venceu nesta corrida ou se deu erro, ela para sozinha e diz por quê. Senão, passa a Thinking e pede a dica."
              , blocks =
                    [ Clear
                    , Lead "O tique decide: parar ou pedir a dica."
                    , Code { file = "web/src/Game/Assist.elm", from = 276, to = 285, mark = [ 280, 282, 285 ] }
                    ]
              }
            , { notes = "Quando a dica chega, a IA manda jogar a direção e volta a Playing. Se não há jogada, ela para, avisa, e pede ao Prolog que declare o fim de jogo. Repare que o Assist não joga nada: ele devolve uma ação, Play dir, e quem executa é o Game."
              , blocks =
                    [ Clear
                    , Lead "O Assist decide; o Game executa."
                    , Code { file = "web/src/Game/Assist.elm", from = 402, to = 409, mark = [ 405, 409 ] }
                    ]
              }
            , { notes = "A tela de desafios. Abra Desafios e escolha o primeiro: chegar a 16 em 3 jogadas. O Prolog devolve a menor sequência, e cada Próximo passo aplica uma jogada. Nenhuma peça nasce no desafio: só deslizar e fundir o que já está lá."
              , blocks =
                    [ Clear
                    , Lead "Desafios: a solução do Prolog, passo a passo."
                    , Demo
                    ]
              }
            , { notes = "A diferença entre a IA e o desafio está aqui. Play joga como uma tecla: depois da resposta do Prolog, o Elm sorteia a peça nova. Step só aplica a resposta do Prolog no tabuleiro, sem sorteio nenhum."
              , blocks =
                    [ Clear
                    , Lead "IA sorteia peça; desafio não."
                    , Code { file = "web/src/Game.elm", from = 992, to = 998, mark = [ 994, 998 ] }
                    ]
              }
            , { notes = "E se a API cair? Falha é um valor: o Http volta com um Result, e o nosso tipo Error tem um caso para cada problema. Como é um tipo, o compilador obriga quem usa a tratar todos os casos."
              , blocks =
                    [ Clear
                    , Lead "Falha é um valor (Result), e o compilador obriga a tratar."
                    , Code { file = "web/src/Api.elm", from = 297, to = 301, mark = [ 298, 299, 300, 301 ] }
                    ]
              }
            , { notes = "Cada resposta vira um caso. O 422 vem com a mensagem do servidor no corpo, e por isso usamos expectStringResponse: o expectJson jogaria esse corpo fora. Com a API parada, o proxy do Vite responde 502: para quem joga, é o mesmo que nenhuma resposta, como a rede fora."
              , blocks =
                    [ Clear
                    , Lead "O 422 traz a mensagem no corpo."
                    , Code { file = "web/src/Api.elm", from = 316, to = 330, mark = [ 324, 326, 330 ] }
                    ]
              }
            , { notes = "Cada caso vira uma frase diferente: sem resposta, pedido recusado com a mensagem do servidor, erro do servidor ou resposta fora do formato. O jogo não trava: a mensagem aparece embaixo e dá para continuar. Ao vivo: pare a API no terminal e clique em Dica."
              , blocks =
                    [ Clear
                    , Lead "Rede, 422 e resposta inválida têm mensagens diferentes."
                    , Code { file = "web/src/Api.elm", from = 338, to = 351, mark = [ 342, 345, 348, 351 ] }
                    , Demo
                    ]
              }
            ]
      }
    ]


{-| Tabuleiros prontos para a dica e a IA (não contam para o recorde).
-}
cenarios : List Etapa
cenarios =
    [ { label = "duas peças", note = "", board = [ [ 2, 2, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ] }
    , { label = "meio de jogo", note = "", board = [ [ 2, 4, 8, 16 ], [ 4, 8, 16, 2 ], [ 2, 0, 0, 0 ], [ 0, 0, 0, 4 ] ] }
    ]
