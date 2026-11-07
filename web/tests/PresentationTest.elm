module PresentationTest exposing (suite)

import Cenas.Types exposing (Block(..), visibleBlocks)
import Expect
import Presentation exposing (Msg(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Apresentação"
        [ test "há cenas" <|
            \_ -> Expect.greaterThan 0 Presentation.sceneCount
        , test "avançar passa pelos passos e depois pela próxima cena" <|
            \_ ->
                Presentation.init 0 0
                    |> Presentation.update Next
                    |> Presentation.update Next
                    |> (\m -> ( m.scene, m.step ))
                    |> Expect.equal ( 1, 0 )
        , test "voltar do primeiro passo da cena vai ao último da anterior" <|
            \_ ->
                Presentation.init 1 0
                    |> Presentation.update Prev
                    |> (\m -> ( m.scene, m.step ))
                    |> Expect.equal ( 0, 1 )
        , test "não passa do início nem do fim" <|
            \_ ->
                Expect.equal
                    ( Presentation.init 0 0 |> Presentation.update Prev |> (\m -> ( m.scene, m.step ))
                    , Presentation.update Last (Presentation.init 0 0) |> Presentation.update Next |> (\m -> m.scene)
                    )
                    ( ( 0, 0 ), Presentation.sceneCount - 1 )
        , test "os passos acumulam blocos e Clear descarta os anteriores" <|
            \_ ->
                let
                    scene =
                        { issue = 0
                        , title = ""
                        , steps =
                            [ { notes = "", blocks = [ Paragraph "a" ] }
                            , { notes = "", blocks = [ Paragraph "b" ] }
                            , { notes = "", blocks = [ Clear, Paragraph "c" ] }
                            ]
                        }
                in
                Expect.equal
                    [ List.map Tuple.second (visibleBlocks 1 scene)
                    , List.map Tuple.second (visibleBlocks 2 scene)
                    ]
                    [ [ Paragraph "a", Paragraph "b" ], [ Paragraph "c" ] ]
        , test "índice fora do limite é ajustado" <|
            \_ ->
                Presentation.init 999 999
                    |> (\m -> m.scene)
                    |> Expect.equal (Presentation.sceneCount - 1)
        ]
