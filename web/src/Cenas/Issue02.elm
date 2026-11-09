module Cenas.Issue02 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 2
      , title = "Prolog: deslizar e fundir uma linha"
      , steps =
            [ { notes = "Em uma jogada, cada linha é independente. Vamos resolver só uma linha indo para a esquerda e depois reaproveitar para o tabuleiro todo."
              , blocks =
                    [ Lead "Uma linha de cada vez."
                    , Pre "  [2, 2, 4, 0]   ←   esquerda\n\n  [4, 4, 0, 0]   +4 pontos"
                    ]
              }
            , { notes = "O slide_left faz três coisas, uma por linha: tira os zeros, funde os pares e completa com zeros até o tamanho original. Por isso serve para N de 3 a 6."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 5, to = 12, mark = [ 10, 11, 12 ] }
                    ]
              }
            , { notes = "Em Prolog não há laço: o merge é definido por casos. O primeiro caso é a lista vazia, que não tem nada para fundir e vale 0 pontos. É ele que faz a recursão parar."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 14, to = 22, mark = [ 15 ] }
                    ]
              }
            , { notes = "Dois iguais seguidos: o padrão [X,X|T] usa o mesmo X duas vezes, então só casa se as duas peças forem iguais. A unificação faz a comparação por nós. A mesma cláusula cria a peça Y e soma Y aos pontos."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 14, to = 22, mark = [ 16, 18, 20 ] }
                    ]
              }
            , { notes = "Se o X não tem par, ele fica como está e a recursão segue no resto. Repare que a última cláusula só é tentada quando a de fusão não casou."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 14, to = 22, mark = [ 21, 22 ] }
                    ]
              }
            , { notes = "Rastreio de [2,2,2,2]. Depois de fundir, a recursão continua em T, e não em Y: a peça nova nunca volta para a entrada. Por isso cada peça funde uma vez só, e o resultado é [4,4,0,0], e não [8,0,0,0]."
              , blocks =
                    [ Clear
                    , Pre "merge([2,2,2,2], M, P)\n│  [X,X|T]  X = 2, T = [2,2]   →  Y = 4\n│  merge([2,2], R, Rest)\n│  │  [X,X|T]  X = 2, T = []   →  Y = 4\n│  │  merge([], [], 0)            caso base\n│  └  Rest = 0 + 4 = 4\n└  P = 4 + 4 = 8\n\nM = [4,4]   →   completa   →   [4,4,0,0]"
                    ]
              }
            , { notes = "A consulta de verdade, no swipl. Esta é a regra que o jogo inteiro vai usar, linha por linha: a #3 aplica o slide_left em cada linha com maplist e gira o tabuleiro para as outras direções."
              , blocks =
                    [ Clear
                    , Pre "?- slide_left([2,2,0,4], L, P).\nL = [4,4,0,0],\nP = 4.\n\n?- slide_left([2,2,2,2,8,8], L, P).\nL = [4,4,16,0,0,0],\nP = 24."
                    ]
              }
            , { notes = "Por que o corte. Sem o !, ao pedir outra resposta com ponto e vírgula, o Prolog volta atrás e tenta a última cláusula com o par, deixando o 2 sem fundir. O corte diz: achou o par, esta é a única resposta. Assim o slide_left é determinístico."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 16, to = 17, mark = [ 17 ] }
                    , Pre "% sem o !\n?- slide_left([2,2,0,0], L, P).\nL = [4,0,0,0], P = 4 ;\nL = [2,2,0,0], P = 0.      ← errado: o par não fundiu"
                    ]
              }
            , { notes = "E ao contrário? slide_left(X, [4,0,0,0], 4) pede a linha que gera esse resultado. Não funciona, porque o is/2 é aritmética de mão única e só calcula com valores prontos. Sem o must_be, o Prolog até começaria a inventar linhas, mas pararia no is/2 com esse mesmo erro, lá no meio do merge. O must_be acusa o problema logo na entrada: o modo é +Row, então a linha precisa vir pronta."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/game.pl", from = 8, to = 9, mark = [ 9 ] }
                    , Pre "?- slide_left(X, [4,0,0,0], 4).\nERROR: Arguments are not sufficiently instantiated"
                    ]
              }
            ]
      }
    ]
