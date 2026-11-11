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
      , title = "Quem fez o Logic2048"
      , steps =
            [ { notes = "Apresentar o grupo. Cada pessoa diz o próprio nome e qual parte vai apresentar."
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
      , title = "Primeiro, jogue"
      , steps =
            [ { notes = "Deixar a plateia jogar um pouco antes de explicar. Use W, A, S e D."
              , blocks = [ Lead "Este é o Logic2048. Jogue com W A S D.", Demo ]
              }
            , { notes = "Explicar o jogo para quem nunca viu: deslize as peças, junte as iguais, chegue ao 2048."
              , blocks = [ Bullets [ "O jogo: cada jogada desliza todas as peças. Duas peças iguais se fundem na soma delas, e o objetivo é chegar ao 2048." ] ]
              }
            , { notes = "Dizer o que o projeto é: o mesmo jogo, mas cada pedaço feito no paradigma mais adequado."
              , blocks = [ Bullets [ "O projeto: um 2048 completo em que as regras são lógica pura em Prolog, a tela é Elm e o Python liga os dois." ] ]
              }
            , { notes = "Dizer por que: é o trabalho de Paradigmas de Programação, e o objetivo é mostrar como paradigmas diferentes cooperam num produto só."
              , blocks = [ Bullets [ "Por quê: a disciplina é Paradigmas de Programação. Aqui o paradigma lógico (Prolog) e o funcional (Elm) resolvem partes diferentes do mesmo problema." ] ]
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
      , title = "O roteiro da apresentação"
      , steps =
            [ { notes = "Dizer que agora cada pessoa apresenta uma parte, na mesma ordem em que a jogada acontece."
              , blocks = [ Lead "Vamos seguir o caminho da jogada, da regra até a tela." ]
              }
            , { notes = "Prolog: o que decide a jogada."
              , blocks = [ Bullets [ "1. Prolog: as regras do jogo, a dica e os desafios." ] ]
              }
            , { notes = "Python: a ponte."
              , blocks = [ Bullets [ "2. Python: a ponte que leva o tabuleiro até as regras e traz a resposta." ] ]
              }
            , { notes = "Elm: o que o jogador vê."
              , blocks = [ Bullets [ "3. Elm: a tela, as animações e os sons." ] ]
              }
            , { notes = "Fechamento: como o grupo trabalhou."
              , blocks = [ Bullets [ "4. Como trabalhamos: issues, revisão em círculo e testes automáticos." ] ]
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
    , blocks = [ Clear, Flow { nodes = architecture, active = active, back = "↩  o resultado volta pelo mesmo caminho, em JSON" } ]
    }
