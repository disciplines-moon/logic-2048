module Cenas.Types exposing (Block(..), Etapa, FlowNode, Member, Pedido, Scene, Step, isPending, pending, visibleBlocks)

{-| A apresentação é um conjunto de **cenas** (uma ou mais por issue). Cada cena
tem **passos**: ao avançar, o próximo passo ACRESCENTA blocos na tela, no ritmo
da fala. Os blocos podem ser vivos (`Demo`) ou código real do repositório.
-}


type Block
    = Paragraph String
    | Bullets (List String)
      -- Texto literal, por exemplo um diagrama.
    | Pre String
      -- Trecho de arquivo do repositório. `file` é a chave em `main.js`
      -- (por exemplo "prolog/game.pl"). `from` e `to` são linhas (1 a N), com
      -- `to = 0` indo até o fim. `mark` são linhas (números do arquivo) destacadas.
    | Code { file : String, from : Int, to : Int, mark : List Int }
      -- Demo ao vivo: o jogo real dentro da cena.
    | Demo
      -- Frase grande de destaque.
    | Lead String
      -- Linha de peças animada: desliza para a esquerda e funde os pares, como o `slide_left/3`.
      -- Recebe a linha de entrada; o destino de cada peça é calculado na hora.
    | Slide (List Int)
      -- As três fases do `slide_left/3` (exclude, merge, completa), uma linha por fase.
    | Fases (List Int)
      -- O corte `!` lado a lado: com ele (uma resposta) e sem ele (resposta errada no backtracking).
    | Corte
      -- Tabuleiros ligados por setas, que aparecem um a um em ciclo: as etapas de
      -- uma jogada do `move/4` (por exemplo transpõe, desliza, transpõe de volta).
      -- Os tabuleiros são escritos à mão na cena (o teste `cena_issue03` confere).
    | Etapas (List Etapa)
      -- Tabuleiros lado a lado, sem setas: o mesmo tabuleiro em direções diferentes.
    | Tabuleiros (List Etapa)
      -- Botões que carregam um tabuleiro pronto na `Demo` (por exemplo um cenário
      -- quase perdido). Cada botão mostra o tabuleiro e a legenda (`label`); use
      -- junto com um `Demo` no mesmo passo.
    | Cenarios (List Etapa)
      -- Capa: título grande, subtítulo e etiquetas. Em cenas com `title = ""` o título comum some.
    | Hero { title : String, subtitle : String, chips : List String }
      -- Diagrama de etapas ligadas por setas. `active` (a partir de 0) acende a
      -- etapa atual e mostra o `detail` dela. Use `Clear` + um novo `Flow` com
      -- outro `active` para "caminhar" pelo fluxo a cada passo. `art` escolhe a
      -- ilustração animada da etapa: "keyboard", "elm", "python", "prolog" (ou "" para nenhuma).
      -- `back` é a frase que aparece embaixo quando a última etapa acende (o caminho de volta).
    | Flow { nodes : List FlowNode, active : Int, back : String }
      -- Equipe: foto do GitHub (`login`), nome e etiqueta opcional, com animação de entrada.
    | Team (List Member)
      -- Pedidos de verdade ao `POST /api/move`: cada `Pedido` vira um botão, e o
      -- painel mostra o JSON enviado, o status HTTP e o JSON que o servidor devolveu.
      -- O `body` vai exatamente como está escrito, então pode ser inválido de propósito.
    | Pedidos (List Pedido)
      -- Cena ainda não escrita. Falha a revisão final (#14).
    | Pending String
      -- Apaga tudo que apareceu antes na cena (para trocar um bloco por outro).
    | Clear


{-| Um tabuleiro com legenda (`label`, de preferência o objetivo Prolog que o
produziu) e uma nota curta em destaque (`note`, por exemplo "+4"; "" para nenhuma).
-}
type alias Etapa =
    { label : String
    , note : String
    , board : List (List Int)
    }


{-| Um pedido pronto do bloco `Pedidos`: o texto do botão e o corpo JSON enviado.
-}
type alias Pedido =
    { label : String
    , body : String
    }


type alias Member =
    { name : String
    , login : String
    }


type alias FlowNode =
    { label : String
    , sub : String
    , detail : String
    , art : String
    }


type alias Step =
    { notes : String
    , blocks : List Block
    }


type alias Scene =
    { issue : Int
    , title : String
    , steps : List Step
    }


pending : Int -> String -> String -> Scene
pending issue title hint =
    { issue = issue
    , title = title
    , steps = [ { notes = "", blocks = [ Pending hint ] } ]
    }


isPending : Scene -> Bool
isPending scene =
    List.any
        (\step ->
            List.any
                (\block ->
                    case block of
                        Pending _ ->
                            True

                        _ ->
                            False
                )
                step.blocks
        )
        scene.steps


{-| Blocos visíveis até o passo `upTo` (0 a N-1). Os passos se acumulam, e um
`Clear` descarta o que veio antes. Cada bloco vem com o índice do passo em que
nasceu.
-}
visibleBlocks : Int -> Scene -> List ( Int, Block )
visibleBlocks upTo scene =
    scene.steps
        |> List.take (upTo + 1)
        |> List.indexedMap (\i step -> List.map (Tuple.pair i) step.blocks)
        |> List.concat
        |> List.foldl
            (\( i, block ) acc ->
                case block of
                    Clear ->
                        []

                    _ ->
                        acc ++ [ ( i, block ) ]
            )
            []
