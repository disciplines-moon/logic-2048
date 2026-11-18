module Cenas.Issue14 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, FlowNode, Scene)


cenas : List Scene
cenas =
    [ { issue = 14
      , title = "Conclusão"
      , steps =
            [ { notes = "Voltando ao começo: uma jogada é uma ida e volta. A tecla chega ao Elm, o Python leva o tabuleiro ao Prolog, e o Prolog decide. Cada paradigma ficou no que faz melhor."
              , blocks =
                    [ Lead "Prolog decide, Python traduz, Elm desenha."
                    , Flow { nodes = caminho, active = 3, back = "↩  e o resultado volta pelo mesmo caminho, em JSON" }
                    ]
              }
            , { notes = "Tudo junto, ao vivo. Carregue o tabuleiro quase vencido e ligue a IA: ela pede a dica ao Prolog, joga, e a vitória dispara a festa da #9. Depois, um desafio passo a passo, e o replay da partida."
              , blocks =
                    [ Clear
                    , Lead "Tudo o que foi mostrado funciona junto."
                    , Cenarios cenarios
                    , Demo
                    ]
              }
            , { notes = "Uma frase por paradigma. No lógico, as regras são relações, e a dica e os desafios são buscas que o Prolog faz sozinho por backtracking. No funcional, o estado só muda no update, uma função pura, e efeitos como HTTP, sorteio e som são dados. E a ponte só traduz formatos."
              , blocks =
                    [ Clear
                    , Lead "O que cada paradigma nos deu."
                    , Bullets
                        [ "Lógico (Prolog): regras como relações; dica e desafios são buscas por backtracking."
                        , "Funcional (Elm): o estado só muda no update; HTTP, sorteio e som são dados."
                        , "A ponte (Python): valida e traduz; nenhuma regra mora nela."
                        ]
                    ]
              }
            , { notes = "Com honestidade, os limites. A dica em Prolog é exata, mas cara: cada nível multiplica o trabalho, e por isso a profundidade é limitada. Uma IA que vença sempre precisaria de busca mais funda com poda. Os testes de interface são de lógica, não de clique. E a API depende do janus compilar em cada máquina."
              , blocks =
                    [ Clear
                    , Lead "O que faríamos com mais tempo."
                    , Bullets
                        [ "Dica mais funda, com poda e memória dos tabuleiros já vistos."
                        , "Testes de interface no navegador, além dos testes de lógica."
                        , "Empacotar a API para não depender de compilar o janus em cada máquina."
                        ]
                    ]
              }
            , { notes = "Obrigado. Cada um responde as perguntas sobre a própria parte."
              , blocks =
                    [ Clear
                    , Hero { title = "Perguntas?", subtitle = "Obrigado!", chips = [ "Prolog", "Python", "Elm" ] }
                    ]
              }
            ]
      }
    ]


caminho : List FlowNode
caminho =
    [ { label = "Teclado", sub = "você", detail = "", art = "" }
    , { label = "Elm", sub = "estado e tela", detail = "", art = "" }
    , { label = "Python", sub = "ponte", detail = "", art = "" }
    , { label = "Prolog", sub = "regras", detail = "Move, funde, pontua, dá a dica e resolve os desafios. O mesmo tabuleiro sempre dá a mesma resposta.", art = "" }
    ]


{-| Tabuleiros prontos para a demo final (não contam para o recorde).
-}
cenarios : List Etapa
cenarios =
    [ { label = "3×3 quase vencido", note = "", board = [ [ 128, 64, 64 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ] }
    , { label = "4×4 meio de jogo", note = "", board = [ [ 2, 4, 8, 16 ], [ 4, 8, 16, 2 ], [ 2, 0, 0, 0 ], [ 0, 0, 0, 4 ] ] }
    ]
