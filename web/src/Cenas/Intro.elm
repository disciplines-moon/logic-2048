module Cenas.Intro exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene, Step)


cenas : List Scene
cenas =
    [ { issue = 17
      , title = ""
      , steps =
            [ { notes = "Cumprimentar e dizer o nome do projeto. O jogo é o 2048, mas o foco é como cada paradigma resolve a sua parte."
              , blocks =
                    [ Hero
                        { title = "Logic2048"
                        , subtitle = "O 2048 em que cada paradigma faz o que faz de melhor."
                        , chips = [ "Prolog", "Python", "Elm" ]
                        }
                    ]
              }
            ]
      }
    , { issue = 17
      , title = "Primeiro, jogue"
      , steps =
            [ { notes = "Deixar a plateia ver o jogo funcionando antes de explicar. Jogue com as teclas W, A, S e D."
              , blocks =
                    [ Lead "Tudo o que vamos explicar está rodando aqui."
                    , Demo
                    ]
              }
            ]
      }
    , { issue = 17
      , title = "Como uma jogada acontece"
      , steps =
            [ step "Uma jogada é uma ida e volta. Ela começa no teclado." 0
            , step "O Elm recebe a tecla, guarda o estado e desenha a tela." 1
            , step "O Python recebe o tabuleiro em JSON, confere e repassa. Não conhece as regras do jogo." 2
            , step "O Prolog decide o resultado da jogada. O mesmo tabuleiro sempre dá a mesma resposta." 3
            ]
      }
    , { issue = 17
      , title = "O que vem a seguir"
      , steps =
            [ { notes = "Anunciar o roteiro: cada pessoa apresenta a sua parte."
              , blocks = [ Bullets [ "Prolog: as regras do jogo, a dica e os desafios." ] ]
              }
            , { notes = "Passar para a parte do Python."
              , blocks = [ Bullets [ "Python: a ponte entre a tela e as regras." ] ]
              }
            , { notes = "Passar para a parte do Elm."
              , blocks = [ Bullets [ "Elm: o que você vê, as animações e os sons." ] ]
              }
            , { notes = "Fechar anunciando como o grupo trabalhou."
              , blocks = [ Bullets [ "Como trabalhamos: issues, revisão e CI." ] ]
              }
            ]
      }
    ]


architecture : List FlowNode
architecture =
    [ { label = "Teclado", sub = "você", detail = "Você aperta uma tecla e o app recebe uma mensagem.", art = "keyboard" }
    , { label = "Elm", sub = "interface", detail = "Guarda o estado do jogo, sorteia as peças novas e desenha a tela. É puro, exceto o que passa pelos ports.", art = "elm" }
    , { label = "Python", sub = "ponte", detail = "Confere a entrada e traduz JSON para Prolog e de volta. Não tem regra de jogo.", art = "python" }
    , { label = "Prolog", sub = "regras", detail = "Move, funde, pontua e dá dicas. É puro: o mesmo tabuleiro sempre dá o mesmo resultado.", art = "prolog" }
    ]


step : String -> Int -> Step
step notes active =
    { notes = notes
    , blocks = [ Clear, Flow { nodes = architecture, active = active } ]
    }
