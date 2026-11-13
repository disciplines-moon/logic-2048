module Cenas.Issue10 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Pedido, Scene)


cenas : List Scene
cenas =
    [ { issue = 10
      , title = "Python: a ponte para o Prolog"
      , steps =
            [ { notes = "Na abertura vimos a jogada inteira. Agora abrimos a caixa do Python. Ele não decide nada de jogo: recebe o tabuleiro em JSON, confere se a entrada é válida e traduz para uma pergunta ao Prolog. Quem faz a tradução é o janus, a biblioteca que liga o Python ao SWI-Prolog no mesmo processo."
              , blocks = [ Flow { nodes = ponte, active = 2, back = "" } ]
              }
            , { notes = "O Prolog responde ligando N (o tabuleiro novo), S (os pontos) e M (o caminho das peças). Na volta, o janus traduz isso para um dict Python, e o Python devolve JSON."
              , blocks = [ Clear, Flow { nodes = ponte, active = 3, back = "↩  a volta: o janus traz N, S e M num dict Python, e o Python responde em JSON" } ]
              }
            , { notes = "O endpoint inteiro é tradução. Entra JSON: quando a função roda, o FastAPI já transformou o corpo num MoveRequest validado. Chama o Prolog: o query_once pergunta o move_trace/5, que é o move/4 mais o caminho de cada peça para a animação (#8), e depois faz duas perguntas de sim ou não, vitória e derrota. Sai JSON: o MoveResponse. O moved só compara dois tabuleiros: é um dado, não uma regra do 2048."
              , blocks =
                    [ Clear
                    , Lead "Entra JSON, chama o Prolog, sai JSON."
                    , Code { file = "server/main.py", from = 185, to = 199, mark = [ 189, 196, 197, 199 ] }
                    ]
              }
            , { notes = "O que o query_once devolve, rodando de verdade. Mandamos um dicionário com os valores de B e D; o Prolog prova o objetivo e devolve outro dicionário com as variáveis que ele ligou, N e S, mais o truth, que diz se provou."
              , blocks =
                    [ Clear
                    , Lead "O janus traduz os tipos entre os dois paradigmas."
                    , Pre ">>> tres = [[2, 2, 0], [0, 4, 4], [0, 0, 8]]\n>>> janus.query_once(\"game:move(B, D, N, S)\", {\"B\": tres, \"D\": \"left\"})\n{'truth': True, 'N': [[4, 0, 0], [8, 0, 0], [8, 0, 0]], 'S': 12}"
                    ]
              }
            , { notes = "As conversões, uma por uma. A string \"left\" vira o átomo left, e é por isso que o move_dir(left, ...) do Prolog casa direto. Lista vira lista e inteiro vira inteiro. Na volta, o par left-12.5 vira a tupla (\"left\", 12.5): a #11 usa isso nas notas da dica. E falhar não é erro: o objetivo que não se prova volta como truth False. Converter os tipos é o trabalho de verdade da ponte."
              , blocks =
                    [ Pre ">>> janus.query_once(\"atom(D)\", {\"D\": \"left\"})             # str   → átomo\n{'truth': True}\n>>> janus.query_once(\"is_list(B)\", {\"B\": tres})            # list  → lista\n{'truth': True}\n>>> janus.query_once(\"X = left-12.5\")                      # par   → tupla\n{'truth': True, 'X': ('left', 12.5)}\n>>> janus.query_once(\"game:game_lost(B)\", {\"B\": tres})     # falha → False\n{'truth': False}"
                    ]
              }
            , { notes = "Entrada inválida nunca chega ao Prolog, que assume entrada válida (contrato). Primeiro os tipos declaram o formato: Board é lista de listas de inteiros estritos, e o StrictInt recusa true, 2.0 e \"2\". A direção é um Literal: só as quatro palavras. O FastAPI confere tudo isso antes de a função rodar. A #11 reusa o mesmo Board."
              , blocks =
                    [ Clear
                    , Lead "Entrada inválida nunca chega ao Prolog."
                    , Code { file = "server/main.py", from = 70, to = 76, mark = [ 70, 71 ] }
                    ]
              }
            , { notes = "O que o tipo não diz, o validar_tabuleiro confere: quadrado de 3 a 6, e cada casa 0 ou potência de 2. O v & (v - 1) apaga o único bit ligado de uma potência de 2 e dá 0. O ValueError vira um 422 com a frase daqui."
              , blocks =
                    [ Clear
                    , Lead "Entrada inválida nunca chega ao Prolog."
                    , Code { file = "server/main.py", from = 55, to = 64, mark = [ 58, 62 ] }
                    ]
              }
            , { notes = "Sem estes handlers, o FastAPI responderia {\"detail\": [...]} em inglês. Trocamos pelo formato do contrato: 422 com {\"error\": ...} em português, dizendo o campo errado, porque o Elm mostra essa mensagem a quem joga. Qualquer exceção inesperada, como um erro no Prolog, vira 500 no mesmo formato, e o detalhe vai para o log. 400 nunca: até um corpo que não dá para ler vira 422."
              , blocks =
                    [ Clear
                    , Lead "Erros com 422 e 500, sempre como {\"error\": ...}."
                    , Code { file = "server/main.py", from = 142, to = 145, mark = [ 145 ] }
                    , Code { file = "server/main.py", from = 167, to = 172, mark = [ 172 ] }
                    ]
              }
            , { notes = "Ao vivo, pedidos de verdade ao servidor. Primeiro a direção diagonal: 422, e a mensagem diz o campo e o que vale. Depois a peça 3, a linha curta, o texto no lugar do número e o JSON quebrado: cada erro para na borda, e o Prolog nem é chamado. Por fim a jogada válida: 200 com board, score, moved, won e lost. O erro é legível, e o servidor continua de pé."
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: pedidos de verdade ao /api/move."
                    , Pedidos pedidos
                    ]
              }
            , { notes = "Os testes usam o TestClient do FastAPI, que chama a API sem subir servidor: N de 3 a 6, cada tipo de entrada inválida com a mensagem exata, 404, 405 e o 500. O 500 não acontece de propósito, então o teste força: o monkeypatch troca a chamada ao Prolog por uma que quebra, e conferimos a resposta. As conversões do janus e os recortes de código desta cena também têm teste."
              , blocks =
                    [ Clear
                    , Lead "Testes: o 500 é forçado com monkeypatch."
                    , Code { file = "server/test_main.py", from = 210, to = 224, mark = [ 214, 215, 224 ] }
                    ]
              }
            , { notes = "Por que a API não tem regra de jogo? Porque cada regra mora num lugar só. A prova está no histórico: a #3 trocou o esboço do move/4 pela regra de verdade, e a #4 escreveu vitória e derrota. As duas mexeram no game.pl e nos testes, e nenhuma tocou no main.py. Se o Python também soubesse as regras, seriam duas versões para manter iguais, em dois paradigmas. A ponte faz só o que é dela: valida, traduz e responde."
              , blocks =
                    [ Clear
                    , Lead "Uma regra mora num lugar só: o Prolog."
                    , Pre "$ git show --stat=50 --format='%s' 07e6127 abc16b5 -- prolog server\nProlog: mover nas 4 direções (move/4)\n prolog/game.pl      |  54 ++++-\n prolog/test_game.pl | 261 +++++++++++++++++++++-\n server/test_main.py |  48 ++++\nProlog: vitória por N, derrota e jogadas válidas\n prolog/game.pl      |  47 +++++++-\n prolog/test_game.pl | 135 +++++++++++++++++++++-"
                    , Bullets [ "A #3 e a #4 mudaram as regras, e o server/main.py não mudou." ]
                    ]
              }
            ]
      }
    ]


{-| As mesmas etapas da cena "Como uma jogada acontece", agora com o foco no Python.
-}
ponte : List FlowNode
ponte =
    [ { label = "Teclado", sub = "você", detail = "", art = "keyboard" }
    , { label = "Elm", sub = "interface", detail = "", art = "elm" }
    , { label = "Python", sub = "ponte", detail = "Recebe o JSON, confere a entrada e, pelo janus, transforma em consulta Prolog. Não conhece as regras do 2048.", art = "python" }
    , { label = "Prolog", sub = "regras", detail = "Prova game:move_trace(B, D, N, S, M) e liga N (o tabuleiro novo), S (os pontos) e M (o caminho das peças).", art = "prolog" }
    ]


{-| Pedidos do painel ao vivo. Todos partem do mesmo 3×3 e mudam uma coisa só.
-}
pedidos : List Pedido
pedidos =
    [ pedido "direção \"diagonal\"" "[[2,2,0],[0,4,4],[0,0,8]]" "\"diagonal\""
    , pedido "peça 3" "[[2,3,0],[0,4,4],[0,0,8]]" "\"left\""
    , pedido "linha curta" "[[2,2,0],[0,4],[0,0,8]]" "\"left\""
    , pedido "\"2\" no lugar de 2" "[[\"2\",2,0],[0,4,4],[0,0,8]]" "\"left\""
    , { label = "JSON quebrado", body = "{\n  \"board\": [[2,2,0],[0,4,4],\n  \"direction\": \"left\"\n}" }
    , pedido "jogada válida" "[[2,2,0],[0,4,4],[0,0,8]]" "\"left\""
    ]


pedido : String -> String -> String -> Pedido
pedido label board direction =
    { label = label
    , body = "{\n  \"board\": " ++ board ++ ",\n  \"direction\": " ++ direction ++ "\n}"
    }
