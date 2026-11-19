module ApiTest exposing (suite)

import Api exposing (Direction(..))
import Dict
import Expect
import Http
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Api"
        [ describe "dica e desafios (#20)"
            [ test "dica com direção e scores na ordem do contrato" <|
                \_ ->
                    D.decodeString Api.hintDecoder "{\"direction\": \"left\", \"depth\": 2, \"scores\": {\"down\": 9.0, \"left\": 12.5, \"right\": 12.5}}"
                        |> Expect.equal (Ok { direction = Just Left, depth = 2, scores = [ ( Left, 12.5 ), ( Right, 12.5 ), ( Down, 9.0 ) ] })
            , test "dica sem jogada: null vira Nothing" <|
                \_ ->
                    D.decodeString Api.hintDecoder "{\"direction\": null, \"depth\": 2, \"scores\": {}}"
                        |> Expect.equal (Ok { direction = Nothing, depth = 2, scores = [] })
            , test "direção desconhecida é resposta inválida" <|
                \_ ->
                    D.decodeString Api.hintDecoder "{\"direction\": \"diagonal\", \"depth\": 2, \"scores\": {}}"
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "solução do desafio" <|
                \_ ->
                    D.decodeString Api.solutionDecoder "{\"solvable\": true, \"moves\": [\"left\", \"up\"]}"
                        |> Expect.equal (Ok { solvable = True, moves = [ Left, Up ] })
            , test "desafio da lista" <|
                \_ ->
                    D.decodeString Api.challengeDecoder "{\"id\": \"c1\", \"title\": \"t\", \"board\": [[2,2,4],[0,0,0],[0,0,0]], \"target\": 8, \"max_moves\": 2}"
                        |> Expect.equal (Ok { id = "c1", title = "t", board = [ [ 2, 2, 4 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ], target = 8, maxMoves = 2 })
            , test "422 lê a mensagem do corpo" <|
                \_ ->
                    Api.apiResult D.int (Http.BadStatus_ (metadata 422) "{\"error\": \"depth: use um número de 1 a 3\"}")
                        |> Expect.equal (Err (Api.Rejected "depth: use um número de 1 a 3"))
            , test "500 é erro do servidor" <|
                \_ ->
                    Api.apiResult D.int (Http.BadStatus_ (metadata 500) "{\"error\": \"erro interno no servidor\"}")
                        |> Expect.equal (Err (Api.Server 500))
            , test "502 do proxy (API parada) é falta de resposta" <|
                \_ ->
                    Api.apiResult D.int (Http.BadStatus_ (metadata 502) "")
                        |> Expect.equal (Err Api.Network)
            , test "200 fora do formato é resposta inválida" <|
                \_ ->
                    Api.apiResult D.int (Http.GoodStatus_ (metadata 200) "{}")
                        |> Expect.equal (Err Api.Invalid)
            , test "rede fora" <|
                \_ ->
                    Api.apiResult D.int Http.NetworkError_
                        |> Expect.equal (Err Api.Network)
            ]
        , test "codifica o pedido de movimento" <|
            \_ ->
                Api.encodeMove [ [ 2, 0 ] ] Left
                    |> E.encode 0
                    |> Expect.equal "{\"board\":[[2,0]],\"direction\":\"left\"}"
        , test "decodifica a resposta" <|
            \_ ->
                D.decodeString Api.moveDecoder
                    "{\"board\":[[4]],\"score\":4,\"moved\":true,\"won\":false,\"lost\":false}"
                    |> Expect.equal
                        (Ok { board = [ [ 4 ] ], score = 4, moved = True, won = False, lost = False, moves = [] })
        , test "decodifica o caminho das peças (#8)" <|
            \_ ->
                D.decodeString Api.moveDecoder
                    "{\"board\":[[4]],\"score\":4,\"moved\":true,\"won\":false,\"lost\":false,\"moves\":[{\"from\":[0,1],\"to\":[0,0],\"merged\":true}]}"
                    |> Result.map .moves
                    |> Expect.equal (Ok [ { from = ( 0, 1 ), to = ( 0, 0 ), merged = True } ])
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
        , describe "resposta crua (#10)"
            [ test "200 chega com o corpo" <|
                \_ ->
                    Api.rawResponse (Http.GoodStatus_ (metadata 200) "{\"score\":4}")
                        |> Expect.equal (Ok { status = 200, body = "{\"score\":4}" })
            , test "422 também chega com o corpo, que traz o error" <|
                \_ ->
                    Api.rawResponse (Http.BadStatus_ (metadata 422) "{\"error\":\"JSON inválido\"}")
                        |> Expect.equal (Ok { status = 422, body = "{\"error\":\"JSON inválido\"}" })
            , test "sem resposta é erro de rede" <|
                \_ ->
                    Api.rawResponse Http.NetworkError_
                        |> Expect.equal (Err Http.NetworkError)
            ]
        ]


metadata : Int -> Http.Metadata
metadata status =
    { url = "/api/move", statusCode = status, statusText = "", headers = Dict.empty }


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
