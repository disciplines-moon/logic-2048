module ApiTest exposing (suite)

import Api exposing (Direction(..))
import Expect
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Api"
        [ test "codifica o pedido de movimento" <|
            \_ ->
                Api.encodeMove [ [ 2, 0 ] ] Left
                    |> E.encode 0
                    |> Expect.equal "{\"board\":[[2,0]],\"direction\":\"left\"}"
        , test "decodifica a resposta" <|
            \_ ->
                D.decodeString Api.moveDecoder
                    "{\"board\":[[4]],\"score\":4,\"moved\":true,\"won\":false,\"lost\":false}"
                    |> Expect.equal
                        (Ok { board = [ [ 4 ] ], score = 4, moved = True, won = False, lost = False })
        , test "seta vira direção" <|
            \_ ->
                D.decodeString Api.keyDecoder (key "ArrowLeft" False False)
                    |> Expect.equal (Ok (Just Left))
        , test "tecla segurada (repeat) não joga" <|
            \_ ->
                D.decodeString Api.wasdDecoder (key "a" True False)
                    |> Result.toMaybe
                    |> Expect.equal Nothing
        , test "Ctrl+tecla não joga (Ctrl+Z é desfazer)" <|
            \_ ->
                D.decodeString Api.wasdDecoder (key "a" False True)
                    |> Result.toMaybe
                    |> Expect.equal Nothing
        , describe "tecla digitada num campo de texto não joga"
            (List.map
                (\tag ->
                    test tag <|
                        \_ ->
                            D.decodeString Api.wasdDecoder (keyIn tag "a")
                                |> Result.toMaybe
                                |> Expect.equal Nothing
                )
                [ "INPUT", "TEXTAREA", "SELECT" ]
            )
        , describe "Ctrl+Z desfaz (#7)"
            [ test "Ctrl+Z" <|
                \_ -> D.decodeString Api.undoDecoder (undo "z" True False False False) |> Expect.equal (Ok ())
            , test "Cmd+Z no Mac" <|
                \_ -> D.decodeString Api.undoDecoder (undo "z" False True False False) |> Expect.equal (Ok ())
            , test "Z sem Ctrl não desfaz" <|
                \_ -> D.decodeString Api.undoDecoder (undo "z" False False False False) |> Result.toMaybe |> Expect.equal Nothing
            , test "Ctrl+Shift+Z não desfaz" <|
                \_ -> D.decodeString Api.undoDecoder (undo "Z" True False True False) |> Result.toMaybe |> Expect.equal Nothing
            , test "Ctrl+Z segurado não desfaz em série" <|
                \_ -> D.decodeString Api.undoDecoder (undo "z" True False False True) |> Result.toMaybe |> Expect.equal Nothing
            ]
        , test "tecla fora de campo de texto joga" <|
            \_ ->
                D.decodeString Api.wasdDecoder (keyIn "BODY" "a")
                    |> Expect.equal (Ok (Just Left))
        ]


{-| Evento de teclado mínimo, como o navegador manda.
-}
key : String -> Bool -> Bool -> String
key k repeat ctrl =
    E.encode 0
        (E.object
            [ ( "key", E.string k )
            , ( "repeat", E.bool repeat )
            , ( "ctrlKey", E.bool ctrl )
            , ( "altKey", E.bool False )
            , ( "metaKey", E.bool False )
            ]
        )


{-| Evento de teclado vindo de um elemento (`target.tagName`), sem repeat nem modificador.
-}
keyIn : String -> String -> String
keyIn tag k =
    E.encode 0
        (E.object
            [ ( "key", E.string k )
            , ( "repeat", E.bool False )
            , ( "ctrlKey", E.bool False )
            , ( "altKey", E.bool False )
            , ( "metaKey", E.bool False )
            , ( "target", E.object [ ( "tagName", E.string tag ) ] )
            ]
        )


{-| Evento de teclado para o Ctrl+Z: tecla, Ctrl, Meta (Cmd), Shift e repeat.
-}
undo : String -> Bool -> Bool -> Bool -> Bool -> String
undo k ctrl meta shift repeat =
    E.encode 0
        (E.object
            [ ( "key", E.string k )
            , ( "repeat", E.bool repeat )
            , ( "ctrlKey", E.bool ctrl )
            , ( "altKey", E.bool False )
            , ( "metaKey", E.bool meta )
            , ( "shiftKey", E.bool shift )
            ]
        )
