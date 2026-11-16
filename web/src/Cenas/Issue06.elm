module Cenas.Issue06 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Scene, Step)


cenas : List Scene
cenas =
    [ { issue = 6
      , title = "Elm: estado, Random e TEA"
      , steps =
            [ cycle "Toda tela em Elm segue o mesmo ciclo, a arquitetura TEA. Começa com uma Msg: um valor que descreve o que aconteceu. Apertar A (esquerda) vira Pressed Left. Ainda não mudou nada." 0
            , cycle "A Msg vai para o update, uma função pura: recebe a Msg e o Model antigo e devolve um Model novo. É o único lugar onde o estado muda. Não há atribuição solta pelo código." 1
            , cycle "O Model novo é outro valor. O antigo continua intacto, porque em Elm nada é mutável. É isso que a #7 vai usar para desfazer: guardar os estados antigos." 2
            , cycle "A view só lê o Model e desenha. Não sorteia, não fala com o servidor. Depois de desenhar, o app espera a próxima Msg e o ciclo recomeça." 3
            , { notes = "O estado do jogo inteiro cabe nesse registro: tabuleiro, tamanho, pontos e status. Histórico e replay são da próxima cena (#7), os quatro seguintes (tema, peças com identidade, próximo id e câmera lenta) são da tela, na #8, e os cinco últimos (recordes, som, comemoração e tela de vitória) são da #9."
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 111, to = 130, mark = [ 112, 113, 114, 115 ] }
                    ]
              }
            , { notes = "E as Msg são tudo o que pode acontecer: tecla, resposta do servidor, peças sorteadas, novo jogo, troca de tamanho, toque na tela. Desfazer e replay também são da #7."
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 187, to = 206, mark = [ 188, 189, 190 ] }
                    ]
              }
            , { notes = "Apertar uma tecla não muda o tabuleiro. O update devolve um par: o Model, só marcando que está esperando, e um Cmd, que é um pedido para o runtime do Elm fazer o POST /api/move. Quem decide a jogada é o Prolog."
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 285, to = 293, mark = [ 288, 293 ] }
                    ]
              }
            , { notes = "Quando o Prolog responde, o update soma os pontos. Se o tabuleiro mudou, pede ao runtime um sorteio com Random.generate. Se não mudou, não sorteia nada. O resultado do sorteio volta como mais uma Msg, Spawned. Detalhe: a derrota só aparece na tecla seguinte ao tabuleiro travar. Quem sabe se ainda há jogada é o Prolog, e ele responde sobre o tabuleiro de antes do sorteio; o Elm só descobre que travou ao mandar a próxima jogada."
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 426, to = 444, mark = [ 433, 438, 440, 444 ] }
                    ]
              }
            , { notes = "Por que o sorteio fica no Elm? O Prolog é puro: o mesmo tabuleiro sempre dá a mesma resposta. Sortear dá um resultado diferente a cada vez, então é um efeito. Um Generator não sorteia: só descreve o sorteio. 2 com peso 90, 4 com peso 10, numa casa vazia qualquer. Quem executa é o runtime."
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 812, to = 814, mark = [ 814 ] }
                    , Code { file = "web/src/Game.elm", from = 819, to = 828, mark = [ 827 ] }
                    , Pre "Prolog   move(Board, left, New, Score)      mesma entrada → mesma saída\nElm      Random.generate Spawned gerador    o runtime sorteia → Msg"
                    ]
              }
            , { notes = "Agora ao vivo. Jogar com W, A, S, D. Cada tecla vira uma Msg, o update troca o Model e a view redesenha. Repare: a cada jogada que mexe nasce exatamente uma peça; se a jogada não mexe, nada nasce."
              , blocks =
                    [ Clear
                    , Lead "Cada tecla: Msg → update → Model novo → view."
                    , Demo
                    , Code { file = "web/src/Game.elm", from = 438, to = 444, mark = [ 440 ] }
                    ]
              }
            , { notes = "Trocar o tamanho do tabuleiro ao vivo, de 3 a 6. É o mesmo código para qualquer N: a Msg SizeChosen só cria um jogo novo com o N escolhido, e o Prolog recebe o tabuleiro do tamanho que vier."
              , blocks =
                    [ Code { file = "web/src/Game.elm", from = 314, to = 316, mark = [ 314, 316 ] }
                    ]
              }
            ]
      }
    ]


{-| O ciclo da arquitetura TEA. Cada passo acende uma etapa.
-}
tea : List FlowNode
tea =
    [ { label = "Msg", sub = "o que aconteceu", detail = "Apertar A vira um valor: Pressed Left. Nada mudou ainda.", art = "keyboard" }
    , { label = "update", sub = "função pura", detail = "update : Msg -> Model -> ( Model, Cmd Msg ). Recebe a Msg e o Model antigo e devolve um Model novo.", art = "" }
    , { label = "Model", sub = "estado imutável", detail = "Um valor novo. O Model antigo continua igual e pode ser guardado.", art = "" }
    , { label = "view", sub = "desenha", detail = "view : Model -> Html Msg. Só lê o Model: nada de servidor nem sorteio aqui.", art = "" }
    ]


cycle : String -> Int -> Step
cycle notes active =
    { notes = notes
    , blocks = [ Clear, Flow { nodes = tea, active = active, back = "↩  a view espera a próxima Msg, e o ciclo recomeça" } ]
    }
