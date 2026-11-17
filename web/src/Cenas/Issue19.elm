module Cenas.Issue19 exposing (cenas)

import Cenas.Types exposing (Block(..), Etapa, Scene)


cenas : List Scene
cenas =
    [ { issue = 19
      , title = "Prolog: desafios com CLP(FD)"
      , steps =
            [ { notes = "Agora é um quebra-cabeça, não um jogo. O tabuleiro vem pronto, ninguém sorteia peça nova, e a pergunta é: dá para chegar a uma peça alvo em até N jogadas? Se der, qual a menor sequência? As regras: vale peça maior ou igual ao alvo, jogada que não muda nada não conta, e sem solução o Prolog falha em vez de devolver lista vazia."
              , blocks =
                    [ Lead "Um quebra-cabeça: chegar ao alvo em até N jogadas, sem peças novas."
                    , Tabuleiros [ etapa "c1: alvo 16, até 3 jogadas" "" c1 ]
                    , Bullets
                        [ "Vence com alguma peça >= alvo."
                        , "Resposta: a menor sequência de jogadas."
                        , "Jogada que não muda o tabuleiro não conta."
                        , "Sem solução: o predicado falha."
                        ]
                    ]
              }
            , { notes = "A observação que muda tudo: sem peças novas, deslizar e fundir não cria nem destrói valor. Dois mais dois vira quatro. A soma das peças é a mesma do começo ao fim. Então, se o alvo é maior que a soma, não existe resposta, e sabemos disso sem jogar nada. Essa conta elimina casos antes de qualquer busca."
              , blocks =
                    [ Clear
                    , Lead "Sem peças novas, a soma das peças não muda."
                    , Etapas
                        [ etapa "Board" "soma 16" c1
                        , etapa "left" "soma 16" c1a
                        , etapa "left" "soma 16" c1b
                        , etapa "left" "soma 16" c1c
                        ]
                    , Pre "Alvo > soma  ⇒  impossível, sem simular nenhuma jogada."
                    ]
              }
            , { notes = "Aqui entra o CLP(FD). Não escrevemos um if: declaramos uma restrição. O sum diz que Sum é a soma das casas, e o #=< diz que o alvo cabe nessa soma. Se não cabe, o predicado falha nessa linha. No exemplo da issue, a soma é 2 e o alvo é 8: falso em 239 inferências, sem tocar no move/4."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/challenge.pl", from = 33, to = 41, mark = [ 40, 41 ] }
                    , Pre "?- challenge([[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 5, M).\nfalse.        % soma 2 < 8: nenhuma jogada simulada"
                    ]
              }
            , { notes = "O modelo. Len é quantas jogadas, com domínio 1 até MaxMoves, declarado com in. Mais uma restrição: cada jogada no máximo dobra a maior peça, porque uma peça só funde uma vez por jogada. Então Max vezes 2 elevado a Len tem de alcançar o alvo, e tamanhos curtos demais caem sem simular nada. Depois, Codes é uma lista de Len variáveis, cada uma com domínio 1 a 4, declarado com ins: uma direção por jogada. O labeling do Len em ordem crescente tenta 1 jogada, depois 2, e assim por diante: a primeira resposta é a menor."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/challenge.pl", from = 42, to = 55, mark = [ 46, 47, 51, 53 ] }
                    ]
              }
            , { notes = "E aqui está a parte honesta. O efeito de uma jogada é o move/4: deslizar e fundir não é uma conta linear, e o CLP(FD) não sabe prever o tabuleiro. Então a direção é escolhida pelo labeling, que tenta 1, 2, 3, 4 e volta atrás quando dá errado. Antes de cada jogada, a restrição de crescimento poda o ramo se já não dá para chegar. Jogada que não muda o tabuleiro é rejeitada pelo \\==. O CLP(FD) só conhece inteiros, então o code_dir (fatos no fim do arquivo) traduz 1, 2, 3, 4 para left, right, up, down."
              , blocks =
                    [ Clear
                    , Code { file = "prolog/challenge.pl", from = 57, to = 72, mark = [ 65, 66, 68, 69 ] }
                    ]
              }
            , { notes = "O desafio c1 resolvido. Com 1 e 2 jogadas não há resposta, e com 3 o labeling encontra left, left, left: 2 mais 2, depois 4 mais 4, depois 8 mais 8. É a menor sequência. Repare que cada tabuleiro parte do anterior, sem nenhuma peça nova."
              , blocks =
                    [ Clear
                    , Lead "c1: a menor sequência."
                    , Etapas
                        [ etapa "Board" "" c1
                        , etapa "left" "" c1a
                        , etapa "left" "" c1b
                        , etapa "left" "16 >= 16" c1c
                        ]
                    , Pre "?- challenge([[2,2,4,8],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 16, 3, M).\nM = [left, left, left]."
                    ]
              }
            , { notes = "Um desafio em duas dimensões, no 3×3. A soma é 16, exatamente o alvo: todas as peças precisam se juntar numa só. São quatro jogadas, alternando esquerda e cima. Com só 3 jogadas, o Prolog esgota a busca e responde false: não é lista vazia, é falha."
              , blocks =
                    [ Clear
                    , Lead "c3: todas as peças viram uma só."
                    , Etapas
                        [ etapa "Board" "" c3
                        , etapa "left" "" c3a
                        , etapa "up" "" c3b
                        , etapa "left" "" c3c
                        , etapa "up" "16" c3d
                        ]
                    , Pre "?- challenge(C3, 16, 4, M).\nM = [left, up, left, up].\n\n?- challenge(C3, 16, 3, M).\nfalse."
                    ]
              }
            , { notes = "Comparação medida, em inferências, que não dependem da máquina. Busca sem poda é o mesmo backtracking sem as restrições. Gera e testa rotula a lista inteira e só depois simula. Quando a poda corta, o ganho é enorme: alvo 32 com soma 16 custa 244 inferências contra meio milhão. No misto, o crescimento poda no meio da busca e gasta menos da metade. Mas, num desafio curto como o c2, a poda quase não corta, e a diferença é pequena. O CLP(FD) resolve domínio e poda. A escolha das jogadas continua sendo busca."
              , blocks =
                    [ Clear
                    , Pre "                             CLP(FD) + busca   busca sem poda   gera e testa\nc2: alvo 16, 5 jogadas               40.715           46.461        172.464\nc2: alvo 32 (soma 16)                   244          560.973      6.297.587\nmisto: alvo 64, 6 jogadas           118.715          302.945      4.452.993\n\ninferências no SWI-Prolog 10.0.2 (comparar/0 em prolog/test_challenge.pl)"
                    , Bullets
                        [ "CLP(FD): domínios (in, ins) e poda pela soma e pelo crescimento."
                        , "Busca: o efeito de cada jogada (move/4), com labeling e backtracking."
                        ]
                    ]
              }
            , { notes = "Para fechar, um alvo impossível. O c2 soma 16. Peça um alvo ao público: qualquer coisa acima de 16 falha na hora, porque a restrição da soma corta antes da busca. Alvo 16 tem resposta em 4 jogadas."
              , blocks =
                    [ Clear
                    , Lead "Alvo impossível: o Prolog responde na hora."
                    , Tabuleiros [ etapa "c2: soma 16" "" c2 ]
                    , Pre "?- challenge(C2, 16, 5, M).\nM = [right, up, up, left].\n\n?- challenge(C2, 32, 6, M).\nfalse.        % 32 > 16: 244 inferências"
                    ]
              }
            ]
      }
    ]


etapa : String -> String -> List (List Int) -> Etapa
etapa label note board =
    { label = label, note = note, board = board }



-- Tabuleiros da cena, escritos à mão. Em prolog/test_challenge.pl, o teste
-- `cena_issue19` confere cada jogada com o move/4 e cada resposta com o challenge/4.


c1 : List (List Int)
c1 =
    [ [ 2, 2, 4, 8 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c1a : List (List Int)
c1a =
    [ [ 4, 4, 8, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c1b : List (List Int)
c1b =
    [ [ 8, 8, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c1c : List (List Int)
c1c =
    [ [ 16, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


c2 : List (List Int)
c2 =
    [ [ 4, 0, 2, 0 ], [ 0, 0, 0, 2 ], [ 2, 0, 0, 0 ], [ 0, 4, 0, 2 ] ]


c3 : List (List Int)
c3 =
    [ [ 2, 4, 0 ], [ 0, 2, 0 ], [ 4, 0, 4 ] ]


c3a : List (List Int)
c3a =
    [ [ 2, 4, 0 ], [ 2, 0, 0 ], [ 8, 0, 0 ] ]


c3b : List (List Int)
c3b =
    [ [ 4, 4, 0 ], [ 8, 0, 0 ], [ 0, 0, 0 ] ]


c3c : List (List Int)
c3c =
    [ [ 8, 0, 0 ], [ 8, 0, 0 ], [ 0, 0, 0 ] ]


c3d : List (List Int)
c3d =
    [ [ 16, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ]
