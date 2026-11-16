module Cenas.Issue07 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 7
      , title = "Elm: desfazer e replay"
      , steps =
            [ { notes = "Toda jogada que mexe guarda o jogo de antes numa lista. Em Elm nenhum valor muda depois de criado, então guardar um estado antigo é só guardar o próprio valor: ninguém vai alterá-lo depois. Não precisa copiar nada."
              , blocks =
                    [ Clear
                    , Lead "O histórico é uma lista de estados imutáveis."
                    , Code { file = "web/src/Game/History.elm", from = 31, to = 44, mark = [ 31, 32, 44 ] }
                    ]
              }
            , { notes = "Desfazer é tirar o primeiro da lista: devolve o estado anterior e o resto do histórico. Lista vazia, nada a desfazer, e o Maybe obriga a tratar esse caso."
              , blocks =
                    [ Clear
                    , Lead "Desfazer: tirar o primeiro da lista."
                    , Code { file = "web/src/Game/History.elm", from = 49, to = 56, mark = [ 52, 53 ] }
                    ]
              }
            , { notes = "No jogo, o estado anterior volta inteiro: tabuleiro, pontos e status, com a peça que tinha sido sorteada. Nada é recalculado nem sorteado de novo."
              , blocks =
                    [ Clear
                    , Code { file = "web/src/Game.elm", from = 484, to = 499, mark = [ 486, 490, 491, 492, 493 ] }
                    ]
              }
            , { notes = "Ao vivo: jogar 3 vezes com W, A, S, D e desfazer 2 com Ctrl+Z (Cmd+Z no Mac) ou com o botão. Volta ao estado depois da 1ª jogada, com a mesma peça sorteada. Ctrl+Z não vira jogada: as teclas de jogada ignoram Ctrl, Alt e Meta."
              , blocks =
                    [ Clear
                    , Lead "Jogue 3 vezes e desfaça 2: Ctrl+Z ou ↶ Desfazer."
                    , Demo
                    ]
              }
            , { notes = "O replay toca a mesma lista, do primeiro estado ao atual, com um relógio (Time.every). Não sorteia nem pergunta ao Prolog: os estados já estão guardados, por isso a partida sai idêntica. Dá para pausar e trocar a velocidade. As jogadas desfeitas saíram da lista, então o replay mostra só a partida que ficou."
              , blocks =
                    [ Clear
                    , Lead "Replay: a mesma lista, tocada em ordem."
                    , Demo
                    , Code { file = "web/src/Game/History.elm", from = 77, to = 83, mark = [ 79 ] }
                    ]
              }
            , { notes = "Com estado mutável, mover altera o tabuleiro no lugar. Guardar a referência não basta, porque a próxima jogada muda também o que foi guardado: é preciso copiar o tabuleiro inteiro a cada jogada, a cópia defensiva, e ninguém pode esquecer. Em Elm isso não existe: a imutabilidade deu desfazer e replay de graça."
              , blocks =
                    [ Clear
                    , Lead "Imutabilidade: desfazer e replay de graça."
                    , Pre "Mutável (JavaScript)\n  historico.push(tabuleiro)\n  mover(tabuleiro)                // o que foi guardado mudou junto!\n  historico.push(structuredClone(tabuleiro))   // cópia defensiva\n\nImutável (Elm)\n  remember model = History.push (snapshot model) model.history\n  -- o Model antigo nunca muda: guardar não custa uma cópia"
                    ]
              }
            ]
      }
    ]
