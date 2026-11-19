module Cenas.Issue02 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 2
      , title = "Prolog: deslizar e fundir uma linha"
      , steps =
            [ { notes = "Numa jogada, cada linha é independente. Então resolvemos uma linha indo para a esquerda. O slide_left faz três coisas: tira os zeros, funde os pares e completa com zeros. Serve para qualquer tamanho."
              , secs = 20
              , blocks =
                    [ Lead "Uma linha de cada vez: tira os zeros, funde, completa."
                    , Code { file = "prolog/game.pl", from = 8, to = 12, mark = [ 10, 11, 12 ] }
                    , Fases [ 2, 0, 2, 4 ]
                    ]
              }
            , { notes = "Não há laço: o merge é definido por casos. A lista vazia é o caso base. O padrão [X,X|T] usa o mesmo X duas vezes, então só casa com duas peças iguais: a unificação compara por nós. Sem par, a peça fica. Depois de fundir, a recursão segue no resto, por isso [2,2,2,2] vira [4,4], e não [8]."
              , secs = 25
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 14, to = 22, mark = [ 15, 16, 19, 21 ] }
                    , Slide [ 2, 2, 2, 2 ]
                    ]
              }
            , { notes = "E o corte. Sem o !, ao pedir outra resposta, o Prolog voltaria atrás e tentaria a última cláusula com o par, deixando o 2 sem fundir. O corte diz: achou o par, esta é a única resposta."
              , secs = 20
              , blocks =
                    [ Clear
                    , Lead "O corte: uma resposta só, e a certa."
                    , Code { file = "prolog/game.pl", from = 16, to = 17, mark = [ 17 ] }
                    , Corte
                    ]
              }
            ]
      }
    ]
