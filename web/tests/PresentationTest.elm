module PresentationTest exposing (suite)

import Cenas
import Cenas.Types exposing (Block(..), visibleBlocks)
import Expect
import Presentation exposing (Msg(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Apresentação"
        [ test "há cenas" <|
            \_ -> Expect.greaterThan 0 Presentation.sceneCount
        , test "avançar por todos os passos chega ao fim, e voltar desfaz" <|
            \_ ->
                let
                    total =
                        Cenas.all |> List.map (\sc -> List.length sc.steps) |> List.sum

                    start =
                        Presentation.init 0 0

                    forward =
                        List.foldl (\_ m -> Presentation.update Next m) start (List.repeat (total - 1) ())

                    back =
                        List.foldl (\_ m -> Presentation.update Prev m) forward (List.repeat (total - 1) ())
                in
                Expect.equal
                    ( ( forward.scene, forward.step ), ( back.scene, back.step ) )
                    ( ( (Presentation.update Last start).scene, (Presentation.update Last start).step ), ( 0, 0 ) )
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
