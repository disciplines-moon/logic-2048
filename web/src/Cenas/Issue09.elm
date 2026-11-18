module Cenas.Issue09 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, FlowNode, Scene, Step)


cenas : List Scene
cenas =
    [ { issue = 9
      , title = "Elm: ports, sons e confete"
      , steps =
            [ caminho "O Elm é puro: ele não toca som nem mexe no navegador. Quando uma jogada termina, o update decide o que deve acontecer lá fora, por exemplo um som de fusão. Essa decisão é só um valor, um Effect. Ainda não aconteceu nada." 1
            , caminho "O valor sai do Elm por um port: a única porta para o mundo de fora, com tipo checado. Do outro lado, o JavaScript recebe a mensagem e executa o efeito: toca o som, solta o confete, grava no navegador. O Elm só descreveu o que queria." 3
            , { notes = "Os ports são declarados num lugar só, o Ports.elm. Cada um tem tipo: playSound recebe um texto, celebrate não recebe nada, e saveBest, mais abaixo no arquivo, recebe um registro com tamanho e recorde. Não passa qualquer coisa. No main.js, cada port é ligado a uma função JavaScript: sons.js, confete.js e memoria.js, como no jogo da memória."
              , blocks =
                    [ Clear
                    , Lead "O port é tipado: não passa qualquer coisa."
                    , Code { file = "web/src/Ports.elm", from = 14, to = 21, mark = [ 16, 21 ] }
                    , Code { file = "web/src/main.js", from = 57, to = 61, mark = [ 57, 58 ] }
                    ]
              }
            , { notes = "Quem decide os efeitos é uma função pura, reactions. A vitória vem do Prolog: o won da resposta. Mas o won continua verdadeiro depois de vencer, então o confete só sai se a partida ainda não comemorou: é o campo celebrated, guardado no Model. O mesmo para a derrota, o lost do Prolog na primeira vez. E o recorde só conta se o placar passou o recorde daquele tamanho."
              , blocks =
                    [ Clear
                    , Lead "Confete quando o Prolog diz won, uma vez por partida."
                    , Code { file = "web/src/Game.elm", from = 562, to = 576, mark = [ 566, 569, 572 ] }
                    ]
              }
            , { notes = "Ao vivo. Fusões, A: cada fusão manda uma mensagem ao port de som. Quase vencido, A: o Prolog responde won e vem a festa (fanfarra, confete, fogos e chuva de peças 2048), tudo em JavaScript a partir de dois ports. Continuar jogando e outra tecla: o won segue true, mas a festa não repete."
              , blocks =
                    [ Clear
                    , Lead "O mesmo mecanismo, outro efeito."
                    , Demo
                    , Cenarios
                        [ etapa "fusões: aperte A" "" fusoes
                        , etapa "quase vencido: A" "" quaseVencido
                        ]
                    ]
              }
            , { notes = "E o estado inicial? O recorde de cada tamanho, o tema e o som desligado ficam no localStorage do navegador. Ao abrir a página, o main.js lê tudo e entrega ao Elm pelas flags, antes do primeiro init. Experimente: anote o recorde, aperte F5, e ele volta. Os cenários prontos da apresentação não contam para o recorde."
              , blocks =
                    [ Clear
                    , Lead "O estado inicial entra no Elm por flags."
                    , Code { file = "web/src/main.js", from = 49, to = 49, mark = [ 49 ] }
                    , Code { file = "web/src/memoria.js", from = 39, to = 45, mark = [ 41, 42, 43 ] }
                    ]
              }
            , { notes = "O botão de som é só mais uma Msg: o update troca o campo muted e manda o port saveMuted, para a escolha valer na próxima visita. Com o som desligado, reactions simplesmente não inclui sons na lista de efeitos; o confete e o recorde continuam. Desligar aqui na demo, jogar, e ver que nada toca."
              , blocks =
                    [ Clear
                    , Lead "Silenciar é decidir no Elm, lembrar no navegador."
                    , Demo
                    , Code { file = "web/src/Game.elm", from = 377, to = 378, mark = [ 378 ] }
                    ]
              }
            ]
      }
    ]


{-| O caminho de um efeito, do update ao navegador. Cada passo acende uma etapa.
-}
efeito : List FlowNode
efeito =
    [ { label = "update", sub = "função pura", detail = "Recebe a resposta do Prolog e decide os efeitos da jogada.", art = "" }
    , { label = "Effect", sub = "um valor", detail = "Sound Merge, Confetti, SaveBest 4 2048: a descrição do efeito, não o efeito.", art = "" }
    , { label = "port", sub = "Cmd tipado", detail = "perform transforma o valor num Cmd de port: a única saída do Elm.", art = "" }
    , { label = "JavaScript", sub = "executa", detail = "sons.js toca, confete.js desenha, memoria.js grava no localStorage.", art = "" }
    ]


caminho : String -> Int -> Step
caminho notes active =
    { notes = notes
    , blocks = [ Clear, Flow { nodes = efeito, active = active, back = "↩  na próxima visita, o que foi gravado volta ao Elm pelas flags" } ]
    }


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }


{-| Com A: os pares de 2 e de 4 fundem (som de fusão), o 8 só desliza.
-}
fusoes : List (List Int)
fusoes =
    [ [ 2, 2, 0, 0 ], [ 0, 0, 0, 8 ], [ 4, 0, 4, 0 ], [ 16, 0, 0, 0 ] ]


{-| Com A: 1024 + 1024 = 2048, e o Prolog responde won (o mesmo cenário da #4).
-}
quaseVencido : List (List Int)
quaseVencido =
    [ [ 1024, 1024, 0, 0 ], [ 4, 8, 2, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
