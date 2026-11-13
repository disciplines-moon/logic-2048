module PresentationTest exposing (suite)

import Api
import Cenas
import Cenas.Types exposing (Block(..), visibleBlocks)
import Expect
import Json.Decode as D
import Presentation exposing (Msg(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Apresentação"
        [ describe "teclado" teclado
        , test "há cenas" <|
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
        , describe "pedidos ao vivo (#10)"
            [ test "enviar guarda o pedido, ainda sem resposta" <|
                \_ ->
                    Presentation.init 0 0
                        |> Presentation.update (SendRequest "{}")
                        |> .request
                        |> Expect.equal (Just { body = "{}", answer = Nothing })
            , test "a resposta do pedido atual aparece" <|
                \_ ->
                    Presentation.init 0 0
                        |> Presentation.update (SendRequest "{}")
                        |> Presentation.update (GotResponse "{}" (Ok { status = 422, body = "x" }))
                        |> .request
                        |> Expect.equal (Just { body = "{}", answer = Just (Ok { status = 422, body = "x" }) })
            , test "resposta atrasada de outro pedido é descartada" <|
                \_ ->
                    Presentation.init 0 0
                        |> Presentation.update (SendRequest "a")
                        |> Presentation.update (SendRequest "b")
                        |> Presentation.update (GotResponse "a" (Ok { status = 200, body = "x" }))
                        |> .request
                        |> Expect.equal (Just { body = "b", answer = Nothing })
            , test "navegar não apaga o pedido" <|
                \_ ->
                    Presentation.init 0 0
                        |> Presentation.update (SendRequest "{}")
                        |> Presentation.update Next
                        |> .request
                        |> Expect.equal (Just { body = "{}", answer = Nothing })
            ]
        , test "índice fora do limite é ajustado" <|
            \_ ->
                Presentation.init 999 999
                    |> (\m -> m.scene)
                    |> Expect.equal (Presentation.sceneCount - 1)
        ]


tecla : String -> Bool -> Bool -> String
tecla key ctrl repeat =
    "{\"key\":\"" ++ key ++ "\",\"ctrlKey\":" ++ b ctrl ++ ",\"altKey\":false,\"metaKey\":false,\"repeat\":" ++ b repeat ++ "}"


b : Bool -> String
b x =
    if x then
        "true"

    else
        "false"


teclado : List Test
teclado =
    [ test "seta direita avança" <|
        \_ -> Expect.equal (Ok Next) (D.decodeString Presentation.keyDecoder (tecla "ArrowRight" False False))
    , test "N maiúsculo abre notas" <|
        \_ -> Expect.equal (Ok ToggleNotes) (D.decodeString Presentation.keyDecoder (tecla "N" False False))
    , test "Ctrl+F é ignorado" <|
        \_ -> Expect.equal (Ok Ignored) (D.decodeString Presentation.keyDecoder (tecla "f" True False))
    , test "tecla repetida é ignorada" <|
        \_ -> Expect.equal (Ok Ignored) (D.decodeString Presentation.keyDecoder (tecla "ArrowRight" False True))
    , test "espaço não navega" <|
        \_ -> Expect.equal (Ok Ignored) (D.decodeString Presentation.keyDecoder (tecla " " False False))
    , test "W joga para cima, mesmo maiúsculo" <|
        \_ -> Expect.equal (Ok (Just Api.Up)) (D.decodeString Api.wasdDecoder (tecla "W" False False))
    , test "W repetido não joga" <|
        \_ -> Expect.equal True (D.decodeString Api.wasdDecoder (tecla "w" False True) |> Result.toMaybe |> (==) Nothing)
    , test "Ctrl+W não joga" <|
        \_ -> Expect.equal True (D.decodeString Api.wasdDecoder (tecla "w" True False) |> Result.toMaybe |> (==) Nothing)
    , test "seta repetida não joga" <|
        \_ -> Expect.equal True (D.decodeString Api.keyDecoder (tecla "ArrowUp" False True) |> Result.toMaybe |> (==) Nothing)
    ]
