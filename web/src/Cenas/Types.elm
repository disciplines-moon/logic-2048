module Cenas.Types exposing (Block(..), Scene, Step, isPending, pending)

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
      -- Cena ainda não escrita. Falha a revisão final (#14).
    | Pending String


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
