module Cenas.Issue11 exposing (cenas)

import Cenas.Types exposing (Block(..), FlowNode, Pedido, Scene)


cenas : List Scene
cenas =
    [ { issue = 11
      , title = "Python: dica e desafios na API"
      , steps =
            [ { notes = "A ponte da #10 ganha mais três serviços. Dica: o Prolog procura a melhor jogada. Desafio: o Prolog procura a menor sequência que chega ao alvo. E a lista de desafios, que é um arquivo fixo. O formato de cada um está no contrato, e o Elm da #20 consome os três."
              , blocks =
                    [ Lead "Mesma ponte, mais três serviços."
                    , Pre "POST /api/hint        { board, depth }             →  { direction, depth, scores }\nPOST /api/challenge   { board, target, max_moves } →  { solvable, moves }\nGET  /api/challenges                               →  [ { id, title, board, target, max_moves } ]"
                    , Bullets
                        [ "hint chama game:hint/4 (expectimax, #5)."
                        , "challenge chama game:challenge/4 (CLP(FD) e busca, #19)."
                        , "challenges lê server/data/challenges.json."
                        ]
                    ]
              }
            , { notes = "O caminho de uma dica. O Elm manda o tabuleiro em JSON. O Python valida e pergunta ao Prolog game:hint(B, D, Best, S). O Prolog liga Best e S, e o Python traduz de volta para o formato do contrato, não para o formato do Prolog."
              , blocks = [ Clear, Flow { nodes = dica, active = 2, back = "" } ]
              }
            , { notes = "Na volta, o Prolog responde com o átomo left e uma lista de pares left-12.5. O janus entrega isso como string e tuplas, e o Python monta o JSON do contrato."
              , blocks = [ Clear, Flow { nodes = dica, active = 3, back = "↩  a volta: Best = left e S = [left-12.5, ...] viram {\"direction\": \"left\", \"scores\": {\"left\": 12.5, ...}}" } ]
              }
            , { notes = "Aqui está o trabalho de verdade da ponte: converter na fronteira. O Prolog diz none quando não há jogada; o JSON diz null. O Prolog fala em pares left-12.5; o JSON fala em objeto. Nenhuma linha aqui decide qual jogada é melhor: isso é do Prolog."
              , blocks =
                    [ Clear
                    , Lead "O Prolog fala em átomos e pares; o JSON, em null e objetos."
                    , Code { file = "server/extras.py", from = 107, to = 120, mark = [ 113, 118, 119 ] }
                    ]
              }
            , { notes = "No desafio, a diferença é ainda maior. Para o Prolog, não ter solução é falhar: a pergunta simplesmente não se prova. Para o JSON, é um booleano: solvable false. A ponte transforma falha em dado."
              , blocks =
                    [ Clear
                    , Lead "No Prolog, \"sem solução\" é falhar. No JSON, é false."
                    , Code { file = "server/extras.py", from = 123, to = 131, mark = [ 129, 130, 131 ] }
                    ]
              }
            , { notes = "Ao vivo, pedidos de verdade ao /api/hint. Duas peças: a dica é left, empatada com right, e vale a primeira na ordem. up não aparece porque não move nada. O tabuleiro travado devolve direction null. Depth 4 e 5×5 com depth 3 são 422, com a mensagem em português. E com muitas casas vazias, pedimos 3 e a resposta diz depth 2: o Python reduziu."
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: pedidos de verdade ao /api/hint."
                    , PedidosEm "/api/hint" pedidosDica
                    ]
              }
            , { notes = "Por que limitar a profundidade? Cada nível multiplica o trabalho: quatro jogadas, e para cada uma, cada casa vazia pode receber um 2 ou um 4. Com muitas casas vazias a árvore explode, então a profundidade cai para 2. O máximo também depende do tamanho: 3 até o 4×4, 2 no 5×5 e 6×6."
              , blocks =
                    [ Clear
                    , Lead "Cada nível da dica multiplica o trabalho."
                    , Code { file = "server/extras.py", from = 93, to = 99, mark = [ 94, 99 ] }
                    ]
              }
            , { notes = "Agora o /api/challenge. O exemplo do contrato chega a 8 em duas jogadas para a esquerda. Pedir 64 com só 8 de soma é impossível: solvable false. Já ter a peça é solvable true sem nenhuma jogada. E max_moves 9 é 422. Por último, o GET da lista de desafios que a tela de desafios usa."
              , blocks =
                    [ Clear
                    , Lead "Ao vivo: desafios."
                    , PedidosEm "/api/challenge" pedidosDesafio
                    , PedidosEm "/api/challenges" [ { label = "lista de desafios", body = "" } ]
                    ]
              }
            , { notes = "Os testes rodam o Prolog de verdade, sem mock: o TestClient chama a API, que chama o janus, que chama o Prolog. Este teste garante que cada desafio do JSON tem solução confirmada pelo Prolog e que o alvo cabe na soma das peças, já que nenhuma peça nasce."
              , blocks =
                    [ Clear
                    , Lead "Testes de ponta a ponta: Prolog real, sem mock."
                    , Code { file = "server/test_extras.py", from = 161, to = 168, mark = [ 164, 166, 167 ] }
                    ]
              }
            , { notes = "Para alguém do grupo rodar isso em outra máquina, o janus-swi precisa compilar contra o SWI-Prolog. No gcc 14 ou mais novo ele falha com incompatible-pointer-types, e o README tem o comando que resolve, para Linux, macOS e WSL."
              , blocks =
                    [ Clear
                    , Lead "Funciona em qualquer máquina do grupo."
                    , Pre "$ cd server && uv run pytest -q\n54 passed in 0.73s     # test_main.py (#10) + test_extras.py (#11)\n\n# gcc 14+: o janus-swi falha com incompatible-pointer-types\n$ CFLAGS=\"-Wno-error=incompatible-pointer-types\" uv sync"
                    , Bullets [ "Passo a passo para Linux, macOS e WSL no README, em \"Instalando o janus-swi\"." ]
                    ]
              }
            ]
      }
    ]


{-| O caminho de uma dica, com o foco no Python.
-}
dica : List FlowNode
dica =
    [ { label = "Elm", sub = "Dica", detail = "", art = "" }
    , { label = "JSON", sub = "board, depth", detail = "", art = "" }
    , { label = "Python", sub = "ponte", detail = "Valida o tabuleiro e a profundidade e pergunta game:hint(B, D, Best, S). Não sabe qual jogada é boa.", art = "" }
    , { label = "Prolog", sub = "expectimax", detail = "Simula as jogadas à frente e liga Best (a melhor direção) e S (o valor esperado de cada uma).", art = "" }
    ]


pedidosDica : List Pedido
pedidosDica =
    [ { label = "duas peças", body = "{\n  \"board\": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],\n  \"depth\": 2\n}" }
    , { label = "travado: sem jogada", body = "{\n  \"board\": [[2,4,2],[4,2,4],[2,4,2]]\n}" }
    , { label = "depth 4", body = "{\n  \"board\": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],\n  \"depth\": 4\n}" }
    , { label = "5×5 com depth 3", body = "{\n  \"board\": [[2,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]],\n  \"depth\": 3\n}" }
    , { label = "muitas vazias: pede 3", body = "{\n  \"board\": [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],\n  \"depth\": 3\n}" }
    ]


pedidosDesafio : List Pedido
pedidosDesafio =
    [ desafio "chegar a 8" "[[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]" 8 2
    , desafio "64 é impossível" "[[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]" 64 6
    , desafio "já tem o 16" "[[16,0,0],[0,0,0],[0,0,0]]" 16 1
    , desafio "max_moves 9" "[[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]" 8 9
    ]


desafio : String -> String -> Int -> Int -> Pedido
desafio label board target maxMoves =
    { label = label
    , body = "{\n  \"board\": " ++ board ++ ",\n  \"target\": " ++ String.fromInt target ++ ",\n  \"max_moves\": " ++ String.fromInt maxMoves ++ "\n}"
    }
