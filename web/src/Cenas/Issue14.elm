module Cenas.Issue14 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 14
      , title = "Conclusão"
      , steps =
            [ { notes = "Uma frase por paradigma. No lógico, as regras são relações, e a dica e os desafios são buscas que o Prolog faz por backtracking. No funcional, o estado só muda no update, e efeitos como HTTP, sorteio e som são dados. A ponte só traduz. O limite: a dica é exata, mas cara, então a profundidade é limitada."
              , secs = 25
              , blocks =
                    [ Lead "O que cada paradigma nos deu."
                    , Bullets
                        [ "Lógico (Prolog): regras como relações; dica e desafios são buscas por backtracking."
                        , "Funcional (Elm): o estado só muda no update; HTTP, sorteio e som são dados."
                        , "A ponte (Python): valida e traduz; nenhuma regra mora nela."
                        ]
                    ]
              }
            , { notes = "Obrigado! Cada um responde as perguntas sobre a própria parte."
              , secs = 10
              , blocks =
                    [ Clear
                    , Hero { title = "Perguntas?", subtitle = "Obrigado!", chips = [ "Prolog", "Python", "Elm" ] }
                    ]
              }
            ]
      }
    ]
