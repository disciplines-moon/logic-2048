module Cenas.Issue05 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 5
      , title = "Prolog: dica com expectimax"
      , steps =
            [ { notes = "O problema da dica. Eu escolho a jogada, mas depois dela nasce uma peça ao acaso, numa casa vazia qualquer: 2 com 90% de chance e 4 com 10%. Quem sorteia é o Elm; o Prolog não sabe qual vai sair. Uma jogada boa agora pode ficar ruim depois da peça sorteada. Então, como decidir sob incerteza?"
              , blocks =
                    [ Lead "Depois da minha jogada, uma peça nasce ao acaso. Qual jogada escolher?"
                    , Tabuleiros
                        [ etapa "Board" "" arvore
                        , etapa "right" "" arvoreRight
                        , etapa "nasce 2" "90%" arvoreRight2
                        , etapa "nasce 4" "10%" arvoreRight4
                        ]
                    ]
              }
            , { notes = "A ideia do expectimax é uma árvore com dois tipos de nó. No nó de máximo é a minha vez: fico com a jogada de maior valor. No nó de sorteio é a vez do acaso: não dá para escolher, então calculo a média ponderada sobre todas as casas vazias, com 90% para o 2 e 10% para o 4. Esta é a árvore real deste tabuleiro com profundidade 1: cada jogada deixa uma casa vazia só, então cada sorteio tem dois filhos. No fim, a heurística dá uma nota a cada tabuleiro."
              , blocks =
                    [ Clear
                    , Lead "Máximo nas minhas jogadas, média no sorteio."
                    , Pre arvoreTexto
                    ]
              }
            , { notes = "As contas. O left vale 0,9 vezes 20 mais 0,1 vezes 22, que dá 20,2. O right dá 22 com qualquer peça. O up dá 14. O nó de máximo fica com o right. Repare que o left perde por causa da média: ele só é bom se nascer um 4, que é raro. Isso o Prolog responde de verdade, e o teste cena_issue05 confere estes números."
              , blocks =
                    [ Pre "left : 0,9 × 20 + 0,1 × 22 = 20,2\nright: 0,9 × 22 + 0,1 × 22 = 22,0   ← máximo\nup   : 0,9 × 14 + 0,1 × 14 = 14,0\n\n?- hint([[2,0,4],[4,8,16],[2,32,64]], 1, Best, Scores).\nBest = right,\nScores = [left-20.2, right-22.0, up-14.0]."
                    ]
              }
            , { notes = "Sem heurística não dá para comparar tabuleiros no fim da busca, porque não sabemos quem vai ganhar. A nota junta três ideias de quem joga bem: casas vazias valem 10 cada, porque espaço é tempo de vida. Desordem tira pontos: em cada linha e coluna, somo as subidas e as descidas, em log2, e fico com a menor; uma linha toda em ordem dá zero. E a maior peça num canto ganha um bônus. A nota não depende do lado: espelhar o tabuleiro dá a mesma nota."
              , blocks =
                    [ Clear
                    , Lead "A heurística: a nota de um tabuleiro no fim da busca."
                    , Code { file = "prolog/hint.pl", from = 129, to = 138, mark = [ 135, 136, 137, 138 ] }
                    , Bullets
                        [ "Casas vazias: mais espaço, mais tempo até perder."
                        , "Monotonicidade: linhas e colunas em ordem facilitam fundir."
                        , "Maior peça no canto: no meio, ela atrapalha tudo em volta."
                        ]
                    ]
              }
            , { notes = "O nó de máximo. Profundidade zero: acabou a busca, avalio. Senão, o findall junta os filhos, que são as jogadas que mudam o tabuleiro, e o aggregate_all com max fica com o maior valor. Não tem laço: o member volta atrás por backtracking em cada filho, e o aggregate_all junta as respostas."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/hint.pl", from = 59, to = 72, mark = [ 61, 63, 65, 68, 69, 70 ] }
                    ]
              }
            , { notes = "O nó de sorteio. Para cada casa vazia e cada peça possível, por backtracking, coloco a peça, chamo o nó de máximo com uma jogada a menos, e o aggregate_all com sum faz a média ponderada: cada caso pesa a chance da peça dividida pelo número de casas vazias. A recursão entre max_value e chance_value é a árvore inteira, em umas vinte linhas. O spawn são só dois fatos: a mesma tabela de 90 e 10 do sorteio do Elm."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/hint.pl", from = 86, to = 103, mark = [ 89, 92, 93, 94, 95, 97 ] }
                    ]
              }
            , { notes = "E o hint em si. O available_moves da issue 4 dá só as direções que mudam o tabuleiro. O findall monta a lista de pontuações, uma por direção. O best escolhe a maior, e o empate vai para a primeira na ordem left, right, up, down, porque o member percorre nessa ordem e o once para na primeira. Sem jogada, a lista é vazia e Best é none. Nada é aleatório: o mesmo tabuleiro dá sempre a mesma dica."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/hint.pl", from = 38, to = 57, mark = [ 41, 42, 45, 53, 56, 57 ] }
                    ]
              }
            , { notes = "O exemplo da issue, com a profundidade padrão 2. O up não aparece, porque não muda nada. Left e right empatam exatamente: um tabuleiro é o espelho do outro e a nota não tem lado preferido. Pelo desempate, a dica é left. O botão Dica da interface vem na issue 20 e chama exatamente este predicado pelo /api/hint da issue 11."
              , blocks =
                    [ Clear
                    , Lead "O exemplo da issue: empate, vale a primeira da ordem."
                    , Tabuleiros
                        [ etapa "Board" "" exemplo
                        , etapa "left" "135,67" exemploLeft
                        , etapa "right" "135,67" exemploRight
                        , etapa "down" "134,73" exemploDown
                        ]
                    , Pre "?- hint([[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 2, Best, Scores).\nBest = left,\nScores = [left-135.67, right-135.67, down-134.73]."
                    ]
              }
            , { notes = "Por que limitar a profundidade. Cada nível multiplica o trabalho por até 4 jogadas vezes 2 peças vezes o número de casas vazias. Com 14 casas vazias, a profundidade 2 leva um décimo de segundo e a 3 leva uns 12 segundos: cem vezes mais. Com 6 casas vazias, a 3 cabe em pouco mais de um segundo. Por isso o máximo é 3 no 4×4 e 2 no 5×5 e 6×6, e o Python reduz para 2 quando há mais de 6 casas vazias. O Prolog descreve o espaço de estados em poucas linhas, mas não poda sozinho: ele visita a árvore toda. Poda esperta, como cortar ramos improváveis, teria que ser escrita à mão."
              , blocks =
                    [ Clear
                    , Lead "Cada nível multiplica o trabalho."
                    , Pre "                       profundidade 1   profundidade 2   profundidade 3\n4×4, 14 casas vazias      30 mil inf.     2,3 mi inf.      231 mi inf.\n                              0,003 s          0,12 s            12 s\n4×4,  6 casas vazias      14 mil inf.     0,5 mi inf.       23 mi inf.\n                              0,001 s          0,03 s           1,2 s\n\nfolhas ≈ (4 jogadas × 2 peças × E casas vazias) ^ profundidade\nSWI-Prolog 11.0.0 (medir/0 em prolog/test_hint.pl)"
                    , Bullets
                        [ "Máximo: 3 para N <= 4 e 2 para N >= 5."
                        , "Mais de 6 casas vazias: o Python usa profundidade 2."
                        ]
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }


arvoreTexto : String
arvoreTexto =
    String.join "\n"
        [ "                    MÁXIMO = 22  →  dica: right"
        , "        ┌──────────────────┼──────────────────┐"
        , "      left               right                up"
        , "  SORTEIO 20,2       SORTEIO 22,0        SORTEIO 14,0"
        , "   ┌────┴────┐        ┌────┴────┐         ┌────┴────┐"
        , " 2 (90%)  4 (10%)   2 (90%)  4 (10%)    2 (90%)  4 (10%)"
        , " nota 20  nota 22   nota 22  nota 22    nota 14  nota 14"
        ]



-- Tabuleiros da cena, escritos à mão. Em prolog/test_hint.pl, o teste
-- `cena_issue05` confere cada jogada com o move/4, cada nota com o evaluate/2
-- e cada resposta com o hint/4.


arvore : List (List Int)
arvore =
    [ [ 2, 0, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


arvoreRight : List (List Int)
arvoreRight =
    [ [ 0, 2, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


arvoreRight2 : List (List Int)
arvoreRight2 =
    [ [ 2, 2, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


arvoreRight4 : List (List Int)
arvoreRight4 =
    [ [ 4, 2, 4 ], [ 4, 8, 16 ], [ 2, 32, 64 ] ]


exemplo : List (List Int)
exemplo =
    [ [ 2, 2, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


exemploLeft : List (List Int)
exemploLeft =
    [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


exemploRight : List (List Int)
exemploRight =
    [ [ 0, 0, 0, 4 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


exemploDown : List (List Int)
exemploDown =
    [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 2, 2, 0, 0 ] ]
