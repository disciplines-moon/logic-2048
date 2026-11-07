module Cenas.Intro exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene, Step)


cenas : List Scene
cenas =
    [ { issue = 17
      , title = "Logic2048"
      , steps =
            [ { notes = "Apresentar o grupo e o jogo."
              , blocks = [ Paragraph "2048 com três paradigmas trabalhando juntos." ]
              }
            , { notes = "Mostrar que o jogo já roda, ao vivo, dentro da apresentação."
              , blocks = [ Demo ]
              }
            ]
      }
    , { issue = 17
      , title = "Arquitetura"
      , steps =
            [ step "Fluxo de uma jogada, da tecla ao resultado. Começa no teclado." 0
            , step "Elm cuida do que o usuário vê e do sorteio das peças." 1
            , step "Python só traduz formatos e valida." 2
            , step "Prolog decide as regras: é puro, não sorteia nada. O resultado volta pelo mesmo caminho." 3
            ]
      }
    , { issue = 17
      , title = "Exemplo: código real aparecendo aos poucos"
      , steps =
            [ { notes = "O trecho vem do arquivo do repositório, sem copiar e colar."
              , blocks = [ Code { file = "prolog/game.pl", from = 1, to = 14, mark = [] } ]
              }
            , { notes = "Destacar o predicado que decide a vitória."
              , blocks = [ Clear, Code { file = "prolog/game.pl", from = 11, to = 14, mark = [ 12, 13 ] } ]
              }
            ]
      }
    ]


architecture : List FlowNode
architecture =
    [ { label = "Teclado", sub = "você", detail = "Uma seta vira uma mensagem para o app." }
    , { label = "Elm", sub = "interface", detail = "Estado, sorteio de peças, histórico, animações e ports. Tudo puro, exceto o que passa pelos ports." }
    , { label = "Python", sub = "ponte", detail = "Valida a entrada e traduz JSON para termos Prolog e de volta. Não tem regra de jogo." }
    , { label = "Prolog", sub = "regras", detail = "Mover, fundir, pontuar, dica e desafios. Puro: o mesmo tabuleiro dá sempre o mesmo resultado." }
    ]


step : String -> Int -> Step
step notes active =
    { notes = notes
    , blocks = [ Clear, Flow { nodes = architecture, active = active } ]
    }
