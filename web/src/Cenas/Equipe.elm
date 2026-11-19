module Cenas.Equipe exposing (apresentador, equipe)

{-| Quem explica o quê (#14): cada pessoa apresenta as próprias issues
(`docs/planejamento.md`). O painel de notas mostra a foto e o nome de quem fala.
-}

import Cenas.Types exposing (Member)


equipe : List ( Member, List Int )
equipe =
    [ ( { name = "Victor Schmidt", login = "moonshinerd" }, [ 13, 14, 17 ] )
    , ( { name = "Bianca Patrocínio", login = "BiancaPatrocinio7" }, [ 2, 5 ] )
    , ( { name = "Davi Aguiar", login = "davi-aguiar-vieira" }, [ 3, 19 ] )
    , ( { name = "Kaio Macedo", login = "Bigkaio" }, [ 4, 11 ] )
    , ( { name = "Mateus Castro", login = "mat054" }, [ 6, 7 ] )
    , ( { name = "Mateus Henrique", login = "Mateushqms" }, [ 8, 9 ] )
    , ( { name = "William Bernardo", login = "willxbernardo" }, [ 10, 20 ] )
    ]


{-| Quem apresenta a cena da issue: a pessoa que tinha a issue. As cenas de
abertura são da #17 (estruturação).
-}
apresentador : Int -> Maybe Member
apresentador issue =
    equipe
        |> List.filter (\( _, issues ) -> List.member issue issues)
        |> List.head
        |> Maybe.map Tuple.first
