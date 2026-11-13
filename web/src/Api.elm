module Api exposing (Direction(..), MoveResponse, RawResponse, encodeMove, keyDecoder, moveDecoder, postMove, postRaw, rawResponse, undoDecoder, wasdDecoder)

import Http
import Json.Decode as D
import Json.Encode as E


type Direction
    = Left
    | Right
    | Up
    | Down


type alias MoveResponse =
    { board : List (List Int)
    , score : Int
    , moved : Bool
    , won : Bool
    , lost : Bool
    }


{-| Falha quando a tecla está sendo repetida (segurada), vem com Ctrl, Alt ou Meta
(Ctrl+Z é desfazer, não jogada) ou foi digitada num campo de texto.
-}
notRepeat : D.Decoder ()
notRepeat =
    D.map5
        (\r ctrl alt meta typing -> r || ctrl || alt || meta || typing)
        (D.field "repeat" D.bool)
        (D.field "ctrlKey" D.bool)
        (D.field "altKey" D.bool)
        (D.field "metaKey" D.bool)
        inTextField
        |> D.andThen
            (\bloqueada ->
                if bloqueada then
                    D.fail "tecla repetida ou com modificador"

                else
                    D.succeed ()
            )


{-| Setas do teclado viram direções. Outras teclas viram `Nothing`.
-}
keyDecoder : D.Decoder (Maybe Direction)
keyDecoder =
    notRepeat
        |> D.andThen (\_ -> D.field "key" D.string)
        |> D.map
            (\key ->
                case key of
                    "ArrowLeft" ->
                        Just Left

                    "ArrowRight" ->
                        Just Right

                    "ArrowUp" ->
                        Just Up

                    "ArrowDown" ->
                        Just Down

                    _ ->
                        Nothing
            )


{-| W, A, S, D também jogam (na apresentação, as setas navegam).
-}
wasdDecoder : D.Decoder (Maybe Direction)
wasdDecoder =
    notRepeat
        |> D.andThen (\_ -> D.field "key" D.string)
        |> D.map
            (\key ->
                case String.toLower key of
                    "a" ->
                        Just Left

                    "d" ->
                        Just Right

                    "w" ->
                        Just Up

                    "s" ->
                        Just Down

                    _ ->
                        Nothing
            )


directionToString : Direction -> String
directionToString dir =
    case dir of
        Left ->
            "left"

        Right ->
            "right"

        Up ->
            "up"

        Down ->
            "down"


encodeMove : List (List Int) -> Direction -> E.Value
encodeMove board dir =
    E.object
        [ ( "board", E.list (E.list E.int) board )
        , ( "direction", E.string (directionToString dir) )
        ]


moveDecoder : D.Decoder MoveResponse
moveDecoder =
    D.map5 MoveResponse
        (D.field "board" (D.list (D.list D.int)))
        (D.field "score" D.int)
        (D.field "moved" D.bool)
        (D.field "won" D.bool)
        (D.field "lost" D.bool)


postMove : List (List Int) -> Direction -> (Result Http.Error MoveResponse -> msg) -> Cmd msg
postMove board dir toMsg =
    Http.post
        { url = "/api/move"
        , body = Http.jsonBody (encodeMove board dir)
        , expect = Http.expectJson toMsg moveDecoder
        }


{-| Uma resposta HTTP como veio: o status e o corpo em texto, seja qual for o status.
-}
type alias RawResponse =
    { status : Int
    , body : String
    }


{-| Manda `body` exatamente como está escrito, mesmo que seja inválido de propósito,
e devolve a resposta crua. A apresentação da #10 usa isso para mostrar o
`{"error": ...}` do 422, que o `Http.expectJson` descartaria (veja `docs/contrato.md`).
-}
postRaw : String -> String -> (Result Http.Error RawResponse -> msg) -> Cmd msg
postRaw url body toMsg =
    Http.post
        { url = url
        , body = Http.stringBody "application/json" body
        , expect = Http.expectStringResponse toMsg rawResponse
        }


{-| Qualquer status com corpo é resposta (200, 422 ou 500). Só é erro quando não
chega resposta nenhuma: rede fora, tempo esgotado ou endereço inválido.
-}
rawResponse : Http.Response String -> Result Http.Error RawResponse
rawResponse response =
    case response of
        Http.GoodStatus_ meta body ->
            Ok { status = meta.statusCode, body = body }

        Http.BadStatus_ meta body ->
            Ok { status = meta.statusCode, body = body }

        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError


{-| Ctrl+Z (ou Cmd+Z no Mac) desfaz (#7). Como nas jogadas, tecla segurada e campo
de texto não contam; com Shift ou Alt também não (Ctrl+Shift+Z costuma ser refazer).
-}
undoDecoder : D.Decoder ()
undoDecoder =
    D.map7
        (\key ctrl meta shift alt r typing ->
            (String.toLower key == "z")
                && (ctrl || meta)
                && not (shift || alt || r || typing)
        )
        (D.field "key" D.string)
        (D.field "ctrlKey" D.bool)
        (D.field "metaKey" D.bool)
        (D.field "shiftKey" D.bool)
        (D.field "altKey" D.bool)
        (D.field "repeat" D.bool)
        inTextField
        |> D.andThen
            (\isUndo ->
                if isUndo then
                    D.succeed ()

                else
                    D.fail "não é Ctrl+Z"
            )


{-| A tecla foi digitada num campo de texto? Aí ela é do campo, não do jogo.
-}
inTextField : D.Decoder Bool
inTextField =
    D.maybe (D.at [ "target", "tagName" ] D.string)
        |> D.map (\tag -> List.member tag [ Just "INPUT", Just "TEXTAREA", Just "SELECT" ])
