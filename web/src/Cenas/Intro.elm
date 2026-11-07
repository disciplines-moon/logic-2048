module Cenas.Intro exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


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
            [ { notes = "Fluxo de uma jogada, da tecla ao resultado."
              , blocks =
                    [ Pre "Teclado -> Elm --(JSON/HTTP)--> Python --(janus)--> Prolog\n          ^                                       |\n          '-------------- resultado em JSON ------'"
                    ]
              }
            , { notes = "Prolog decide as regras: é puro, não sorteia nada."
              , blocks = [ Bullets [ "Prolog: mover, fundir, pontuar, dica e desafios." ] ]
              }
            , { notes = "Python só traduz formatos e valida."
              , blocks = [ Bullets [ "Python: valida e traduz. Sem regra de jogo." ] ]
              }
            , { notes = "Elm cuida do que o usuário vê e do sorteio das peças."
              , blocks = [ Bullets [ "Elm: estado, sorteio, histórico, animações e ports." ] ]
              }
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
