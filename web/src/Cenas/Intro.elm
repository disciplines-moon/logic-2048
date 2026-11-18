module Cenas.Intro exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene, Step)


cenas : List Scene
cenas =
    [ { issue = 17
      , title = ""
      , steps =
            [ { notes = "Boa tarde! Este é o Logic2048: o jogo 2048, mas o foco é como cada paradigma resolve a sua parte. Prolog decide, Python traduz e Elm desenha."
              , secs = 15
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
      , title = "Quem fez o Logic2048"
      , steps =
            [ { notes = "Cada pessoa diz o próprio nome e o que vai apresentar, numa frase. Cada um apresenta as issues que implementou."
              , secs = 30
              , blocks =
                    [ Team
                        [ { name = "Victor Schmidt", login = "moonshinerd" }
                        , { name = "Bianca Patrocínio", login = "BiancaPatrocinio7" }
                        , { name = "Davi Aguiar", login = "davi-aguiar-vieira" }
                        , { name = "Kaio Macedo", login = "Bigkaio" }
                        , { name = "Mateus Castro", login = "mat054" }
                        , { name = "Mateus Henrique", login = "Mateushqms" }
                        , { name = "William Bernardo", login = "willxbernardo" }
                        ]
                    ]
              }
            ]
      }
    , { issue = 17
      , title = "Como uma jogada acontece"
      , steps =
            [ step "Uma jogada é uma ida e volta, e começa no teclado." 10 0
            , step "O Elm vira a tecla numa mensagem, guarda o estado, sorteia as peças novas e desenha a tela." 12 1
            , step "O Python só confere o JSON e traduz para uma pergunta ao Prolog. Ele não conhece as regras." 12 2
            , step "O Prolog decide a jogada. É puro: o mesmo tabuleiro sempre dá a mesma resposta. Vamos seguir esse caminho, começando pelas regras." 12 3
            ]
      }
    ]


architecture : List FlowNode
architecture =
    [ { label = "Teclado", sub = "você", detail = "Você aperta uma tecla e o app recebe uma mensagem.", art = "keyboard" }
    , { label = "Elm", sub = "interface", detail = "Guarda o estado do jogo, sorteia as peças novas e desenha a tela.", art = "elm" }
    , { label = "Python", sub = "ponte", detail = "Confere a entrada e traduz JSON para Prolog e de volta. Não tem regra de jogo.", art = "python" }
    , { label = "Prolog", sub = "regras", detail = "Move, funde, pontua e dá dicas. O mesmo tabuleiro sempre dá o mesmo resultado.", art = "prolog" }
    ]


step : String -> Int -> Int -> Step
step notes secs active =
    { notes = notes
    , secs = secs
    , blocks = [ Clear, Flow { nodes = architecture, active = active, back = "↩  o resultado volta pelo mesmo caminho, em JSON" } ]
    }
